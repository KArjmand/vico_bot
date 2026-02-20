module agent

import time
import cron

pub struct CronTool {
mut:
	scheduler cron.Scheduler
	channel   string
	chat_id   string
}

pub fn new_cron_tool(scheduler cron.Scheduler) &CronTool {
	return &CronTool{
		scheduler: scheduler
	}
}

pub fn (t &CronTool) name() string {
	return 'cron'
}

pub fn (t &CronTool) description() string {
	return 'Schedule one-time or recurring reminders/tasks. Actions: add (schedule), list (show pending), cancel (remove by name).'
}

pub fn (t &CronTool) parameters() map[string]string {
	return {
		'type':       'object'
		'properties': '{
            "action": {
                "type":        "string",
                "description": "The action: add (schedule a new job), list (show pending jobs), cancel (remove a job by name)",
                "enum":        ["add", "list", "cancel"]
            },
            "name": {
                "type":        "string",
                "description": "A short name for the job (used to identify it for cancellation)"
            },
            "message": {
                "type":        "string",
                "description": "The reminder message or task description to deliver when the job fires"
            },
            "delay": {
                "type":        "string",
                "description": "How long to wait before first firing, e.g. \'2m\', \'1h30m\', \'30s\', \'1h\'. Uses Go duration format."
            },
            "recurring": {
                "type":        "boolean",
                "description": "If true, the job will repeat at the specified interval. If false or omitted, fires only once."
            },
            "interval": {
                "type":        "string",
                "description": "For recurring jobs: how often to repeat (minimum 2m). Uses Go duration format."
            }
        }'
		'required':   '["action"]'
	}
}

pub fn (mut t CronTool) set_context(channel string, chat_id string) {
	t.channel = channel
	t.chat_id = chat_id
}

pub fn (mut t CronTool) execute(args map[string]string) !string {
	action := args['action'] or { return error('action is required') }

	match action {
		'add' {
			name := args['name'] or { 'reminder' }
			message := args['message'] or { return error('message is required') }
			delay_str := args['delay'] or { return error("delay is required (e.g. '2m', '1h')") }

			mut delay := time.Duration(0)
			if delay_str.ends_with('s') {
				seconds := delay_str[..delay_str.len - 1].int()
				delay = seconds * time.second
			} else if delay_str.ends_with('m') {
				minutes := delay_str[..delay_str.len - 1].int()
				delay = minutes * time.minute
			} else if delay_str.ends_with('h') {
				hours := delay_str[..delay_str.len - 1].int()
				delay = hours * time.hour
			} else {
				return error('invalid delay format: ${delay_str} (use s, m, or h suffix)')
			}

			if delay < 30 * time.second {
				return error('delay must be at least 30s (got ${delay_str})')
			}

			recurring_str := args['recurring'] or { 'false' }
			recurring := recurring_str == 'true'

			if recurring {
				return 'Recurring jobs not yet supported.'
			}

			id := t.scheduler.add(name, message, delay, t.channel, t.chat_id)
			return 'Scheduled job "${name}" (id: ${id}). Will fire in ${delay_str}.'
		}
		'list' {
			jobs := t.scheduler.list()
			if jobs.len == 0 {
				return 'No scheduled jobs.'
			}
			mut output := []string{}
			for job in jobs {
				output << 'Job ${job.id}: ${job.name} - ${job.message} (next: ${job.fire_at})'
			}
			return output.join('\n')
		}
		'cancel' {
			name := args['name'] or { return error('name is required') }

			cancelled := t.scheduler.cancel_by_name(name)
			if cancelled {
				return 'Cancelled job "${name}".'
			} else {
				return 'No job found with name "${name}".'
			}
		}
		else {
			return error('unknown action: ${action}')
		}
	}
}
