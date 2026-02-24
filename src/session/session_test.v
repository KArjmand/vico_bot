module session

import os

fn test_session_manager_create_session() {
	temp_dir := os.join_path(os.temp_dir(), 'vicobot_test_session_1')
	os.mkdir_all(temp_dir, os.MkdirParams{}) or { return }
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	mut manager := SessionManager.new(temp_dir)
	ses := manager.get_or_create('test-channel:test-chat')

	assert ses.key == 'test-channel:test-chat'
	assert ses.history.len == 0
}

fn test_session_manager_get_existing() {
	temp_dir := os.join_path(os.temp_dir(), 'vicobot_test_session_2')
	os.mkdir_all(temp_dir, os.MkdirParams{}) or { return }
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	mut manager := SessionManager.new(temp_dir)

	// Create session first
	mut session1 := manager.get_or_create('test-channel:test-chat')
	session1.add_message('user', 'Hello')

	// Get same session
	session2 := manager.get_or_create('test-channel:test-chat')

	assert session1.key == session2.key
	assert session2.get_history().len == 1
}

fn test_session_add_messages() {
	temp_dir := os.join_path(os.temp_dir(), 'vicobot_test_session_3')
	os.mkdir_all(temp_dir, os.MkdirParams{}) or { return }
	defer { os.rmdir_all(temp_dir) or {} }

	mut manager := SessionManager.new(temp_dir)
	mut session := manager.get_or_create('test')

	// Add messages
	session.add_message('user', 'Hello')
	session.add_message('assistant', 'Hi there!')
	session.add_message('user', 'How are you?')

	history := session.get_history()
	assert history.len == 3
	assert history[0] == 'user: Hello'
	assert history[1] == 'assistant: Hi there!'
	assert history[2] == 'user: How are you?'
}

fn test_session_save_and_load() {
	temp_dir := os.join_path(os.temp_dir(), 'vicobot_test_session_4')
	os.mkdir_all(temp_dir, os.MkdirParams{}) or { return }
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	mut manager := SessionManager.new(temp_dir)
	mut session := manager.get_or_create('test')

	// Add messages
	session.add_message('user', 'Test message')

	// Save session
	manager.save(mut session)!

	// Create new manager and load session
	mut manager2 := new_session_manager(temp_dir)
	manager2.load_all()!
	loaded_session := manager2.get_or_create('test')

	history := loaded_session.get_history()
	assert history.len == 1
	assert history[0] == 'user: Test message'
}

fn test_session_persistence() {
	temp_dir := os.join_path(os.temp_dir(), 'vicobot_test_session_5')
	os.mkdir_all(temp_dir, os.MkdirParams{}) or { return }
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	mut manager := SessionManager.new(temp_dir)
	mut session := manager.get_or_create('persistent-test')

	// Add multiple messages
	session.add_message('user', 'First message')
	session.add_message('assistant', 'First response')
	session.add_message('user', 'Second message')

	// Save
	manager.save(mut session)!

	// Verify file exists
	session_file := os.join_path(temp_dir, 'sessions', 'persistent-test.json')
	assert os.exists(session_file)

	// Load and verify content
	content := os.read_file(session_file)!
	assert content.contains('First message')
	assert content.contains('First response')
	assert content.contains('Second message')
}

fn test_session_trim() {
	temp_dir := os.join_path(os.temp_dir(), 'vicobot_test_session_6')
	os.mkdir_all(temp_dir, os.MkdirParams{}) or { return }
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	mut manager := SessionManager.new(temp_dir)
	mut session := manager.get_or_create('test')

	// Add more messages than max_history_size (50)
	for i in 0 .. 60 {
		session.add_message('user', 'Message ${i}')
	}

	// Trim should keep only last 50 (called manually, not just on save)
	session.trim()
	assert session.history.len == 50
	assert session.history[0] == 'user: Message 10' // First 10 should be trimmed
}
