module heartbeat

import os
import time
import context
import chat

fn test_heartbeat_sends_message() {
	ws := os.join_path(os.temp_dir(), 'heartbeat_test')
	os.mkdir_all(ws) or { panic(err) }
	path := os.join_path(ws, 'HEARTBEAT.md')
	os.write_file(path, 'Test task') or { panic(err) }

	mut background := context.background()
	mut ctx, cancel := context.with_cancel(mut background)
	hub := chat.new_hub(10)

	start_heartbeat(mut ctx, ws, 100 * time.millisecond, hub)

	// Wait for the hub to receive the message
	select {
		msg := <-hub.in {
			assert msg.channel == 'heartbeat'
			assert msg.content.contains('Test task')
		}
		2 * time.second {
			assert false, 'heartbeat timed out'
		}
	}

	cancel()
	time.sleep(200 * time.millisecond)
	os.rmdir_all(ws) or { panic(err) }
}
