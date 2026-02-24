module cron

import time

@[heap]
pub struct Job {
pub:
	id        string
	name      string
	message   string
	channel   string
	chat_id   string
	recurring bool
	interval  time.Duration
pub mut:
	fire_at time.Time
	fired   bool
}

pub type FireCallback = fn (job Job)

@[heap; noinit]
pub struct Scheduler {
	callback FireCallback @[required]
mut:
	jobs    map[string]&Job
	next_id int
	running bool
}

pub fn Scheduler.new(callback FireCallback) Scheduler {
	return Scheduler{
		callback: callback
		jobs:     map[string]&Job{}
	}
}

pub fn (mut s Scheduler) add(name string, message string, delay time.Duration, channel string, chat_id string) string {
	s.next_id++
	id := 'job-${s.next_id}'
	s.jobs[id] = &Job{
		id:      id
		name:    name
		message: message
		fire_at: time.now().add(delay)
		channel: channel
		chat_id: chat_id
	}
	return id
}

pub fn (mut s Scheduler) add_recurring(name string, message string, interval time.Duration, channel string, chat_id string) string {
	s.next_id++
	id := 'job-${s.next_id}'
	s.jobs[id] = &Job{
		id:        id
		name:      name
		message:   message
		fire_at:   time.now().add(interval)
		channel:   channel
		chat_id:   chat_id
		recurring: true
		interval:  interval
	}
	return id
}

pub fn (mut s Scheduler) cancel_by_name(name string) bool {
	mut found_id := ''
	for id, j in s.jobs {
		if j.name == name {
			found_id = id
			break
		}
	}
	if found_id != '' {
		s.jobs.delete(found_id)
		return true
	}
	return false
}

pub fn (s &Scheduler) list() []Job {
	mut result := []Job{cap: s.jobs.len}
	for _, j in s.jobs {
		result << *j
	}
	return result
}

pub fn (mut s Scheduler) start() {
	s.running = true
	for {
		if !s.running {
			break
		}
		time.sleep(100 * time.millisecond)
		s.tick(time.now())
	}
}

pub fn (mut s Scheduler) stop() {
	s.running = false
}

fn (mut s Scheduler) tick(now time.Time) {
	mut to_fire := []Job{}
	for id, j in s.jobs {
		if !j.fired && now.unix_milli() >= j.fire_at.unix_milli() {
			if j.recurring {
				unsafe {
					mut job := &j
					job.fire_at = now.add(job.interval)
				}
			} else {
				unsafe {
					mut job := &j
					job.fired = true
				}
				s.jobs.delete(id)
			}
			to_fire << *j
		}
	}
	for j in to_fire {
		s.callback(j)
	}
}
