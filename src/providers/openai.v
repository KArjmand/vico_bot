module providers

import net.http
import time
import context
import x.json2

// OpenAIProvider calls an OpenAI-compatible API
@[noinit]
pub struct OpenAIProvider {
pub:
	api_key  string
	api_base string
pub mut:
	timeout    time.Duration
	max_tokens int
}

pub fn OpenAIProvider.new(api_key string, api_base string, max_tokens int) OpenAIProvider {
	mut base := api_base
	if base == '' {
		base = 'https://api.openai.com/v1'
	}
	// Fixed: trim_suffix returns the new string, doesn't modify in place
	if base.ends_with('/') {
		base = base.all_before_last('/')
	}
	return OpenAIProvider{
		api_key:    api_key
		api_base:   base
		timeout:    60 * time.second
		max_tokens: max_tokens
	}
}

// Internal JSON structures - Use json2.Any throughout for consistency
struct ChatRequest {
	model      string
	messages   []MessageJSON
	tools      []ToolWrapper @[json: 'tools'; skip_empty]
	max_tokens int           @[json: 'max_tokens']
}

struct ToolWrapper {
	typ      string @[json: 'type']
	function FunctionDef
}

struct FunctionDef {
	name        string
	description string
	parameters  map[string]json2.Any @[json: 'parameters'; raw; skip_empty]
}

struct MessageJSON {
	role         string
	content      string
	tool_call_id string @[json: 'tool_call_id'; skip_empty]
pub mut:
	// MUST be pub mut to append to this array later
	tool_calls []ToolCallJSON @[json: 'tool_calls'; skip_empty]
}

struct ToolCallJSON {
	id       string
	typ      string @[json: 'type']
	function ToolCallFunctionJSON
}

struct ToolCallFunctionJSON {
	name      string
	arguments string
}

struct MessageResponseJSON {
	role       string
	content    string
	tool_calls []ToolCallJSON @[json: 'tool_calls'; skip_empty]
}

pub struct ChoiceJSON {
	message MessageResponseJSON
}

struct ChatResponse {
	choices []ChoiceJSON
}

pub fn new_openai_provider(api_key string, api_base string, max_tokens int) OpenAIProvider {
	mut base := api_base
	if base == '' {
		base = 'https://api.openai.com/v1'
	}
	// Fixed: trim_suffix returns the new string, doesn't modify in place
	if base.ends_with('/') {
		base = base.all_before_last('/')
	}
	return OpenAIProvider{
		api_key:    api_key
		api_base:   base
		timeout:    60 * time.second
		max_tokens: max_tokens
	}
}

pub fn (p OpenAIProvider) get_default_model() string {
	return 'gpt-4o-mini'
}

pub fn (p OpenAIProvider) chat(mut ctx context.Context, messages []Message, tools []ToolDefinition, model string) !LLMResponse {
	if ctx.err() !is none {
		return error('context canceled')
	}

	mut mdl := if model == '' { p.get_default_model() } else { model }

	mut req_messages := []MessageJSON{}
	for m in messages {
		mut mj := MessageJSON{
			role:         m.role
			content:      m.content
			tool_call_id: m.tool_call_id
		}
		for tc in m.tool_calls {
			// Use json2.encode for map[string]json2.Any
			args_json := json2.encode(tc.arguments)
			mj.tool_calls << ToolCallJSON{
				id:       tc.id
				typ:      'function'
				function: ToolCallFunctionJSON{
					name:      tc.name
					arguments: args_json
				}
			}
		}
		req_messages << mj
	}

	mut req_tools := []ToolWrapper{}
	for t in tools {
		// Use .clone() to copy maps in V
		mut params := t.parameters.clone()
		if params.len == 0 {
			params['type'] = json2.Any('object')
			params['properties'] = json2.Any(map[string]json2.Any{})
		}
		req_tools << ToolWrapper{
			typ:      'function'
			function: FunctionDef{
				name:        t.name
				description: t.description
				parameters:  params
			}
		}
	}

	req_body := ChatRequest{
		model:      mdl
		messages:   req_messages
		tools:      req_tools
		max_tokens: if p.max_tokens > 0 { p.max_tokens } else { 4096 }
	}

	mut header := http.new_header()
	header.set(.authorization, 'Bearer ${p.api_key}')
	header.set(.content_type, 'application/json')

	mut req := http.Request{
		url:    '${p.api_base}/chat/completions'
		method: .post
		header: header
		data:   json2.encode(req_body)
		// Set timeouts using time.Duration
		read_timeout:  p.timeout
		write_timeout: p.timeout
	}

	resp := req.do() or {
		// Handle network errors, including timeouts
		eprintln('Request failed: ${err}')
		// Return the error to satisfy the !LLMResponse return type
		return err
	}

	if resp.status_code != 200 {
		return error('OpenAI API error: ${resp.status_code} - ${resp.body}')
	}

	out := json2.decode[ChatResponse](resp.body)!

	if out.choices.len == 0 {
		return error('OpenAI API returned no choices')
	}

	msg := out.choices[0].message

	if msg.tool_calls.len > 0 {
		mut tcs := []ToolCall{}
		for tc in msg.tool_calls {
			parsed := json2.decode[map[string]json2.Any](tc.function.arguments) or { continue }
			tcs << ToolCall{
				id:        tc.id
				name:      tc.function.name
				arguments: parsed
			}
		}
		return LLMResponse{
			content:        msg.content.trim_space()
			has_tool_calls: true
			tool_calls:     tcs
		}
	}

	return LLMResponse{
		content:        msg.content.trim_space()
		has_tool_calls: false
	}
}
