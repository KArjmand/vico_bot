module chat

import time

pub struct Inbound {
pub:
	channel   string
	sender_id string
	chat_id   string
	content   string
	timestamp time.Time
	media     []string
}

pub struct Outbound {
pub:
	channel  string
	chat_id  string
	content  string
	reply_to string
	media    []string
}

@[heap; noinit]
pub struct Hub {
pub:
	in  chan Inbound
	out chan Outbound
}

pub fn Hub.new(buffer int) Hub {
	return Hub{
		in:  chan Inbound{cap: buffer}
		out: chan Outbound{cap: buffer}
	}
}

pub fn (mut h Hub) close() {
	h.in.close()
	h.out.close()
}
