module providers

import context
import x.json2

// Message represents a chat message to/from the LLM.
@[noinit]
pub struct Message {
pub:
	role         string // "system" | "user" | "assistant" | "tool"
	content      string
	tool_call_id string     // set when Role == "tool"
	tool_calls   []ToolCall // set on assistant msgs with tool calls
}

// new_message creates a new Message instance
pub fn Message.new(role string, content string) Message {
	return Message{
		role:         role
		content:      content
		tool_call_id: ''
		tool_calls:   []
	}
}

// Factory functions - most idiomatic in V

pub fn Message.system(content string) Message {
	return Message{
		role:    'system'
		content: content
	}
}

pub fn Message.user(content string) Message {
	return Message{
		role:    'user'
		content: content
	}
}

pub fn Message.assistant(content string) Message {
	return Message{
		role:    'assistant'
		content: content
	}
}

pub fn Message.assistant_with_tools(content string, tool_calls []ToolCall) Message {
	return Message{
		role:       'assistant'
		content:    content
		tool_calls: tool_calls.clone() // usually we clone to be safe
	}
}

// new_tool_message creates a new tool response message
pub fn Message.tool(content string, tool_call_id string) Message {
	return Message{
		role:         'tool'
		content:      content
		tool_call_id: tool_call_id
		tool_calls:   []
	}
}

// new_assistant_message creates a new assistant message with optional tool calls
pub fn Message.assistant_with_tool_calls(content string, tool_calls []ToolCall) Message {
	return Message{
		role:         'assistant'
		content:      content
		tool_call_id: ''
		tool_calls:   tool_calls
	}
}

// ToolDefinition is a lightweight description of a tool available to the model.
pub struct ToolDefinition {
pub mut:
	name        string
	description string
	parameters  map[string]json2.Any @[json2: 'parameters'; raw]
}

// ToolCall represents a request from the LLM to invoke a tool.
pub struct ToolCall {
pub mut:
	id        string
	name      string
	arguments map[string]json2.Any
}

// LLMResponse is a normalized response from a provider.
pub struct LLMResponse {
pub:
	content        string
	has_tool_calls bool
	tool_calls     []ToolCall
}

// LLMProvider is the interface used by the agent loop to call LLMs.
pub interface LLMProvider {
	// Chat sends messages to the model and returns a normalized response.
	// ctx can be used for cancellation and timeout.
	chat(mut ctx context.Context, messages []Message, tools []ToolDefinition, model string) !LLMResponse
	// get_default_model returns the provider's default model string.
	get_default_model() string
}
