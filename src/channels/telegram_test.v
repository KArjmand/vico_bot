module channels

import json

fn test_parse_get_updates_response() {
	json_str := '{"ok":true,"result":[{"update_id":1,"message":{"message_id":1,"from":{"id":123},"chat":{"id":456},"text":"hello"}}]}'
	result := json.decode(GetUpdatesResponse, json_str) or {
		assert false
		return
	}
	assert result.ok == true
	assert result.result.len == 1
	assert result.result[0].update_id == 1
}

fn test_start_telegram_empty_token() {
	start_telegram('', unsafe { nil }, []) or {
		assert err.msg() == 'telegram token not provided'
		return
	}
	assert false
}

fn test_start_telegram_with_base_empty_base() {
	start_telegram_with_base('', unsafe { nil }, []) or {
		assert err.msg() == 'base URL is required'
		return
	}
	assert false
}
