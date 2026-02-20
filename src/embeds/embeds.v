module embeds

pub struct EmbeddedFile {
pub:
	name string
	data string
}

pub fn get_skill(name string) ?EmbeddedFile {
	match name {
		'weather' {
			return EmbeddedFile{
				name: 'weather'
				data: $embed_file('skills/weather/SKILL.md').to_string()
			}
		}
		'example' {
			return EmbeddedFile{
				name: 'example'
				data: $embed_file('skills/example/SKILL.md').to_string()
			}
		}
		'cron' {
			return EmbeddedFile{
				name: 'cron'
				data: $embed_file('skills/cron/SKILL.md').to_string()
			}
		}
		else {
			return none
		}
	}
}

pub fn list_skills() []string {
	return ['weather', 'example', 'cron']
}
