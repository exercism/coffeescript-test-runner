ExampleMultilineTestName = require './example-multiline-test-name'

describe 'Multiline test name', ->
  example = new ExampleMultilineTestName()

  it 'supports test descriptions that are split ' +
      'across lines', ->
    result = example.answer()
    expect(result).toEqual 42
