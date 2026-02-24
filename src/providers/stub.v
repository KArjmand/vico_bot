module providers

import context

// StubProvider is a simple provider useful for local testing.
// It echoes back the last user message.
@[noinit]
pub struct StubProvider {}

pub fn StubProvider.new() StubProvider {
	return StubProvider{}
}

pub fn (p StubProvider) chat(mut ctx context.Context, messages []Message, tools []ToolDefinition, model string) !LLMResponse {
	// Check if context is already canceled
	if ctx.err() !is none {
		return error('context canceled')
	}

	// Find last user message
	mut last := ''
	for i := messages.len - 1; i >= 0; i-- {
		if messages[i].role == 'user' {
			last = messages[i].content
			break
		}
	}
	if last == '' {
		return LLMResponse{
			content: '(stub) Hello from StubProvider'
		}
	}
	return LLMResponse{
		content: '(stub) Echo: ${last}'
	}
}

pub fn (p StubProvider) get_default_model() string {
	return 'stub-model'
}
