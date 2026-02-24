import os
import cli
import time
import config
import chat
import providers
import agent
import context
import heartbeat
import channels

const version = '0.0.1'

fn main() {
	mut app := cli.Command{
		name:        'vicobot'
		description: 'vicobot — lightweight clawbot in V'
		execute:     fn (cmd cli.Command) ! {
			println('vicobot — lightweight clawbot in V')
			println('Usage: vicobot [command] [options]')
			println('Commands: version, onboard, agent, gateway, telegram, memory')
		}
		commands:    [
			cli.Command{
				name:        'version'
				description: 'Print version'
				execute:     fn (cmd cli.Command) ! {
					println('🤖 vicobot v${version}')
				}
			},
			cli.Command{
				name:        'onboard'
				description: 'Create default config and workspace'
				execute:     run_onboard
			},
			cli.Command{
				name:        'agent'
				description: 'Run a single-shot agent query (use -m)'
				flags:       [
					cli.Flag{
						flag:        .string
						name:        'message'
						abbrev:      'm'
						description: 'Message to send to the agent'
					},
					cli.Flag{
						flag:        .string
						name:        'model'
						abbrev:      'M'
						description: 'Model to use (overrides config/provider default)'
					},
				]
				execute:     run_agent
			},
			cli.Command{
				name:        'gateway'
				description: 'Start long-running gateway'
				flags:       [
					cli.Flag{
						flag:        .string
						name:        'model'
						abbrev:      'M'
						description: 'Model to use'
					},
				]
				execute:     run_gateway
			},
			cli.Command{
				name:        'telegram'
				description: 'Start Telegram bot interface'
				execute:     run_telegram
			},
			cli.Command{
				name:        'memory'
				description: 'Inspect or modify workspace memory files'
				commands:    [
					cli.Command{
						name:        'read'
						usage:       '[today|long]'
						description: 'Read memory'
						execute:     run_memory_read
					},
					cli.Command{
						name:        'append'
						usage:       '[today|long] [content...]'
						description: 'Append content to memory'
						execute:     run_memory_append
					},
					cli.Command{
						name:        'write'
						usage:       'long [content...]'
						description: 'Overwrite long-term memory'
						execute:     run_memory_write
					},
					cli.Command{
						name:        'recent'
						description: 'Show recent memories'
						flags:       [
							cli.Flag{
								flag:        .int
								name:        'days'
								abbrev:      'd'
								description: 'Number of days to look back'
							},
						]
						execute:     run_memory_recent
					},
					cli.Command{
						name:        'rank'
						description: 'Search memories by relevance'
						flags:       [
							cli.Flag{
								flag:        .string
								name:        'query'
								abbrev:      'q'
								description: 'Query to search for'
								required:    true
							},
						]
						execute:     run_memory_rank
					},
				]
			},
		]
	}

	app.setup()
	app.parse(os.args)
}

fn run_onboard(cmd cli.Command) ! {
	cfg_path, ws_path := config.onboard() or { return error('onboard failed: ${err}') }
	println('Wrote config to ${cfg_path}\nInitialized workspace at ${ws_path}')
}

fn run_agent(cmd cli.Command) ! {
	msg := cmd.flags.get_string('message') or { '' }
	model_flag := cmd.flags.get_string('model') or { '' }

	if msg == '' {
		println('Specify a message with -m "your message"')
		return
	}

	hub := chat.Hub.new(100)
	cfg := config.load_config() or { config.VicobotConfig{} }

	mut provider := providers.LLMProvider(providers.StubProvider.new())
	if openai := cfg.providers.openai {
		api_key := openai.api_key
		api_base := openai.api_base
		max_tokens := openai.max_tokens
		if api_key != '' {
			provider = providers.OpenAIProvider.new(api_key, api_base, max_tokens)
		}
	}

	mut model := model_flag
	if model == '' && cfg.agents.defaults.model != '' {
		model = cfg.agents.defaults.model
	}
	if model == '' {
		model = provider.get_default_model()
	}

	mut max_iter := cfg.agents.defaults.max_tool_iterations
	if max_iter <= 0 {
		max_iter = 100
	}

	mut ag := agent.AgentLoop.new(hub, provider, model, max_iter, cfg.agents.defaults.workspace,
		none)
	resp := ag.process_direct(msg, 60 * time.second) or { return error('error: ${err}') }
	println(resp)
}

fn run_gateway(cmd cli.Command) ! {
	hub := chat.Hub.new(200)
	cfg := config.load_config() or { return error('Failed to load config') }
	provider := providers.LLMProvider.from_config(cfg)

	mut model := cfg.agents.defaults.model
	if model == '' {
		model = provider.get_default_model()
	}

	mut ag := agent.AgentLoop.new(&hub, provider, model, 100, cfg.agents.defaults.workspace,
		none)

	mut background := context.background()
	mut ctx, cancel_fn := context.with_cancel(mut background)
	mut mut_ctx := ctx
	mut ctx_ptr := &mut_ctx
	spawn ag.run(mut ctx_ptr)

	// Start heartbeat if configured
	mut hb_interval := cfg.agents.defaults.heartbeat_interval_s
	if hb_interval > 0 {
		spawn heartbeat.start_heartbeat(mut ctx_ptr, cfg.agents.defaults.workspace, hb_interval * time.second,
			&hub)
	}

	// Start Telegram if configured and enabled
	if cfg.channels.telegram.enabled && cfg.channels.telegram.token != '' {
		tg_token := cfg.channels.telegram.token
		tg_allow := cfg.channels.telegram.allow_from
		channels.start_telegram(tg_token, &hub, tg_allow) or {
			eprintln('Failed to start telegram: ${err}')
		}
	}

	println('Gateway running. Press Ctrl+C to shut down')
	// V handles signals via the os module
	os.signal_opt(.int, fn [cancel_fn] (sig os.Signal) {
		println('\nShutting down gateway...')
		cancel_fn()
		exit(0)
	}) or { panic(err) }

	for {
		time.sleep(1 * time.second)
	}
}

fn run_memory_read(cmd cli.Command) ! {
	if cmd.args.len < 1 {
		return error('Usage: memory read [today|long]')
	}
	target := cmd.args[0]
	ws := get_workspace()!
	mem_dir := os.join_path(ws, 'memory')

	match target {
		'today' {
			name := '${time.now().year}-${time.now().month:02}-${time.now().day:02}.md'
			path := os.join_path(mem_dir, name)
			if !os.exists(path) {
				println('No memory for today.')
				return
			}
			content := os.read_file(path)!
			println("=== Today's Memory ===")
			println(content)
		}
		'long' {
			path := os.join_path(mem_dir, 'MEMORY.md')
			if !os.exists(path) {
				println('No long-term memory.')
				return
			}
			content := os.read_file(path)!
			println('=== Long-term Memory ===')
			println(content)
		}
		else {
			return error('Invalid target: ${target}. Use [today|long]')
		}
	}
}

fn run_memory_append(cmd cli.Command) ! {
	if cmd.args.len < 2 {
		return error('Usage: memory append [today|long] "content"')
	}
	target := cmd.args[0]
	content := cmd.args[1..].join(' ')

	if target != 'today' && target != 'long' {
		return error('Usage: memory append [today|long] "content"')
	}

	ws := get_workspace()!
	mem_dir := os.join_path(ws, 'memory')
	os.mkdir_all(mem_dir, mode: 0o755)!

	if target == 'today' {
		name := '${time.now().year}-${time.now().month:02}-${time.now().day:02}.md'
		path := os.join_path(mem_dir, name)
		mut f := os.open_append(path) or {
			os.write_file(path, content)!
			println("Appended to today's memory.")
			return
		}
		f.writeln(content)!
		f.close()
		println("Appended to today's memory.")
	} else {
		path := os.join_path(mem_dir, 'MEMORY.md')
		existing := if os.exists(path) { os.read_file(path)! } else { '' }
		new_content := if existing.len > 0 { '${existing}\n${content}' } else { content }
		os.write_file(path, new_content)!
		println('Appended to long-term memory.')
	}
}

fn run_memory_write(cmd cli.Command) ! {
	if cmd.args.len < 1 {
		return error('Usage: memory write long "content"')
	}
	content := cmd.args[1..].join(' ')

	ws := get_workspace()!
	mem_dir := os.join_path(ws, 'memory')
	os.mkdir_all(mem_dir, mode: 0o755)!
	path := os.join_path(mem_dir, 'MEMORY.md')
	os.write_file(path, content)!
	println('Long-term memory updated.')
}

fn run_memory_recent(cmd cli.Command) ! {
	days := cmd.flags.get_int('days') or { 7 }
	if days <= 0 {
		return error('Days must be positive')
	}

	ws := get_workspace()!
	mem_dir := os.join_path(ws, 'memory')

	if !os.exists(mem_dir) {
		println('No memory files found.')
		return
	}

	println('=== Recent ${days} days ===')
	for i := 0; i < days; i++ {
		td := time.now().add(-i * 24 * time.hour)
		name := '${td.year}-${td.month:02}-${td.day:02}.md'
		path := os.join_path(mem_dir, name)
		if os.exists(path) {
			content := os.read_file(path)!
			if content.len > 0 {
				println('\n--- ${name} ---')
				println(content)
			}
		}
	}
}

fn run_memory_rank(cmd cli.Command) ! {
	query := cmd.flags.get_string('query') or { return error('-q required') }

	ws := get_workspace()!
	mem_dir := os.join_path(ws, 'memory')

	if !os.exists(mem_dir) {
		println('No memory files found.')
		return
	}

	// Simple keyword search (can be upgraded to LLM-based ranking)
	mut results := []string{}
	query_lower := query.to_lower()

	// Search today's memory
	td := time.now()
	name := '${td.year}-${td.month:02}-${td.day:02}.md'
	path := os.join_path(mem_dir, name)
	if os.exists(path) {
		content := os.read_file(path)!
		if content.to_lower().contains(query_lower) {
			results << '=== Today (${name}) ===\n${content}'
		}
	}

	// Search long-term memory
	long_path := os.join_path(mem_dir, 'MEMORY.md')
	if os.exists(long_path) {
		content := os.read_file(long_path)!
		if content.to_lower().contains(query_lower) {
			results << '=== Long-term Memory ===\n${content}'
		}
	}

	if results.len == 0 {
		println('No memories found matching "${query}"')
	} else {
		println('=== Results for "${query}" ===')
		for r in results {
			println(r)
			println('---')
		}
	}
}

fn run_telegram(cmd cli.Command) ! {
	cfg := config.load_config() or { config.VicobotConfig{} }

	if !cfg.channels.telegram.enabled || cfg.channels.telegram.token == '' {
		return error('Telegram not configured. Run "vicobot onboard" first.')
	}

	hub := chat.Hub.new(100)

	// Example of V's concise provider logic
	mut provider := providers.LLMProvider(providers.StubProvider.new())
	if openai := cfg.providers.openai {
		api_key := openai.api_key
		api_base := openai.api_base
		max_tokens := openai.max_tokens

		if api_key != '' {
			provider = providers.OpenAIProvider.new(api_key, api_base, max_tokens)
		}
	}

	mut model := cfg.agents.defaults.model
	if model == '' {
		model = provider.get_default_model()
	}

	mut ag := agent.AgentLoop.new(&hub, provider, model, 100, cfg.agents.defaults.workspace,
		none)

	mut background := context.background()
	mut ctx, cancel_fn := context.with_cancel(mut background)
	mut mut_ctx := ctx
	mut ctx_ptr := &mut_ctx
	spawn ag.run(mut ctx_ptr)

	// Start Telegram bot
	tg_token := cfg.channels.telegram.token
	tg_allow := cfg.channels.telegram.allow_from
	channels.start_telegram(tg_token, &hub, tg_allow) or {
		eprintln('Failed to start telegram: ${err}')
		return
	}

	println('Telegram bot running. Press Ctrl+C to shut down')
	// V handles signals via os module
	os.signal_opt(.int, fn [cancel_fn] (sig os.Signal) {
		println('\nShutting down telegram bot...')
		cancel_fn()
		exit(0)
	}) or { panic(err) }

	for {
		time.sleep(1 * time.second)
	}
}

fn get_workspace() !string {
	cfg := config.load_config() or { config.VicobotConfig{} }
	mut ws := cfg.agents.defaults.workspace
	if ws == '' {
		return error('No workspace configured')
	}
	// Expand ~ to home directory
	if ws.starts_with('~') {
		home := os.home_dir()
		ws = home + ws[1..]
	}
	return ws
}
