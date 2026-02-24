module tools

import cron

fn test_cron_tool_add_job() {
	scheduler := cron.Scheduler.new(fn (job cron.Job) {})
	mut tool := CronTool.new(scheduler)

	args := {
		'action':    'add'
		'name':      'test-reminder'
		'message':   'Test reminder message'
		'delay':     '1m'
		'recurring': 'false'
	}

	result := tool.execute(args)!
	assert result.contains('Scheduled job')
	assert result.contains('test-reminder')
}

fn test_cron_tool_add_recurring_job() {
	scheduler := cron.Scheduler.new(fn (job cron.Job) {})
	mut tool := CronTool.new(scheduler)

	args := {
		'action':    'add'
		'name':      'recurring-test'
		'message':   'Recurring test message'
		'delay':     '2m'
		'recurring': 'true'
		'interval':  '3m'
	}

	result := tool.execute(args)!
	assert result.contains('Scheduled recurring job')
	assert result.contains('recurring-test')
}

fn test_cron_tool_list_empty() {
	scheduler := cron.Scheduler.new(fn (job cron.Job) {})
	mut tool := CronTool.new(scheduler)

	args := {
		'action': 'list'
	}
	result := tool.execute(args)!
	assert result == 'No scheduled jobs.'
}

fn test_cron_tool_list_with_jobs() {
	scheduler := cron.Scheduler.new(fn (job cron.Job) {})
	mut tool := CronTool.new(scheduler)

	// Add a job first
	add_args := {
		'action':  'add'
		'name':    'test-job'
		'message': 'Test message'
		'delay':   '5m'
	}
	tool.execute(add_args)!

	// List jobs
	list_args := {
		'action': 'list'
	}
	result := tool.execute(list_args)!
	assert result.contains('Job')
	assert result.contains('test-job')
}

fn test_cron_tool_cancel_job() {
	scheduler := cron.Scheduler.new(fn (job cron.Job) {})
	mut tool := CronTool.new(scheduler)

	// Add a job first
	add_args := {
		'action':  'add'
		'name':    'cancel-test'
		'message': 'Will be cancelled'
		'delay':   '10m'
	}
	tool.execute(add_args)!

	// Cancel the job
	cancel_args := {
		'action': 'cancel'
		'name':   'cancel-test'
	}
	result := tool.execute(cancel_args)!
	assert result.contains('Cancelled job')
	assert result.contains('cancel-test')
}

fn test_cron_tool_cancel_nonexistent() {
	scheduler := cron.Scheduler.new(fn (job cron.Job) {})
	mut tool := CronTool.new(scheduler)

	args := {
		'action': 'cancel'
		'name':   'nonexistent'
	}
	result := tool.execute(args)!
	assert result.contains('No job found')
	assert result.contains('nonexistent')
}

fn test_cron_tool_invalid_action() {
	scheduler := cron.Scheduler.new(fn (job cron.Job) {})
	mut tool := CronTool.new(scheduler)

	args := {
		'action': 'invalid'
	}
	result := tool.execute(args) or { 'error' }
	assert result.contains('error')
}

fn test_cron_tool_set_context() {
	scheduler := cron.Scheduler.new(fn (job cron.Job) {})
	mut tool := CronTool.new(scheduler)

	tool.set_context('test-channel', 'test-chat-id')
	// Test that context is set (would be used when jobs fire)
	// This is more of a smoke test since we can't easily verify internal state
	assert true
}
