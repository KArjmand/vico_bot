#!/usr/bin/env -S v run

// Test runner script - runs each test file individually to avoid parallel runner issues

fn sh(cmd string) {
	println('❯ ${cmd}')
	print(execute_or_exit(cmd).output)
}

fn run_test(file string) {
	println('--- Testing ${file} ---')
	sh('v -stats test ${file}')
	println('')
}

fn main() {
	println('Running vicobot tests (sequential)...')
	println('')

	// Run each test file individually
	run_test('src/agent/memory/memory_test.v')
	run_test('src/agent/memory/ranker_test.v')
	run_test('src/agent/memory/llm_ranker_test.v')
	run_test('src/agent/skills/skills_test.v')
	run_test('src/agent/tools/cron_test.v')
	run_test('src/agent/tools/exec_test.v')
	run_test('src/agent/tools/memory_test.v')
	run_test('src/agent/tools/skills_test.v')
	run_test('src/agent/tools/tools_test.v')

	println('✅ All tests complete!')
}
