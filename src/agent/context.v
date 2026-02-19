module agent

import os
import providers

pub struct ContextBuilder {
pub:
	workspace     string
	ranker        ?Ranker
	top_k         int
	skills_loader &SkillsLoader
}

pub fn new_context_builder(workspace string, r ?Ranker, top_k int) &ContextBuilder {
	return &ContextBuilder{
		workspace:     workspace
		ranker:        r
		top_k:         top_k
		skills_loader: new_skills_loader(workspace)
	}
}

pub fn (cb &ContextBuilder) build_messages(history []string,
	current_message string,
	channel string,
	chat_id string,
	memory_context string,
	memories []MemoryItem) []providers.Message {
	mut msgs := []providers.Message{len: 0, cap: history.len + 8}
	msgs << providers.new_system_message('You are Vicobot, a helpful assistant.')

	bootstrap_files := ['SOUL.md', 'AGENTS.md', 'USER.md', 'TOOLS.md']
	for name in bootstrap_files {
		path := os.join_path(cb.workspace, name)
		if !os.exists(path) {
			continue
		}
		data := os.read_file(path) or { continue }
		content := data.trim_space()
		if content != '' {
			msgs << providers.new_system_message('## ${name}\n\n${content}')
		}
	}

	msgs << providers.new_system_message('You are operating on channel="${channel}" chatID="${chat_id}". You have full access to all registered tools regardless of the channel. Always use your tools when the user asks you to perform actions (file operations, shell commands, web fetches, etc.).')

	msgs << providers.new_system_message('If you decide something should be remembered, call the tool \'write_memory\' with JSON arguments: {"target":"today"|"long", "content":"...", "append":true|false}. Use a tool call rather than plain chat text when writing memory.')

	loaded_skills := cb.skills_loader.load_all() or { []Skill{} }
	if loaded_skills.len > 0 {
		mut sb := 'Available Skills:\n'
		for skill in loaded_skills {
			sb += '\n## ${skill.name}\n${skill.description}\n\n${skill.content}\n'
		}
		msgs << providers.new_system_message(sb)
	}

	if memory_context != '' {
		msgs << providers.new_system_message('Memory:\n' + memory_context)
	}

	mut selected := memories.clone()
	if ranker := cb.ranker {
		selected = ranker.rank(current_message, memories, cb.top_k)
	}
	if selected.len > 0 {
		mut sb := 'Relevant memories:\n'
		for m in selected {
			sb += '- ${m.text} (${m.kind})\n'
		}
		msgs << providers.new_system_message(sb)
	}

	for h in history {
		if h.len > 0 {
			msgs << providers.new_message('user', h)
		}
	}

	msgs << providers.new_message('user', current_message)
	return msgs
}
