module tools

import os

fn test_exec_array_echo() {
	mut t := ExecTool.new(5)
	res := t.execute({
		'command': 'echo hello'
	})!
	assert res.trim_space() == 'hello'
}

fn test_exec_string_allowed() {
	mut t := ExecTool.new(5)
	// In V, string commands are allowed (different from Go)
	res := t.execute({
		'command': 'echo test'
	})!
	assert res.contains('test')
}

fn test_exec_dangerous_prog_rejected() {
	mut t := ExecTool.new(5)
	_ := t.execute({
		'command': 'rm -rf /'
	}) or { return }
	assert false, 'expected error for dangerous program'
}

fn test_exec_with_workspace() {
	ws_dir := os.temp_dir()
	test_file := os.join_path(ws_dir, 'vicobot_test_file.txt')
	os.write_file(test_file, 'content') or { return }
	defer {
		os.rm(test_file) or {}
	}

	mut t := ExecTool.new_with_workspace(5, ws_dir)
	res := t.execute({
		'command': 'cat vicobot_test_file.txt'
	}) or {
		println('exec error: ${err}')
		return
	}
	assert res.trim_space() == 'content'
}

fn test_exec_rejects_unsafe_arg() {
	ws_dir := os.temp_dir()
	mut t := ExecTool.new_with_workspace(5, ws_dir)
	_ := t.execute({
		'command': 'ls /etc'
	}) or { return }
	assert false, 'expected error for absolute path arg'
}
