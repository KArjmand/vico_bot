module agent

import os

fn test_write_memory_tool_today() {
	tmp := os.temp_dir()
	mem := new_memory_store_with_workspace(tmp, 10)
	mut wt := new_write_memory_tool(mem)

	wt.execute({
		'target':  'today'
		'content': 'note A'
	})!

	today := mem.read_today() or { '' }
	assert today.contains('note A'), 'expected today to contain note A'
}

fn test_write_memory_tool_long() {
	tmp := os.temp_dir()
	mem := new_memory_store_with_workspace(tmp, 10)
	mut wt := new_write_memory_tool(mem)

	wt.execute({
		'target':  'long'
		'content': 'LT1'
	})!

	lt := mem.read_long_term() or { '' }
	assert lt.contains('LT1'), 'expected long-term to contain LT1'
}

fn test_write_memory_tool_overwrite() {
	tmp := os.temp_dir()
	mem := new_memory_store_with_workspace(tmp, 10)
	mut wt := new_write_memory_tool(mem)

	wt.execute({
		'target':  'long'
		'content': 'first'
	})!
	wt.execute({
		'target':  'long'
		'content': 'second'
		'append':  'false'
	})!

	lt := mem.read_long_term() or { '' }
	assert lt.contains('second'), 'expected second after overwrite'
}
