module agent

import os
import session

fn test_session_manager_create_session() {
	temp_dir := os.temp_dir()
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	manager := session.new_session_manager(temp_dir)
	ses := manager.get_or_create('test-channel:test-chat')

	assert ses != 0
	assert ses.id == 'test-channel:test-chat'
}

fn test_session_manager_get_existing() {
	temp_dir := os.temp_dir()
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	manager := session.new_session_manager(temp_dir)

	// Create session first
	session1 := manager.get_or_create('test-channel:test-chat')
	session1.add_message('user', 'Hello')

	// Get same session
	session2 := manager.get_or_create('test-channel:test-chat')

	assert session1.id == session2.id
	assert session2.get_history().len == 1
}

fn test_session_add_messages() {
	temp_dir := os.temp_dir()
	defer { os.rmdir_all(temp_dir) or {} }

	manager := session.new_session_manager(temp_dir)
	mut session := manager.get_or_create('test')

	// Add messages
	session.add_message('user', 'Hello')
	session.add_message('assistant', 'Hi there!')
	session.add_message('user', 'How are you?')

	history := session.get_history()
	assert history.len == 3
	assert history[0].role == 'user'
	assert history[0].content == 'Hello'
	assert history[1].role == 'assistant'
	assert history[1].content == 'Hi there!'
	assert history[2].role == 'user'
	assert history[2].content == 'How are you?'
}

fn test_session_save_and_load() {
	temp_dir := os.temp_dir()
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	manager := session.new_session_manager(temp_dir)
	mut session := manager.get_or_create('test')

	// Add messages
	session.add_message('user', 'Test message')

	// Save session
	manager.save(session)!

	// Create new manager and load session
	manager2 := session.new_session_manager(temp_dir)
	loaded_session := manager2.get_or_create('test')

	history := loaded_session.get_history()
	assert history.len == 1
	assert history[0].content == 'Test message'
}

fn test_session_persistence() {
	temp_dir := os.temp_dir()
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	manager := session.new_session_manager(temp_dir)
	mut session := manager.get_or_create('persistent-test')

	// Add multiple messages
	session.add_message('user', 'First message')
	session.add_message('assistant', 'First response')
	session.add_message('user', 'Second message')

	// Save
	manager.save(session)!

	// Verify file exists
	session_file := os.join_path(temp_dir, 'sessions', 'persistent-test.json')
	assert os.exists(session_file)

	// Load and verify content
	content := os.read_file(session_file)!
	assert content.contains('First message')
	assert content.contains('First response')
	assert content.contains('Second message')
}
