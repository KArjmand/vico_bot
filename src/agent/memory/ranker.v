module memory

// SimpleRanker provides basic memory ranking without LLM.
@[noinit]
pub struct SimpleRanker {}

pub fn SimpleRanker.new() &SimpleRanker {
	return &SimpleRanker{}
}

pub fn (r &SimpleRanker) rank(query string, memories []MemoryItem, top int) []MemoryItem {
	if memories.len == 0 || top <= 0 {
		return []
	}

	// Simple ranking: return most recent items
	mut end := memories.len
	if end > top {
		end = top
	}

	return memories[..end]
}
