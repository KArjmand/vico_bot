module agent

import memory

fn test_build_messages_includes_memories() ! {
	cb := ContextBuilder.new('.', memory.SimpleRanker.new(), 5)

	history := ['user: hi']

	mems := [
		memory.MemoryItem{
			kind: 'short'
			text: 'remember this'
		},
		memory.MemoryItem{
			kind: 'long'
			text: 'big fact'
		},
	]

	mem_ctx := 'Long-term memory: important fact'

	msgs := cb.build_messages(history, 'hello', 'telegram', '123', mem_ctx, mems)

	assert msgs.len >= 4
	assert msgs[0].role == 'system'

	mut has_mem_ctx := false
	mut has_summary := false

	for msg in msgs {
		if msg.role == 'system' {
			if msg.content.contains(mem_ctx) {
				has_mem_ctx = true
			}
			if msg.content.contains('remember this') && msg.content.contains('big fact') {
				has_summary = true
			}
		}
	}

	assert has_mem_ctx, 'memory context not found in system messages'
	assert has_summary, 'memory items summary not found in system messages'
}
