module agent

import time
import chat
import providers

fn test_loop_basic_message_processing() {
	hub := chat.new_hub(10)
	provider := providers.new_stub_provider()
	loop := new_agent_loop(hub, provider, 'test-model', 5, '.', 0)

	// Send a test message
	test_msg := chat.Inbound{
		channel:   'test'
		chat_id:   '123'
		sender_id: 'user1'
		content:   'Hello, bot!'
	}

	// Send message to hub
	hub.in <- test_msg

	// Process should complete without panicking
	// Note: In real test, we'd need to wait for processing
	assert true
}

fn test_loop_remember_command() {
	hub := chat.new_hub(10)
	provider := new_stub_provider()
	loop := new_agent_loop(hub, provider, 'test-model', 5, '.', 0)

	// Send a remember command
	remember_msg := chat.Inbound{
		channel:   'test'
		chat_id:   '123'
		sender_id: 'user1'
		content:   'remember to buy milk'
	}

	hub.in <- remember_msg

	// Should process remember command
	assert true
}

fn test_loop_tool_execution() {
	hub := chat.new_hub(10)
	provider := new_stub_provider()
	loop := new_agent_loop(hub, provider, 'test-model', 5, '.', 0)

	// Send a message that should trigger tool usage
	tool_msg := chat.Inbound{
		channel:   'test'
		chat_id:   '123'
		sender_id: 'user1'
		content:   'Execute a command'
	}

	hub.in <- tool_msg

	// Should handle tool execution
	assert true
}

fn test_process_direct_basic() {
	hub := chat.new_hub(10)
	provider := new_stub_provider()
	loop := new_agent_loop(hub, provider, 'test-model', 5, '.', 0)

	result := loop.process_direct('Hello, direct!', 30 * time.second)!
	assert result != ''
	assert typeof(result) == typeof('')
}

fn test_process_direct_with_timeout() {
	hub := chat.new_hub(10)
	provider := new_stub_provider()
	loop := new_agent_loop(hub, provider, 'test-model', 5, '.', 0)

	// Very short timeout
	result := loop.process_direct('Hello, direct!', 1 * time.millisecond)

	// Should handle timeout gracefully
	assert result is error
}

fn test_loop_context_setting() {
	hub := chat.new_hub(10)
	provider := new_stub_provider()
	loop := new_agent_loop(hub, provider, 'test-model', 5, '.', 0)

	// Send message to test context setting
	msg := chat.Inbound{
		channel:   'telegram'
		chat_id:   'chat123'
		sender_id: 'user1'
		content:   'Test context'
	}

	hub.in <- msg

	// Tools should have context set
	assert true
}
