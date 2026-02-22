module tools

import os
import net.http

pub struct WebTool {
mut:
	last_url string
}

pub fn new_web_tool() &WebTool {
	return &WebTool{}
}

pub fn (t &WebTool) name() string {
	return 'web'
}

pub fn (t &WebTool) description() string {
	return 'Fetch web pages and return their content'
}

pub fn (t &WebTool) parameters() map[string]string {
	return {
		'url': 'The URL to fetch'
	}
}

pub fn (mut t WebTool) execute(args map[string]string) !string {
	url := args['url'] or { return error('url is required') }
	t.last_url = url

	resp := http.get(url) or { return error('failed to fetch ${url}: ${err}') }
	return resp.body
}
