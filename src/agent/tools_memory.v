module agent

@[heap]
pub struct WriteMemoryTool {
mut:
	memory &MemoryStore
}

pub fn new_write_memory_tool(memory &MemoryStore) &WriteMemoryTool {
	return &WriteMemoryTool{
		memory: memory
	}
}

pub fn (t &WriteMemoryTool) name() string {
	return 'write_memory'
}

pub fn (t &WriteMemoryTool) description() string {
	return 'Store information in memory for later retrieval'
}

pub fn (t &WriteMemoryTool) parameters() map[string]string {
	return {
		'target':  'Memory target: "today" or "long"'
		'content': 'The content to remember'
		'append':  'Whether to append to existing memory (default: true)'
	}
}

pub fn (mut t WriteMemoryTool) execute(args map[string]string) !string {
	target := args['target'] or { 'today' }
	content := args['content'] or { return error('content is required') }
	append_str := args['append'] or { 'true' }
	append := append_str == 'true'

	match target {
		'today' {
			if append {
				t.memory.append_today(content)!
				return "Appended to today's memory"
			}
			t.memory.add_short(content)
			return 'Added to short-term memory'
		}
		'long' {
			t.memory.add_long(content)
			return 'Added to long-term memory'
		}
		else {
			return error('invalid target: ${target}. Use "today" or "long"')
		}
	}
}
