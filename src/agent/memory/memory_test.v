module memory

import os

fn test_memory_add_and_recent() {
	mut s := MemoryStore.new(3)
	s.add_long('L1')
	s.add_short('two')
	s.add_short('one')

	res := s.recent(10)
	assert res.len == 3, 'expected 3 items, got ${res.len}'
	assert res[0].text == 'one', 'expected first to be one'
	assert res[1].text == 'two', 'expected second to be two'
	assert res[2].text == 'L1', 'expected third to be L1'
}

fn test_short_limit() {
	mut s := MemoryStore.new(2)
	s.add_short('c')
	s.add_short('b')
	s.add_short('a')

	res := s.recent(10)
	assert res.len == 2, 'expected 2 items due to limit, got ${res.len}'
	assert res[0].text == 'a', 'expected first to be a'
	assert res[1].text == 'b', 'expected second to be b'
}

fn test_query_by_keyword() {
	mut s := MemoryStore.new(10)
	s.add_long('apple pie recipe')
	s.add_short('Remember the apple')

	res := s.query_by_keyword('apple', 10)
	assert res.len == 2, 'expected 2 results, got ${res.len}'
	assert res[0].text == 'Remember the apple', 'expected short first'
	assert res[1].text == 'apple pie recipe', 'expected long second'
}

fn test_memory_persistence_read_write_long_and_today() {
	tmp_dir := os.temp_dir()
	workspace_dir := os.join_path(tmp_dir, 'vicobot_test_mem')
	os.mkdir_all(workspace_dir) or { return }
	defer {
		os.rmdir_all(workspace_dir) or {}
	}

	mut s := MemoryStore.new_with_workspace(workspace_dir, 10)

	s.write_long_term('Long-term fact\n') or { return }
	lt := s.read_long_term() or { return }
	assert lt == 'Long-term fact\n', 'expected long-term content'

	s.append_today('note 1') or { return }

	files := os.ls(os.join_path(workspace_dir, 'memory')) or { []string{} }
	assert files.len > 0, 'expected memory file created'

	td := s.read_today() or { return }
	assert td != '', 'expected today content, got empty'

	rec := s.get_recent_memories(1) or { return }
	assert rec != '', 'expected recent memory content, got empty'

	mc := s.get_memory_context() or { return }
	assert mc != '', 'expected memory context, got empty'
}
