module agent

import os
import json

pub struct SkillMetadata {
mut:
	name        string
	description string
}

@[heap]
pub struct SkillManager {
	workspace string
}

pub fn new_skill_manager(workspace string) &SkillManager {
	return &SkillManager{
		workspace: workspace
	}
}

pub fn (sm &SkillManager) list_skills() ![]SkillMetadata {
	skills_dir := os.join_path(sm.workspace, 'skills')
	if !os.exists(skills_dir) {
		return []
	}

	mut skills := []SkillMetadata{}
	entries := os.ls(skills_dir) or { return []SkillMetadata{} }
	for entry in entries {
		if !os.is_dir(os.join_path(skills_dir, entry)) {
			continue
		}
		skill_file := os.join_path(skills_dir, entry, 'SKILL.md')
		if os.exists(skill_file) {
			meta := sm.parse_skill_metadata(skill_file) or { continue }
			skills << meta
		}
	}
	return skills
}

pub fn (sm &SkillManager) get_skill(name string) !string {
	skill_file := os.join_path(sm.workspace, 'skills', name, 'SKILL.md')
	if !os.exists(skill_file) {
		return error('skill not found: ${name}')
	}
	return os.read_file(skill_file)!
}

pub fn (mut sm SkillManager) create_skill(name string, description string, content string) ! {
	if name == '' {
		return error('skill name is required')
	}

	skills_dir := os.join_path(sm.workspace, 'skills')
	os.mkdir_all(skills_dir) or { return err }

	skill_dir := os.join_path(skills_dir, name)
	os.mkdir_all(skill_dir) or { return err }

	// Create SKILL.md with frontmatter
	frontmatter := '---
name: ${name}
description: ${description}
---

'
	full_content := frontmatter + content

	skill_file := os.join_path(skill_dir, 'SKILL.md')
	os.write_file(skill_file, full_content) or { return err }
}

pub fn (mut sm SkillManager) delete_skill(name string) ! {
	skill_dir := os.join_path(sm.workspace, 'skills', name)
	os.rmdir_all(skill_dir) or { return err }
}

pub fn (sm &SkillManager) parse_skill_metadata(skill_file string) !SkillMetadata {
	content := os.read_file(skill_file)!
	lines := content.split('\n')

	if lines.len < 3 || lines[0] != '---' {
		return error('invalid frontmatter')
	}

	mut meta := SkillMetadata{}
	mut in_frontmatter := true

	for i := 1; i < lines.len; i++ {
		line := lines[i]
		if line == '---' {
			in_frontmatter = false
			break
		}
		if !in_frontmatter {
			break
		}
		parts := line.split_n(':', 2)
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		value := parts[1].trim_space()
		match key {
			'name' { meta.name = value }
			'description' { meta.description = value }
			else {}
		}
	}

	if meta.name == '' {
		return error('missing name in frontmatter')
	}
	return meta
}

// ============================================================================
// Tool Implementations
// ============================================================================

pub struct CreateSkillTool {
mut:
	manager &SkillManager
}

pub fn new_create_skill_tool(manager &SkillManager) &CreateSkillTool {
	return &CreateSkillTool{
		manager: manager
	}
}

pub fn (t &CreateSkillTool) name() string {
	return 'create_skill'
}

pub fn (t &CreateSkillTool) description() string {
	return 'Create a new skill in the skills directory with markdown content'
}

pub fn (t &CreateSkillTool) parameters() map[string]string {
	return {
		'type':       'object'
		'properties': '{
			"name": {
				"type":        "string",
				"description": "The skill name (alphanumeric, no special chars)"
			},
			"description": {
				"type":        "string",
				"description": "Brief description of what the skill does"
			},
			"content": {
				"type":        "string",
				"description": "The markdown content for the skill (instructions, examples, etc.)"
			}
		}'
		'required':   '["name", "description", "content"]'
	}
}

pub fn (mut t CreateSkillTool) execute(args map[string]string) !string {
	name := args['name'] or { panic('name is required') }
	description := args['description'] or { panic('description is required') }
	content := args['content'] or { panic('content is required') }

	t.manager.create_skill(name, description, content)!
	return 'Skill \'${name}\' created successfully'
}

pub struct ListSkillsTool {
mut:
	manager &SkillManager
}

pub fn new_list_skills_tool(manager &SkillManager) &ListSkillsTool {
	return &ListSkillsTool{
		manager: manager
	}
}

pub fn (t &ListSkillsTool) name() string {
	return 'list_skills'
}

pub fn (t &ListSkillsTool) description() string {
	return 'List all available skills with their names and descriptions'
}

pub fn (t &ListSkillsTool) parameters() map[string]string {
	return {
		'type':       'object'
		'properties': '{}'
	}
}

pub fn (t &ListSkillsTool) execute(args map[string]string) !string {
	skills := t.manager.list_skills()!
	if skills.len == 0 {
		return 'No skills found'
	}

	result := json.encode(skills)
	return result
}

pub struct ReadSkillTool {
mut:
	manager &SkillManager
}

pub fn new_read_skill_tool(manager &SkillManager) &ReadSkillTool {
	return &ReadSkillTool{
		manager: manager
	}
}

pub fn (t &ReadSkillTool) name() string {
	return 'read_skill'
}

pub fn (t &ReadSkillTool) description() string {
	return 'Read the full content of a skill by name'
}

pub fn (t &ReadSkillTool) parameters() map[string]string {
	return {
		'type':       'object'
		'properties': '{
			"name": {
				"type":        "string",
				"description": "The name of the skill to read"
			}
		}'
		'required':   '["name"]'
	}
}

pub fn (t &ReadSkillTool) execute(args map[string]string) !string {
	name := args['name'] or { return error('name is required') }
	return t.manager.get_skill(name)!
}

pub struct DeleteSkillTool {
mut:
	manager &SkillManager
}

pub fn new_delete_skill_tool(manager &SkillManager) &DeleteSkillTool {
	return &DeleteSkillTool{
		manager: manager
	}
}

pub fn (t &DeleteSkillTool) name() string {
	return 'delete_skill'
}

pub fn (t &DeleteSkillTool) description() string {
	return 'Delete a skill from the skills directory'
}

pub fn (t &DeleteSkillTool) parameters() map[string]string {
	return {
		'type':       'object'
		'properties': '{
			"name": {
				"type":        "string",
				"description": "The name of the skill to delete"
			}
		}'
		'required':   '["name"]'
	}
}

pub fn (mut t DeleteSkillTool) execute(args map[string]string) !string {
	name := args['name'] or { return error('name is required') }
	t.manager.delete_skill(name)!
	return 'Skill \'${name}\' deleted successfully'
}
