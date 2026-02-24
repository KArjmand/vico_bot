module tools

import memory as memory_module

@[heap; noinit]
pub struct WriteMemoryTool {
mut:
	memory &memory_module.MemoryStore
}

pub fn WriteMemoryTool.new(memory &memory_module.MemoryStore) &WriteMemoryTool {
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
			if append {
				prev := t.memory.read_long_term() or { '' }
				new_content := if prev == '' { content } else { prev + '\n' + content }
				t.memory.write_long_term(new_content)!
				return 'Appended to long-term memory'
			}
			t.memory.write_long_term(content)!
			return 'Wrote long-term memory'
		}
		else {
			return error('invalid target: ${target}. Use "today" or "long"')
		}
	}
}
