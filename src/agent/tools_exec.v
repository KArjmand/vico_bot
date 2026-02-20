module agent

import os
import net.http

pub struct ExecTool {
	timeout_seconds int
}

pub fn new_exec_tool(timeout_seconds int) &ExecTool {
	return &ExecTool{
		timeout_seconds: timeout_seconds
	}
}

pub fn (t &ExecTool) name() string {
	return 'exec'
}

pub fn (t &ExecTool) description() string {
	return 'Execute shell commands and return the output'
}

pub fn (t &ExecTool) parameters() map[string]string {
	return {
		'command': 'The shell command to execute'
	}
}

pub fn (t &ExecTool) execute(args map[string]string) !string {
	cmd := args['command'] or { return error('command is required') }
	res := os.execute(cmd)
	if res.exit_code != 0 {
		return error('command failed: ${res.output}')
	}
	return res.output
}

pub struct WebTool {
mut:
	last_url string
}

pub fn new_web_tool() &WebTool {
	return &WebTool{}
}

pub fn (t &WebTool) name() string {
	return 'web'
}

pub fn (t &WebTool) description() string {
	return 'Fetch web pages and return their content'
}

pub fn (t &WebTool) parameters() map[string]string {
	return {
		'url': 'The URL to fetch'
	}
}

pub fn (mut t WebTool) execute(args map[string]string) !string {
	url := args['url'] or { return error('url is required') }
	t.last_url = url

	// Simple HTTP fetch implementation
	resp := http.get(url) or { return error('failed to fetch ${url}: ${err}') }
	return resp.body
}

pub struct SpawnTool {
mut:
	running_processes int
}

pub fn new_spawn_tool() &SpawnTool {
	return &SpawnTool{
		running_processes: 0
	}
}

pub fn (t &SpawnTool) name() string {
	return 'spawn'
}

pub fn (t &SpawnTool) description() string {
	return 'Spawn a long-running process'
}

pub fn (t &SpawnTool) parameters() map[string]string {
	return {
		'command': 'The command to run'
		'detach':  'Whether to detach and return immediately'
	}
}

pub fn (mut t SpawnTool) execute(args map[string]string) !string {
	cmd := args['command'] or { return error('command is required') }

	detach_str := args['detach'] or { 'false' }

	detach := detach_str == 'true'

	if detach {
		t.running_processes++
		return 'Process spawned with PID (detached)'
	}
	res := os.execute(cmd)
	return res.output
}
