{ XMLParser } = require("fast-xml-parser");
fs = require 'fs'


read_test_cases = (results) ->
  test_cases = []
  fs.readFile process.argv[2], 'utf8', (err, data) ->
    if err
      fs.readFile process.argv[4], 'utf8', (err, data) ->
        if err
          console.log err
        else
          write_result('fail', [], data)
    else
      options =
        ignoreAttributes: false
      parser = new XMLParser(options)
      get_test_cases(parser.parse(data))

get_test_cases = (result) ->
  matchingKeys = []
  search_keys = (obj) ->
    for key in Object.keys(obj)
      if key is "testcase" 
        matchingKeys.push(obj[key])
      if typeof obj[key] is 'object'
        search_keys(obj[key])
  search_keys(result)
  matchingKeys = matchingKeys.flat()
  
  test_cases = []
  for test_case in matchingKeys
    data = 
      name: test_case['@_name']
    
    if test_case.hasOwnProperty('failure')
      data['status'] = 'fail'
      data['message'] = test_case['failure']['@_message']
    else
      data['status'] = 'pass'
      data['message'] = null
    test_cases.push(data)
  write_result((if test_cases.some (item) -> item.status is "fail" then  "fail" else "pass"), test_cases)

write_result = (status, test_cases = [], message = "") ->
  result = 
    version: 2
    status: status
    tests: test_cases
    message: message if message isnt ""

  
  
  fs.writeFile "#{process.argv[3]}/results.json", JSON.stringify(result, null, "\t"), (err) ->
    if err
      console.log err
    else
      console.log 'File written successfully'

read_test_cases()
