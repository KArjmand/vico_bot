module skills

import os

pub struct Skill {
pub mut:
	name        string
	description string
	content     string
}

@[noinit]
pub struct SkillsLoader {
	workspace_path string
}

pub fn SkillsLoader.new(workspace_path string) &SkillsLoader {
	return &SkillsLoader{
		workspace_path: workspace_path
	}
}

pub fn (l &SkillsLoader) load_all() ![]Skill {
	skills_path := os.join_path(l.workspace_path, 'skills')
	if !os.exists(skills_path) {
		return []
	}
	entries := os.ls(skills_path)!
	mut skills := []Skill{}
	for entry in entries {
		entry_path := os.join_path(skills_path, entry)
		if !os.is_dir(entry_path) {
			continue
		}
		skill_path := os.join_path(entry_path, 'SKILL.md')
		if os.exists(skill_path) {
			skill := l.load_skill(skill_path) or { continue }
			skills << skill
		}
	}
	return skills
}

pub fn (l &SkillsLoader) load_by_name(name string) !Skill {
	skill_path := os.join_path(l.workspace_path, 'skills', name, 'SKILL.md')
	return l.load_skill(skill_path)
}

pub fn (l &SkillsLoader) load_skill(skill_path string) !Skill {
	content := os.read_file(skill_path)!
	lines := content.split('\n')
	if lines.len < 3 || lines[0] != '---' {
		return error('invalid SKILL.md format: missing frontmatter')
	}
	mut skill := Skill{}
	mut in_frontmatter := true
	mut content_start_idx := 0
	for i := 1; i < lines.len; i++ {
		line := lines[i]
		if line == '---' {
			in_frontmatter = false
			content_start_idx = i + 1
			break
		}
		if !in_frontmatter {
			break
		}
		parts := line.split_n(': ', 2)
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		value := parts[1].trim_space()
		match key {
			'name' {
				skill.name = value
			}
			'description' {
				skill.description = value
			}
			else {}
		}
	}
	if skill.name == '' {
		return error('missing name in frontmatter')
	}
	if content_start_idx < lines.len {
		skill.content = lines#[content_start_idx..].join('\n').trim_space()
	}
	return skill
}
