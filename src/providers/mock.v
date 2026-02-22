module providers

import context

pub struct MockProvider {
pub mut:
	response   string
	tool_calls []ToolCall
}

pub fn new_mock_provider() MockProvider {
	return MockProvider{}
}

pub fn (p MockProvider) chat(mut ctx context.Context, messages []Message, tools []ToolDefinition, model string) !LLMResponse {
	if ctx.err() !is none {
		return error('context canceled')
	}

	if p.tool_calls.len > 0 {
		return LLMResponse{
			content:        p.response
			has_tool_calls: true
			tool_calls:     p.tool_calls
		}
	}

	return LLMResponse{
		content:        p.response
		has_tool_calls: false
		tool_calls:     []
	}
}

pub fn (p MockProvider) get_default_model() string {
	return 'mock-model'
}
