module tools

import os

fn test_create_skill_tool_basic() {
	// Create a temporary workspace for testing
	temp_dir := os.temp_dir()
	os.rmdir_all(temp_dir) or {}

	mut manager := SkillManager.new(temp_dir)
	mut tool := CreateSkillTool.new(manager)

	args := {
		'name':        'test-skill'
		'description': 'Test skill description'
		'content':     '# Test Skill\n\nThis is a test skill.'
	}

	result := tool.execute(args)!
	assert result.contains('created successfully')
	assert result.contains('test-skill')

	// Verify file was created
	skill_file := os.join_path(temp_dir, 'skills', 'test-skill', 'SKILL.md')
	assert os.exists(skill_file)

	content := os.read_file(skill_file)!
	assert content.contains('name: test-skill')
	assert content.contains('description: Test skill description')
	assert content.contains('# Test Skill')
}

fn test_create_skill_tool_missing_name() {
	mut manager := SkillManager.new('.')
	mut tool := CreateSkillTool.new(manager)

	args := {
		'name':        ''
		'description': 'Test description'
		'content':     'Test content'
	}

	result := tool.execute(args) or { 'error' }
	assert result.contains('error')
}

fn test_list_skills_tool_empty() {
	temp_dir := os.temp_dir()
	defer { os.rmdir_all(temp_dir) or {} }

	mut manager := SkillManager.new(temp_dir)
	mut tool := ListSkillsTool.new(manager)

	args := map[string]string{}
	result := tool.execute(args)!
	println('list_skills result: ${result}')
	assert result.len > 0
}

fn test_list_skills_tool_with_skills() {
	temp_dir := os.temp_dir()
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	mut manager := new_skill_manager(temp_dir)

	// Create test skills first
	manager.create_skill('skill1', 'First skill', 'Content 1')!
	manager.create_skill('skill2', 'Second skill', 'Content 2')!

	mut tool := new_list_skills_tool(manager)
	args := map[string]string{}
	result := tool.execute(args)!
	assert result.contains('skill1')
	assert result.contains('skill2')
	assert result.contains('First skill')
	assert result.contains('Second skill')
}

fn test_read_skill_tool_existing() {
	temp_dir := os.temp_dir()
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	mut manager := SkillManager.new(temp_dir)
	manager.create_skill('read-test', 'Test skill', '# Read Test\n\nContent here')!

	mut tool := ReadSkillTool.new(manager)
	args := {
		'name': 'read-test'
	}
	result := tool.execute(args)!
	assert result.contains('# Read Test')
	assert result.contains('Content here')
}

fn test_read_skill_tool_nonexistent() {
	mut manager := SkillManager.new('.')
	mut tool := ReadSkillTool.new(manager)

	args := {
		'name': 'nonexistent-skill'
	}
	result := tool.execute(args) or { 'error' }
	assert result.contains('error')
}

fn test_delete_skill_tool_existing() {
	temp_dir := os.temp_dir()
	defer {
		os.rmdir_all(temp_dir) or {}
	}

	mut manager := SkillManager.new(temp_dir)
	manager.create_skill('delete-test', 'To be deleted', 'Will be removed')!

	mut tool := DeleteSkillTool.new(manager)
	args := {
		'name': 'delete-test'
	}
	result := tool.execute(args)!
	assert result.contains('deleted successfully')
	assert result.contains('delete-test')

	// Verify directory was removed
	skill_dir := os.join_path(temp_dir, 'skills', 'delete-test')
	assert !os.exists(skill_dir)
}

fn test_delete_skill_tool_nonexistent() {
	mut manager := SkillManager.new('.')
	mut tool := DeleteSkillTool.new(manager)

	args := {
		'name': 'nonexistent-skill'
	}
	result := tool.execute(args) or { 'error' }
	assert result.contains('error')
}
