#!/usr/bin/env -S v run

fn sh(cmd string) {
	println('❯ ${cmd}')
	print(execute_or_exit(cmd).output)
}

fn main() {
	println('Running vicobot tests...')
	println('')

	test_dirs := ['src/agent/memory', 'src/agent/skills', 'src/agent/tools']

	for dir in test_dirs {
		println('=== Testing ${dir} ===')
		sh('v -stats test ${dir}')
		println('')
	}
}
