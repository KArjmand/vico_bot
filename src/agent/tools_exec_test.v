module agent

fn test_exec_tool() {
	mut t := new_exec_tool(5)
	assert t.name() == 'exec'
	assert t.description() != ''

	res := t.execute({
		'command': 'echo hello'
	}) or { 'failed' }
	assert res.contains('hello')
}

fn test_web_tool() {
	mut t := new_web_tool()
	assert t.name() == 'web'

	res := t.execute({
		'url': 'https://example.com'
	}) or { 'failed' }
	assert res.contains('example.com')
}

fn test_spawn_tool_detached() {
	mut t := new_spawn_tool()
	assert t.name() == 'spawn'

	res := t.execute({
		'command': 'echo test'
		'detach':  'true'
	}) or { 'failed' }
	assert res.contains('spawned')
}

fn test_spawn_tool_blocking() {
	mut t := new_spawn_tool()
	res := t.execute({
		'command': 'echo blocking'
		'detach':  'false'
	}) or { 'failed' }
	assert res.contains('blocking')
}
