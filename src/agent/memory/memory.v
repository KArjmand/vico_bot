module memory

import os
import time

pub struct MemoryItem {
pub:
	kind      string
	text      string
	timestamp time.Time
}

pub interface Ranker {
	rank(query string, memories []MemoryItem, top_k int) []MemoryItem
}

@[noinit]
pub struct MemoryStore {
mut:
	workspace  string
	memory_dir string
	limit      int
	long       []MemoryItem
	short      []MemoryItem
}

pub fn MemoryStore.new(limit int) &MemoryStore {
	return MemoryStore.new_with_workspace('.', limit)
}

pub fn MemoryStore.new_with_workspace(workspace string, limit int) &MemoryStore {
	mut adjusted_limit := limit
	if adjusted_limit <= 0 {
		adjusted_limit = 100
	}
	return &MemoryStore{
		workspace:  workspace
		memory_dir: os.join_path(workspace, 'memory')
		short:      []MemoryItem{len: 0, cap: adjusted_limit}
		long:       []MemoryItem{len: 0}
		limit:      adjusted_limit
	}
}

pub fn (mut s MemoryStore) add_short(text string) {
	it := MemoryItem{
		timestamp: time.now()
		text:      text
		kind:      'short'
	}
	s.short << it
	if s.short.len > s.limit {
		s.short = s.short#[-s.limit..]
	}
}

pub fn (mut s MemoryStore) add_long(text string) {
	it := MemoryItem{
		timestamp: time.now()
		text:      text
		kind:      'long'
	}
	s.long << it
}

pub fn (s &MemoryStore) recent(n int) []MemoryItem {
	if n <= 0 {
		return []
	}
	mut out := []MemoryItem{len: 0, cap: n}
	for i := s.short.len - 1; i >= 0 && out.len < n; i-- {
		out << s.short[i]
	}
	for i := s.long.len - 1; i >= 0 && out.len < n; i-- {
		out << s.long[i]
	}
	return out
}

pub fn (s &MemoryStore) query_by_keyword(keyword string, n int) []MemoryItem {
	if n <= 0 || keyword == '' {
		return []
	}
	k := keyword.to_lower()
	mut out := []MemoryItem{len: 0, cap: n}
	for i := s.short.len - 1; i >= 0 && out.len < n; i-- {
		if s.short[i].text.to_lower().contains(k) {
			out << s.short[i]
		}
	}
	for i := s.long.len - 1; i >= 0 && out.len < n; i-- {
		if s.long[i].text.to_lower().contains(k) {
			out << s.long[i]
		}
	}
	return out
}

pub fn (s &MemoryStore) read_long_term() !string {
	path := os.join_path(s.memory_dir, 'MEMORY.md')
	if !os.exists(path) {
		return ''
	}
	return os.read_file(path)
}

pub fn (mut s MemoryStore) write_long_term(content string) ! {
	os.mkdir_all(s.memory_dir, mode: 0o755)!
	os.write_file(os.join_path(s.memory_dir, 'MEMORY.md'), content)!
}

pub fn (s &MemoryStore) read_today() !string {
	name :=
		'${time.now().as_utc().year}-${time.now().as_utc().month:02}-${time.now().as_utc().day:02}' +
		'.md'
	path := os.join_path(s.memory_dir, name)
	if !os.exists(path) {
		return ''
	}
	return os.read_file(path)
}

pub fn (mut s MemoryStore) append_today(text string) ! {
	os.mkdir_all(s.memory_dir, mode: 0o755)!
	name :=
		'${time.now().as_utc().year}-${time.now().as_utc().month:02}-${time.now().as_utc().day:02}' +
		'.md'
	path := os.join_path(s.memory_dir, name)
	mut f := os.open_append(path) or { panic(err) }
	f.writeln('[${time.now().as_utc().str()}] ${text}')!
	f.close()
}

pub fn (s &MemoryStore) get_recent_memories(days int) !string {
	mut d := days
	if d <= 0 {
		d = 1
	}
	mut parts := []string{len: 0, cap: d}
	for i := 0; i < d; i++ {
		mut td := time.now().as_utc().add(-i * 24 * time.hour)
		name := '${td.year}-${td.month:02}-${td.day:02}' + '.md'
		path := os.join_path(s.memory_dir, name)
		if os.exists(path) {
			parts << os.read_file(path)!
		}
	}
	return parts.join('\n---\n')
}

pub fn (s &MemoryStore) get_memory_context() !string {
	lt := s.read_long_term()!
	td := s.read_today()!
	if lt == '' && td == '' {
		return ''
	}
	if lt == '' {
		return td
	}
	if td == '' {
		return lt
	}
	return lt + '\n\n---\n\n' + td
}
