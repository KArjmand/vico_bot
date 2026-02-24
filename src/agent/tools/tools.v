module tools

import providers
import x.json2

@[heap]
pub interface Tool {
	name() string
	description() string
	parameters() map[string]string
mut:
	execute(args map[string]string) !string
}

@[heap; noinit]
pub struct Registry {
mut:
	mu    int
	tools map[string]&Tool
}

pub fn Registry.new() &Registry {
	return &Registry{
		// Match the expected map[string]&Tool type
		tools: map[string]&Tool{}
	}
}

pub fn (mut r Registry) register(t &Tool) {
	unsafe {
		r.tools[t.name()] = t
	}
}

pub fn (r &Registry) get(name string) ?&Tool {
	return r.tools[name] or { none }
}

pub fn (r &Registry) definitions() []providers.ToolDefinition {
	mut defs := []providers.ToolDefinition{}
	for _, t in r.tools {
		mut params := map[string]json2.Any{}
		for k, v in t.parameters() {
			params[k] = v
		}
		defs << providers.ToolDefinition{
			name:        t.name()
			description: t.description()
			parameters:  params
		}
	}
	return defs
}

pub fn (mut r Registry) execute(name string, args map[string]string) !string {
	if name == '' {
		return error('tool name is required')
	}
	mut t := r.tools[name] or { return error('tool not found') }
	return t.execute(args)
}
