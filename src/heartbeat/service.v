module heartbeat

import os
import time
import context
import chat

// start_heartbeat starts a periodic check that reads HEARTBEAT.md and pushes
// its content into the agent's inbound chat hub for processing.
pub fn start_heartbeat(mut ctx context.Context, workspace string, interval time.Duration, hub &chat.Hub) {
	spawn fn (mut ctx context.Context, workspace string, interval time.Duration, hub &chat.Hub) {
		println('heartbeat: started (every ${interval})')

		done_chan := ctx.done()

		for {
			select {
				_ := <-done_chan {
					println('heartbeat: stopping')
					return
				}
				else {}
			}

			path := os.join_path(workspace, 'HEARTBEAT.md')

			data := os.read_file(path) or {
				time.sleep(interval)
				continue
			}

			content := data.trim_space()
			if content == '' {
				time.sleep(interval)
				continue
			}

			println('heartbeat: sending tasks to agent')

			hub.in <- chat.Inbound{
				channel:   'heartbeat'
				chat_id:   'system'
				sender_id: 'heartbeat'
				content:   '[HEARTBEAT CHECK] Review and execute any pending tasks from HEARTBEAT.md:\n\n${content}'
			}

			time.sleep(interval)
		}
	}(mut ctx, workspace, interval, hub)
}
