module tools

import os

pub struct ExecTool {
	timeout_seconds int
	workspace       string
}

pub fn new_exec_tool(timeout_seconds int) &ExecTool {
	return &ExecTool{
		timeout_seconds: timeout_seconds
		workspace:       ''
	}
}

pub fn new_exec_tool_with_workspace(timeout_seconds int, workspace string) &ExecTool {
	return &ExecTool{
		timeout_seconds: timeout_seconds
		workspace:       workspace
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

fn (t &ExecTool) is_dangerous(cmd string) bool {
	dangerous_programs := ['rm', 'del', 'format', 'mkfs']
	for prog in dangerous_programs {
		if cmd.starts_with('${prog} ') || cmd.starts_with('${prog}\n') {
			return true
		}
	}
	return false
}

fn (t &ExecTool) is_safe_arg(arg string) bool {
	if t.workspace == '' {
		return true
	}
	if arg.starts_with('/') && !arg.starts_with(t.workspace) {
		return false
	}
	if arg.contains('..') {
		return false
	}
	return true
}

pub fn (t &ExecTool) execute(args map[string]string) !string {
	cmd := args['command'] or { return error('command is required') }

	if t.is_dangerous(cmd) {
		return error('dangerous command rejected')
	}

	if t.workspace != '' {
		for arg in cmd.split(' ') {
			if !t.is_safe_arg(arg) {
				return error('unsafe argument rejected: ${arg}')
			}
		}
	}

	res := os.execute(cmd)
	if res.exit_code != 0 {
		return error('command failed')
	}
	return res.output
}
