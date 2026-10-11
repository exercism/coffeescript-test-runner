answer = require './example-task-ids'

# First task by order of appearance, not label, in the file
describe 'second task', ->
  it 'Should appear first', ->
    expect(answer()).toEqual 42

  xit 'Should appear second', ->
    expect(answer()).toEqual 42

describe 'first task', ->
  xit 'Should appear third', ->
    expect(answer()).toEqual 42
