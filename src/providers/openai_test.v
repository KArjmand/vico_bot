module providers

import net.http
import time
import context
import x.json2

// Simple handler struct for the test server
struct TestHandler {}

fn (h TestHandler) handle(req http.Request) http.Response {
	return http.Response{
		status_code: 200
		header:      http.new_header(key: .content_type, value: 'application/json')
		body:        r'{
		  "choices": [
			{
			  "message": {
				"role": "assistant",
				"content": "",
				"tool_calls": [
				  {
					"id": "call_001",
					"type": "function",
					"function": {
					  "name": "message",
					  "arguments": "{\"content\": \"Hello from function\"}"
					}
				  }
				]
			  }
			}
		  ]
		}'
	}
}

fn test_openai_function_call_parsing() {
	mut server := &http.Server{
		addr:    'localhost:12345'
		handler: TestHandler{}
	}

	// Run server in background
	spawn server.listen_and_serve()
	time.sleep(100 * time.millisecond) // Give server a moment to start

	// Initialize provider as mut
	mut p := OpenAIProvider.new('test-key', 'http://localhost:12345', 4096)
	p.timeout = 5 * time.second

	mut base_ctx := context.background()
	// Context returns a result and needs 'mut'
	mut ctx, cancel := context.with_timeout(mut base_ctx, 2 * time.second)
	defer { cancel() }

	msgs := [Message{
		role:    'user'
		content: 'trigger'
	}]

	// Call with 'mut p' and 'mut ctx'
	resp := p.chat(mut ctx, msgs, [], 'model-x') or { panic('expected no error, but got: ${err}') }

	assert resp.has_tool_calls
	assert resp.tool_calls.len == 1
	assert resp.tool_calls[0].name == 'message'

	// json2.Any is a sum type; use .str() or .get_string() to compare
	content_arg := resp.tool_calls[0].arguments['content'] or { json2.Any(false) }
	assert content_arg.str() == 'Hello from function'
}
