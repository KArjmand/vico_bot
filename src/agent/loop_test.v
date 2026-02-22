module agent

import time
import chat
import providers

fn test_process_direct_with_stub() {
	b := chat.new_hub(10)
	p := providers.new_stub_provider()
	mut ag := new_agent_loop(b, p, p.get_default_model(), 5, '.', none)

	result := ag.process_direct('hello', 1 * time.second) or {
		assert false, 'expected no error: ${err}'
		return
	}
	assert result.len > 0
}
