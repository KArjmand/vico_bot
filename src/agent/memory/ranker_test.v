module memory

import time

fn test_simple_ranker_basic() {
	ranker := SimpleRanker.new()

	memories := [
		MemoryItem{
			text:      'First memory'
			kind:      'user'
			timestamp: time.now().add(-2 * time.hour)
		},
		MemoryItem{
			text:      'Second memory'
			kind:      'user'
			timestamp: time.now().add(-1 * time.hour)
		},
		MemoryItem{
			text:      'Third memory'
			kind:      'user'
			timestamp: time.now()
		},
	]

	// Should return most recent items
	result := ranker.rank('any query', memories, 2)
	assert result.len == 2
	// Should be ordered by timestamp (most recent first or same order as input)
	assert result[0].text == 'First memory'
	assert result[1].text == 'Second memory'
}

fn test_simple_ranker_empty() {
	ranker := SimpleRanker.new()

	empty_memories := []MemoryItem{}
	result := ranker.rank('query', empty_memories, 5)
	assert result.len == 0
}

fn test_simple_ranker_zero_top() {
	ranker := SimpleRanker.new()

	memories := [
		MemoryItem{
			text:      'Test memory'
			kind:      'user'
			timestamp: time.now()
		},
	]

	result := ranker.rank('query', memories, 0)
	assert result.len == 0
}

fn test_simple_ranker_top_larger_than_memories() {
	ranker := SimpleRanker.new()

	memories := [
		MemoryItem{
			text:      'Only memory'
			kind:      'user'
			timestamp: time.now()
		},
	]

	result := ranker.rank('query', memories, 5)
	assert result.len == 1
	assert result[0].text == 'Only memory'
}
