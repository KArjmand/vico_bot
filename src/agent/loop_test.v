module agent

import time
import chat
import providers

fn test_process_direct_with_stub() {
	b := chat.Hub.new(10)
	p := providers.StubProvider.new()
	mut ag := AgentLoop.new(
		hub:            b
		provider:       p
		model:          p.get_default_model()
		max_iterations: 5
	)

	result := ag.process_direct('hello', 1 * time.second) or {
		assert false, 'expected no error: ${err}'
		return
	}
	assert result.len > 0
}
