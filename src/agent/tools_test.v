module agent

struct TestTool {
mut:
	name_val string
}

fn (t &TestTool) name() string {
	return t.name_val
}

fn (t &TestTool) description() string {
	return 'test tool'
}

fn (t &TestTool) parameters() map[string]string {
	return {}
}

fn (t &TestTool) execute(args map[string]string) !string {
	return 'executed'
}

fn test_registry_register_and_get() {
	mut reg := new_registry()
	t := &TestTool{
		name_val: 'test'
	}
	reg.register(t)

	got := reg.get('test') or {
		assert false, 'expected to find the tool: ${err}'
		return
	}
	assert got.name() == 'test' // asserting the tool's name
}

fn test_registry_definitions() {
	mut reg := new_registry()
	reg.register(&TestTool{ name_val: 'tool1' })
	reg.register(&TestTool{ name_val: 'tool2' })

	defs := reg.definitions()
	assert defs.len == 2
}

fn test_registry_execute() {
	mut reg := new_registry()
	reg.register(&TestTool{ name_val: 'mytool' })

	res := reg.execute('mytool', {})!
	assert res == 'executed'
}

fn test_registry_execute_not_found() {
	mut reg := new_registry()
	res := reg.execute('nonexistent', {}) or {
		assert err.msg().contains('tool not found')
		return
	}
	assert false // Should not reach here
}
