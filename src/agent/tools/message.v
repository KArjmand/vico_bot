module tools

import chat

@[heap; noinit]
pub struct MessageTool {
mut:
	hub &chat.Hub
}

pub fn MessageTool.new(hub &chat.Hub) &MessageTool {
	return &MessageTool{
		hub: hub
	}
}

pub fn (t &MessageTool) name() string {
	return 'message'
}

pub fn (t &MessageTool) description() string {
	return 'Send a message to a user'
}

pub fn (t &MessageTool) parameters() map[string]string {
	return {
		'content': 'The message content to send'
		'channel': 'The channel to send to (default: current)'
		'chat_id': 'The chat ID (default: current)'
	}
}

pub fn (t &MessageTool) execute(args map[string]string) !string {
	content := args['content'] or { return error('content is required') }
	channel := args['channel'] or { 'cli' }
	chat_id := args['chat_id'] or { 'direct' }

	out := chat.Outbound{
		channel: channel
		chat_id: chat_id
		content: content
	}
	t.hub.out <- out
	return 'sent'
}

pub fn (t &MessageTool) set_context(channel string, chat_id string) {
	// Context setting not needed in basic implementation
}
