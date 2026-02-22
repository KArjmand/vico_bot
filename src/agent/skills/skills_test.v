module skills

import os

fn test_load_all() {
	tmp_dir := os.temp_dir()
	workspace_dir := os.join_path(tmp_dir, 'vicobot_test_ws')
	skills_dir := os.join_path(workspace_dir, 'skills')
	os.mkdir_all(skills_dir) or { return }

	println('[skills_dir] ${skills_dir}')

	test_skills := [
		{
			'name':        'weather'
			'description': 'Get weather info'
			'content':     '# Weather\n\nUse curl wttr.in'
		},
		{
			'name':        'calculator'
			'description': 'Math calculations'
			'content':     '# Calculator\n\nUse bc command'
		},
	]

	for ts in test_skills {
		skill_dir := os.join_path(skills_dir, ts['name']!)
		os.mkdir_all(skill_dir) or { return }
		skill_file := os.join_path(skill_dir, 'SKILL.md')

		content := '---\nname: ${ts['name']!}\ndescription: ${ts['description']!}\n---\n\n${ts['content']!}'
		os.write_file(skill_file, content) or { return }
	}

	loader := new_skills_loader(workspace_dir)
	skills := loader.load_all() or {
		println('LoadAll failed: ${err}')
		return
	}

	assert skills.len == 2

	for skill in skills {
		assert skill.name != ''
		assert skill.description != ''
		assert skill.content != ''
	}

	os.rmdir_all(skills_dir) or {}
}

fn test_load_by_name() {
	tmp_dir := os.temp_dir()
	workspace_dir := os.join_path(tmp_dir, 'vicobot_test_ws2')
	skill_dir := os.join_path(workspace_dir, 'skills', 'test-skill')
	os.mkdir_all(skill_dir) or { return }

	skill_file := os.join_path(skill_dir, 'SKILL.md')
	content := '---\nname: test-skill\ndescription: Test skill\n---\n\n# Test\n\nTest content'
	os.write_file(skill_file, content) or { return }

	loader := new_skills_loader(workspace_dir)
	skill := loader.load_by_name('test-skill') or {
		println('LoadByName failed: ${err}')
		return
	}

	assert skill.name == 'test-skill'
	assert skill.description == 'Test skill'
	assert skill.content.contains('Test content')

	os.rmdir_all(workspace_dir) or {}
}

fn test_skills_loader_empty() {
	loader := new_skills_loader('/nonexistent/path')
	skills := loader.load_all() or { []Skill{} }

	assert skills.len == 0
}

fn test_skills_loader_load_by_name_not_found() {
	loader := new_skills_loader('.')
	_ := loader.load_by_name('nonexistent') or { return }
}
