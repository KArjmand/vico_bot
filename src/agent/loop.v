module agent

import time
import regex
import context
import chat
import providers
import session
import cron

// Make scheduler optional — much cleaner
pub struct AgentLoop {
mut:
	hub            &chat.Hub
	provider       providers.LLMProvider
	tools          &Registry
	sessions       &session.SessionManager
	context        &ContextBuilder
	memory         &MemoryStore
	model          string
	max_iterations int
	running        bool
}

pub fn new_agent_loop(hub &chat.Hub,
	provider &providers.LLMProvider,
	model string,
	max_iterations int,
	workspace string,
	scheduler ?&cron.Scheduler) &AgentLoop {
	mut mut_model := model
	mut mut_workspace := workspace

	if mut_model == '' {
		mut_model = provider.get_default_model()
	}
	if mut_workspace == '' {
		mut_workspace = '.'
	}

	mut reg := new_registry()

	reg.register(new_message_tool(hub))
	reg.register(new_filesystem_tool(mut_workspace))
	reg.register(new_exec_tool(60))
	reg.register(new_web_tool())
	reg.register(new_spawn_tool())

	// Safely register cron tool only when provided
	if mut s := scheduler {
		reg.register(new_cron_tool(s))
	}

	sm := session.new_session_manager(mut_workspace)
	ranker := new_llm_ranker(provider, mut_model)

	// If Ranker interface expects non-error return, wrap it
	mut ctx := new_context_builder(mut_workspace, ranker, 5)

	mem := new_memory_store_with_workspace(mut_workspace, 100)
	reg.register(new_write_memory_tool(mem))

	// skill tools ...
	skill_mgr := new_skill_manager(mut_workspace)
	reg.register(new_create_skill_tool(skill_mgr))
	reg.register(new_list_skills_tool(skill_mgr))
	reg.register(new_read_skill_tool(skill_mgr))
	reg.register(new_delete_skill_tool(skill_mgr))

	return &AgentLoop{
		hub:            hub
		provider:       provider
		tools:          reg
		sessions:       &sm
		context:        ctx
		memory:         mem
		model:          mut_model
		max_iterations: max_iterations
		running:        false
	}
}

// ────────────────────────────────────────────────

pub fn (mut a AgentLoop) run(mut parent context.Context) {
	a.running = true
	println('Agent loop started')

	mut remember_re := regex.regex_opt(r'^remember(?:\s+to)?\s+(.+)$') or {
		panic('remember regex failed to compile: ${err}')
	}

	done_chan := parent.done()
	for a.running {
		select {
			// Shutdown signal – use ctx.done() (standard name)
			_ := <-done_chan {
				println('Agent loop received shutdown signal')
				a.running = false
				return
			}
			msg := <-a.hub.in {
				println('Processing message from ${msg.channel}:${msg.sender_id}')

				trimmed := msg.content.trim_space()

				if remember_re.matches_string(trimmed) {
					groups := remember_re.get_group_list()
					if groups.len >= 2 { // group 0 = full match, group 1 = capture
						note := trimmed[groups[1].start..groups[1].end]

						a.memory.append_today(note) or { eprintln('memory append error: ${err}') }

						out := chat.Outbound{
							channel: msg.channel
							chat_id: msg.chat_id
							content: "OK, I've remembered that."
						}

						select {
							a.hub.out <- out {}
							else {}
						}

						mut sess := a.sessions.get_or_create('${msg.channel}:${msg.chat_id}')
						sess.add_message('user', msg.content)
						sess.add_message('assistant', "OK, I've remembered that.")
						a.sessions.save(mut sess) or {}

						continue
					}
				}

				// Tool context – if your Tool struct/interface has set_context
				// If not → remove or implement it
				/*
                if mut t := a.tools.get('message') {
                    if mut t is ContextAware {
                        t.set_context(msg.channel, msg.chat_id)
                    }
                }
                if mut t := a.tools.get('cron') {
                    if mut t is ContextAware {
                        t.set_context(msg.channel, msg.chat_id)
                    }
                }
                */

				mut sess := a.sessions.get_or_create('${msg.channel}:${msg.chat_id}')
				mem_ctx := a.memory.get_memory_context() or { '' }
				memories := a.memory.recent(5)

				mut messages := a.context.build_messages(sess.get_history(), msg.content,
					msg.channel, msg.chat_id, mem_ctx, memories)

				mut iteration := 0
				mut final_content := ''
				mut last_tool_result := ''

				for iteration < a.max_iterations {
					iteration++

					resp := a.provider.chat(mut parent, messages, a.tools.definitions(),
						a.model) or {
						eprintln('LLM error: ${err}')
						final_content = 'Sorry, an error occurred.'
						break
					}

					if resp.has_tool_calls {
						messages << providers.Message{
							role:       'assistant'
							content:    resp.content
							tool_calls: resp.tool_calls
						}

						for tc in resp.tool_calls {
							// Convert json2.Any map → map[string]string if that's what execute expects
							mut args_str := map[string]string{}
							for k, v in tc.arguments {
								args_str[k] = v.str()
							}

							res := a.tools.execute(tc.name, args_str) or { '(tool failed) ${err}' }

							last_tool_result = res
							messages << providers.Message{
								role:         'tool'
								content:      res
								tool_call_id: tc.id
							}
						}
						continue
					}

					final_content = resp.content
					break
				}

				if final_content == '' && last_tool_result != '' {
					final_content = last_tool_result
				}

				sess.add_message('user', msg.content)
				sess.add_message('assistant', final_content)
				a.sessions.save(mut sess) or {}

				out := chat.Outbound{
					channel: msg.channel
					chat_id: msg.chat_id
					content: final_content
				}

				select {
					a.hub.out <- out {}
					else {}
				}
			}
			100 * time.millisecond {}
		}
	}
}

pub fn (mut a AgentLoop) process_direct(content string, timeout time.Duration) !string {
	mut bg := context.background()
	mut ctx, cancel := context.with_timeout(mut bg, timeout)
	defer { cancel() }

	// Remove set_context calls unless you implement them
	/*
    if mut t := a.tools.get('message') {
        if mut t is ContextAware { t.set_context('cli', 'direct') }
    }
    */

	mem_ctx := a.memory.get_memory_context() or { '' }
	memories := a.memory.recent(5)

	mut messages := a.context.build_messages([], content, 'cli', 'direct', mem_ctx, memories)

	mut last_tool_result := ''
	for iteration := 0; iteration < a.max_iterations; iteration++ {
		resp := a.provider.chat(mut ctx, messages, a.tools.definitions(), a.model) or { return err }

		if !resp.has_tool_calls {
			if resp.content != '' {
				return resp.content
			}
			if last_tool_result != '' {
				return last_tool_result
			}
			return resp.content
		}

		messages << providers.Message{
			role:       'assistant'
			content:    resp.content
			tool_calls: resp.tool_calls
		}

		for tc in resp.tool_calls {
			mut args_str := map[string]string{}
			for k, v in tc.arguments {
				args_str[k] = v.str()
			}

			result := a.tools.execute(tc.name, args_str) or { '(tool error) ${err}' }
			last_tool_result = result
			messages << providers.Message{
				role:         'tool'
				content:      result
				tool_call_id: tc.id
			}
		}
	}

	return 'Max iterations reached'
}
