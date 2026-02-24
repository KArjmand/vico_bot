module tools

import os

@[noinit]
pub struct FilesystemTool {
mut:
	workspace string
}

pub fn FilesystemTool.new(workspace string) &FilesystemTool {
	return &FilesystemTool{
		workspace: workspace
	}
}

pub fn (t &FilesystemTool) name() string {
	return 'filesystem'
}

pub fn (t &FilesystemTool) description() string {
	return 'Read, write, and list files in the workspace'
}

pub fn (t &FilesystemTool) parameters() map[string]string {
	return {
		'operation': 'The operation: read, write, list, delete, mkdir'
		'path':      'File or directory path'
		'content':   'Content to write (for write operation)'
	}
}

pub fn (t &FilesystemTool) execute(args map[string]string) !string {
	op := args['operation'] or { 'read' }
	path := args['path'] or { return error('path is required') }

	full_path := os.join_path(t.workspace, path)
	match op {
		'read' {
			if !os.exists(full_path) {
				return error('file not found')
			}
			return os.read_file(full_path)!
		}
		'write' {
			content := args['content'] or { return error('content is required for write') }
			os.write_file(full_path, content)!
			return 'File written successfully'
		}
		'list' {
			if !os.exists(full_path) {
				return error('directory not found')
			}
			entries := os.ls(full_path)!
			return entries.join('\n')
		}
		'delete' {
			os.rm(full_path)!
			return 'File deleted successfully'
		}
		'mkdir' {
			os.mkdir_all(full_path, mode: 0o755)!
			return 'Directory created successfully'
		}
		else {
			return error('unknown operation: ${op}')
		}
	}
}
