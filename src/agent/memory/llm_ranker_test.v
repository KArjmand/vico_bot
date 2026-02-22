module memory

import time
import providers
import x.json2

fn test_llm_ranker_basic() {
	mock_provider := providers.new_mock_provider()
	ranker := new_llm_ranker(mock_provider, 'test-model')

	memories := [
		MemoryItem{
			text:      'User asked about Python programming'
			kind:      'user'
			timestamp: time.now()
		},
		MemoryItem{
			text:      'User asked about V language'
			kind:      'user'
			timestamp: time.now()
		},
	]

	result := ranker.rank('Python programming', memories, 2)
	assert result.len <= 2
	assert result.len > 0
}

fn test_llm_ranker_empty_memories() {
	mock_provider := providers.new_mock_provider()
	ranker := new_llm_ranker(mock_provider, 'test-model')

	empty_memories := []MemoryItem{}
	result := ranker.rank('any query', empty_memories, 5)
	assert result.len == 0
}

fn test_llm_ranker_zero_top() {
	mock_provider := providers.new_mock_provider()
	ranker := new_llm_ranker(mock_provider, 'test-model')

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

fn test_llm_ranker_fallback() {
	mock_provider := providers.new_mock_provider()
	ranker := new_llm_ranker(mock_provider, 'test-model')

	memories := [
		MemoryItem{
			text:      'Test memory 1'
			kind:      'user'
			timestamp: time.now()
		},
		MemoryItem{
			text:      'Test memory 2'
			kind:      'user'
			timestamp: time.now()
		},
	]

	result := ranker.rank('query', memories, 1)
	assert result.len == 1
}

fn test_llm_ranker_uses_provider() {
	mut mock_provider := providers.new_mock_provider()
	mock_provider.tool_calls = [
		providers.ToolCall{
			id:   '1'
			name: 'rank_memories'
			arguments: {
				'indices': json2.Any([json2.Any(1), json2.Any(0)])
			}
		},
	]
	ranker := new_llm_ranker(mock_provider, 'test-model')

	memories := [
		MemoryItem{
			text:      'buy milk'
			kind:      'short'
			timestamp: time.now()
		},
		MemoryItem{
			text:      'call mom'
			kind:      'short'
			timestamp: time.now()
		},
	]

	result := ranker.rank('milk', memories, 2)
	assert result.len == 2
	assert result[0].text == 'call mom'
}

fn test_llm_ranker_parses_float_indices() {
	mut mock_provider := providers.new_mock_provider()
	mock_provider.tool_calls = [
		providers.ToolCall{
			id:   '1'
			name: 'rank_memories'
			arguments: {
				'indices': json2.Any([json2.Any(f64(2)), json2.Any(f64(0))])
			}
		},
	]
	ranker := new_llm_ranker(mock_provider, 'test-model')

	memories := [
		MemoryItem{
			text:      'buy milk'
			kind:      'short'
			timestamp: time.now()
		},
		MemoryItem{
			text:      'call mom'
			kind:      'short'
			timestamp: time.now()
		},
		MemoryItem{
			text:      'big fact'
			kind:      'long'
			timestamp: time.now()
		},
	]

	result := ranker.rank('milk', memories, 2)
	assert result.len == 2
	assert result[0].text == 'big fact'
}

fn test_llm_ranker_parses_array_from_content() {
	mut mock_provider := providers.new_mock_provider()
	mock_provider.response = '[1,0]'
	ranker := new_llm_ranker(mock_provider, 'test-model')

	memories := [
		MemoryItem{
			text:      'buy milk'
			kind:      'short'
			timestamp: time.now()
		},
		MemoryItem{
			text:      'call mom'
			kind:      'short'
			timestamp: time.now()
		},
	]

	result := ranker.rank('milk', memories, 2)
	assert result.len == 2
	assert result[0].text == 'call mom'
}
