module channels

import json
import net.http
import strconv
import time
import chat

struct GetUpdatesResponse {
	ok     bool
	result []Update
}

struct Update {
	update_id i64
	message   ?Message
}

struct Message {
	message_id i64
	from       ?From
	chat       Chat
	text       string
}

struct From {
	id int
}

struct Chat {
	id int
}

pub fn start_telegram(token string, hub &chat.Hub, allow_from []string) ! {
	if token == '' {
		return error('telegram token not provided')
	}
	base := 'https://api.telegram.org/bot${token}'
	return start_telegram_with_base(base, hub, allow_from)
}

pub fn start_telegram_with_base(base string, hub &chat.Hub, allow_from []string) ! {
	if base == '' {
		return error('base URL is required')
	}

	mut allowed := map[string]bool{}
	for id in allow_from {
		allowed[id] = true
	}

	spawn fn [hub, base, allowed] () {
		inbound_polling(hub, base, allowed)
	}()

	spawn fn [hub, base] () {
		outbound_sender(hub, base)
	}()
}

fn inbound_polling(hub &chat.Hub, base string, allowed map[string]bool) {
	mut offset := i64(0)
	for {
		time.sleep(1 * time.second)

		values := {
			'offset':  strconv.format_int(offset, 10)
			'timeout': '30'
		}
		url := '${base}/getUpdates'
		resp := http.post_form(url, values) or {
			println('telegram getUpdates error: ${err}')
			continue
		}
		body := resp.body

		gu := json.decode(GetUpdatesResponse, body) or {
			println('telegram: invalid getUpdates response: ${err}')
			continue
		}
		for upd in gu.result {
			if upd.update_id >= offset {
				offset = upd.update_id + 1
			}
			if m := upd.message {
				mut from_id := ''
				if m.from != none {
					from_id = strconv.format_int(m.from.id, 10)
				}
				if allowed.len > 0 {
					if from_id !in allowed {
						println('telegram: dropping message from unauthorized user ${from_id}')
						continue
					}
				}
				chat_id := strconv.format_int(m.chat.id, 10)
				hub.in <- chat.Inbound{
					channel:   'telegram'
					sender_id: from_id
					chat_id:   chat_id
					content:   m.text
					timestamp: time.now()
				}
			}
		}
	}
}

fn outbound_sender(hub &chat.Hub, base string) {
	for {
		out := <-hub.out
		if out.channel != 'telegram' {
			continue
		}

		// Send "typing..." indicator before actual message
		send_typing_action(base, out.chat_id)

		url := '${base}/sendMessage'
		values := {
			'chat_id': out.chat_id
			'text':    out.content
		}
		resp := http.post_form(url, values) or {
			println('telegram sendMessage error: ${err}')
			continue
		}
		_ := resp.body
	}
}

fn send_typing_action(base string, chat_id string) {
	url := '${base}/sendChatAction'
	values := {
		'chat_id': chat_id
		'action':  'typing'
	}
	resp := http.post_form(url, values) or {
		println('telegram typing action error: ${err}')
		return
	}
	_ := resp.body
}
