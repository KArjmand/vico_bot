module agent

import chat
import providers

fn test_agent_can_be_created() {
	b := chat.new_hub(10)
	p := providers.new_stub_provider()
	_ = new_agent_loop(b, p, p.get_default_model(), 5, '.', none)
	assert true
}
