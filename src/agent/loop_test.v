module agent

import time
import chat
import providers

fn test_process_direct_with_stub() {
	b := chat.Hub.new(10)
	p := providers.StubProvider.new()
	mut ag := AgentLoop.new(b, p, p.get_default_model(), 5, '.', none)

	result := ag.process_direct('hello', 1 * time.second) or {
		assert false, 'expected no error: ${err}'
		return
	}
	assert result.len > 0
}
