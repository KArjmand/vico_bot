#!/usr/bin/env -S v run

// Dynamic test runner - finds and runs all *_test.v files sequentially

fn main() {
	println('Running vicobot tests (dynamic discovery)...')
	println('')

	// Find all test files using find command
	result := execute('find src -name "*_test.v" -type f')
	if result.exit_code != 0 {
		println('Failed to find test files!')
		exit(1)
	}

	mut test_files := result.output.split('\n').filter(it.len > 0)

	if test_files.len == 0 {
		println('No test files found!')
		exit(1)
	}

	// Sort for consistent ordering
	test_files.sort()

	println('Found ${test_files.len} test files:')
	for file in test_files {
		println('  - ${file}')
	}
	println('')

	// Run each test file
	mut passed := 0
	mut failed := 0
	mut failed_files := []string{}

	for file in test_files {
		println('--- Testing ${file} ---')
		test_result := execute('v -stats test ${file}')
		if test_result.exit_code == 0 {
			passed++
			println('✅ PASS')
		} else {
			failed++
			failed_files << file
			println('❌ FAIL')
		}
		println('')
	}

	println('========================================')
	println('Results: ${passed} passed, ${failed} failed')

	if failed_files.len > 0 {
		println('Failed files:')
		for f in failed_files {
			println('  ❌ ${f}')
		}
		exit(1)
	}

	println('✅ All tests passed!')
}
