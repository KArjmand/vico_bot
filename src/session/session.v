module session

import os
import json

const max_history_size = 50

pub struct Session {
pub:
	key string
mut:
	history []string
}

@[noinit]
pub struct SessionManager {
mut:
	sessions  map[string]&Session
	workspace string
}

pub fn SessionManager.new(workspace string) SessionManager {
	return SessionManager{
		sessions:  map[string]&Session{}
		workspace: workspace
	}
}

pub fn (mut sm SessionManager) get_or_create(key string) &Session {
	if s := sm.sessions[key] {
		return s
	}
	// fallback: session not found, create new one below
	s := &Session{
		key:     key
		history: []string{}
	}
	sm.sessions[key] = s
	return s
}

pub fn (mut sm SessionManager) save(mut s Session) ! {
	s.trim()

	path := os.join_path(sm.workspace, 'sessions')
	os.mkdir_all(path, os.MkdirParams{})!

	fpath := os.join_path(path, '${s.key}.json')
	b := json.encode(s)
	os.write_file(fpath, b)!
}

pub fn (mut sm SessionManager) load_all() ! {
	path := os.join_path(sm.workspace, 'sessions')
	os.mkdir_all(path, os.MkdirParams{})!

	entries := os.ls(path)!

	for entry in entries {
		full_path := os.join_path(path, entry)
		if os.is_dir(full_path) {
			continue
		}
		b := os.read_file(full_path) or { continue }
		s := json.decode(Session, b) or { continue }
		sm.sessions[s.key] = &s
	}
}

pub fn (mut s Session) add_message(role string, content string) {
	s.history << '${role}: ${content}'
}

pub fn (s &Session) get_history() []string {
	return s.history
}

pub fn (mut s Session) trim() {
	if s.history.len > max_history_size {
		s.history = s.history[s.history.len - max_history_size..]
	}
}
