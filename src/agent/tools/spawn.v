module tools

import os

@[noinit]
pub struct SpawnTool {
mut:
	running_processes int
}

pub fn SpawnTool.new() &SpawnTool {
	return &SpawnTool{
		running_processes: 0
	}
}

pub fn (t &SpawnTool) name() string {
	return 'spawn'
}

pub fn (t &SpawnTool) description() string {
	return 'Spawn a background subagent (stub)'
}

pub fn (t &SpawnTool) parameters() map[string]string {
	return {
		'agent': 'The name of the agent to spawn'
		'task':  'The task description for the spawned agent'
	}
}

pub fn (mut t SpawnTool) execute(args map[string]string) !string {
	agent_name := args['agent'] or { '' }
	task := args['task'] or { '' }

	if agent_name == '' && task == '' {
		return error("spawn: 'agent' or 'task' required")
	}

	detach_str := args['detach'] or { 'false' }
	detach := detach_str == 'true'

	if detach {
		t.running_processes++
		return 'spawned: agent=${agent_name} task=${task}'
	}

	res := os.execute('echo "spawned: agent=${agent_name} task=${task}"')
	return res.output
}
