module memory

import providers
import x.json2
import context
import strings

@[noinit]
pub struct LLMMemoryRanker {
mut:
	provider ?providers.LLMProvider
	model    string
	fallback &SimpleRanker
}

pub fn LLMMemoryRanker.new(provider ?providers.LLMProvider, model string) &LLMMemoryRanker {
	mut effective_model := model
	if effective_model == '' {
		if p := provider {
			effective_model = p.get_default_model()
		} else {
			effective_model = 'fallback-model'
		}
	}

	return &LLMMemoryRanker{
		provider: provider
		model:    effective_model
		fallback: SimpleRanker.new()
	}
}

pub fn (r &LLMMemoryRanker) rank(query string, memories []MemoryItem, top_k int) []MemoryItem {
	if memories.len == 0 || top_k <= 0 {
		return []
	}

	provider := r.provider or { return r.fallback.rank(query, memories, top_k) }

	// ── Build prompt ───────────────────────────────────────

	mut sb := strings.new_builder(512)
	sb.write_string('You are a ranking assistant. Given the query and memories numbered 0..N-1, ')
	sb.write_string('return ONLY an ordered list of the most relevant indices first.\n')
	sb.write_string('Respond either by calling the tool "rank_memories" with {"indices": [i,j,...]} ')
	sb.write_string('or by outputting a plain JSON array like [3,1,0] in your content.\n')
	sb.write_string('Do NOT add explanations, prefixes or other text.\n\n')

	sb.write_string('Query: ${query}\n\n')
	sb.write_string('Memories (index: text):\n')

	for i, m in memories {
		sb.write_string('${i}: ${m.text}\n')
	}

	system_prompt := sb.str()

	messages := [
		providers.Message.system(system_prompt),
		providers.Message.user('Rank the memories by relevance to the query. Return indices only.'),
	]

	// ── Tool definition ───────────────────────────────────────

	mut items_map := map[string]json2.Any{}
	items_map['type'] = json2.Any('number')

	mut indices_map := map[string]json2.Any{}
	indices_map['type'] = json2.Any('array')
	indices_map['items'] = json2.Any(items_map)

	mut properties_map := map[string]json2.Any{}
	properties_map['indices'] = json2.Any(indices_map)

	mut params_map := map[string]json2.Any{}
	params_map['type'] = json2.Any('object')
	params_map['properties'] = json2.Any(properties_map)
	params_map['required'] = json2.Any([json2.Any('indices')])

	tool := providers.ToolDefinition{
		name:        'rank_memories'
		description: 'Returns an ordered list of relevant memory indices (most relevant first)'
		parameters:  params_map
	}

	// ── Call LLM ────────────────────────────────────────────

	mut bg := context.background()
	resp := provider.chat(mut bg, messages, [tool], r.model) or {
		eprintln('LLM ranking failed: ${err}')
		return r.fallback.rank(query, memories, top_k)
	}

	// ── 1. Prefer tool call ────────────────────────────────────────

	if resp.has_tool_calls && resp.tool_calls.len > 0 {
		for tc in resp.tool_calls {
			if tc.name != 'rank_memories' {
				continue
			}

			if indices_any := tc.arguments['indices'] {
				match indices_any {
					[]json2.Any {
						mut idxs := []int{}
						for val in indices_any { // ← changed: indices_any instead of it
							match val {
								f64 { idxs << int(val) } // ← val, not it
								i64 { idxs << int(val) }
								int { idxs << val }
								else {}
							}
						}
						return r.extract_memories(memories, idxs, top_k)
					}
					else {}
				}
			}
		}
	}

	// ── 2. Fallback: try to parse content as JSON array ────────────
	if resp.content.trim_space().starts_with('[') {
		parsed := json2.decode[json2.Any](resp.content) or {
			return r.fallback.rank(query, memories, top_k)
		}

		arr := parsed.as_array()

		mut idxs := []int{}
		for val in arr {
			match val {
				f64 { idxs << int(val) }
				i64 { idxs << int(val) }
				int { idxs << val }
				else {}
			}
		}

		if idxs.len > 0 {
			return r.extract_memories(memories, idxs, top_k)
		}
	}

	// If we reach here → no valid indices found in content
	return r.fallback.rank(query, memories, top_k)
}

fn (r &LLMMemoryRanker) extract_memories(memories []MemoryItem, idxs []int, top_k int) []MemoryItem {
	mut out := []MemoryItem{cap: top_k}
	mut seen := map[int]bool{}

	mut count := 0
	for idx in idxs {
		if count >= top_k {
			break
		}
		if idx < 0 || idx >= memories.len {
			continue
		}
		if idx in seen {
			continue
		}
		out << memories[idx]
		seen[idx] = true
		count++
	}

	return out
}
