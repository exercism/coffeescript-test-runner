{ XMLParser } = require("fast-xml-parser");
fs = require 'fs'

class TestRunner
  constructor: () ->
    @astData = []

  read_test_cases: (results) =>
    fs.readFile process.argv[2], 'utf8', (err, data) =>
      if err
        @error_handeling()
      else
        @read_ast_tree()
          .then(() =>
            options =
              ignoreAttributes: false
            parser = new XMLParser(options)
            @get_test_cases(parser.parse(data))
          )
          .catch((err) => console.log(err))

  get_test_cases: (result) =>
    matchingKeys = []
    search_keys = (obj) =>
      for key in Object.keys(obj)
        if key is "testcase"
          obj[key] = if obj[key].length is undefined then [obj[key]] else obj[key]
          for testCase in obj[key]
            matchingKeys.push(testCase)
        if typeof obj[key] is 'object'
          search_keys(obj[key])
    search_keys(result)
    
    test_cases = []

    fs.readFile process.argv[6], 'utf8', (err, data) =>
      if err
        throw err
      else
        file = data.split("\n")
        for test_case in matchingKeys
          testInfo = @astData.find (element) => element.name is test_case['@_name']
          return @error_handeling() if testInfo is undefined
          testCode = file.slice(testInfo["loc"]["start"]["line"], testInfo["loc"]["end"]["line"])
          length = testCode[0].match(/^\s*/)[0].length
          testCode = (testCode.map (line) => (line.slice(length))).join("\n")
          data = 
            name: test_case['@_name']
            test_code: testCode
          
          if test_case.hasOwnProperty('failure')
            data['status'] = 'fail'
            data['message'] = test_case['failure']['@_message']
          else
            data['status'] = 'pass'
            data['message'] = null
          test_cases.push(data)
        @write_result((if test_cases.some (item) -> item.status is "fail" then  "fail" else "pass"), test_cases)

  error_handeling: () =>
    fs.readFile process.argv[4], 'utf8', (err, data) =>
      if err
        console.log err
      else
        @write_result('error', [], data)

  read_ast_tree: () =>
    new Promise((resolve, reject) =>
      fs.readFile process.argv[5], 'utf8', (err, data) =>
        if err
          reject(err)
        else
          json = JSON.parse(data)
          @get_ast_tree(json)
          resolve()
    )

  get_ast_tree: (ast) =>
    search_keys = (obj) =>
      for key in Object.keys(obj)
        if typeof obj[key] is 'object' and obj[key] isnt null
          if obj[key]["type"]? and obj[key]["expression"]?["callee"]?["name"]?
            if obj[key]["type"] is "ExpressionStatement" and obj[key]["expression"]["callee"]["name"] is "it"
              if obj[key]["expression"]?["arguments"]?[0]?["value"]? and obj[key]["expression"]?["arguments"]?[1]?["loc"]?
                @astData.push({name: obj[key]["expression"]["arguments"][0]["value"], loc: obj[key]["expression"]["arguments"][1]["loc"]})
              else
                console.log("incorrect")
            else
              search_keys(obj[key])
          else
            search_keys(obj[key])
    search_keys(ast)

  write_result: (status, test_cases = [], message = "") ->
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

testRunner = new TestRunner
testRunner.read_test_cases()
