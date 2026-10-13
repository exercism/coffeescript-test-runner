{ XMLParser } = require("fast-xml-parser");
fs = require 'fs'
he = require 'he'

class TestRunner
  constructor: () ->
    @astData = []
    @taskIdsEnabled = false

    configFile = process.argv[7]
    if configFile? and fs.existsSync(configFile)
      config = JSON.parse(fs.readFileSync(configFile, 'utf8'))
      @taskIdsEnabled = config.custom?['flag.tests.task-per-describe'] is true

  read_test_cases: (results) =>
    fs.readFile process.argv[2], 'utf8', (err, data) =>
      if err
        @error_handling()
      else
        @read_ast_tree()
          .then(() =>
            parser = new XMLParser(ignoreAttributes: false)
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
          name = he.decode(test_case['@_name'].replace(/'/g, "\'"));
          testInfo = @astData.find (element) => he.decode(element.name) is name
          return @error_handling() if testInfo is undefined
          testCode = file.slice(testInfo["loc"]["start"]["line"], testInfo["loc"]["end"]["line"])
          length = testCode[0].match(/^\s*/)[0].length
          testCode = (testCode.map (line) => (line.slice(length))).join("\n")
          data = 
            name: test_case['@_name']
            test_code: testCode

          if @taskIdsEnabled and testInfo.task_id?
            data['task_id'] = testInfo.task_id
          
          if test_case.hasOwnProperty('failure')
            data['status'] = 'fail'
            data['message'] = test_case['failure']['@_message']
          else
            data['status'] = 'pass'
            data['message'] = null
          test_cases.push(data)
        @write_result((if test_cases.some (item) -> item.status is "fail" then  "fail" else "pass"), test_cases)

  error_handling: () =>
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
    nextTaskId = 0
    search_keys = (obj, taskId) =>
      for key in Object.keys(obj)
        child = obj[key]
        continue unless typeof child is 'object' and child?

        calleeName = child["expression"]?["callee"]?["name"]
        if child["type"] is "ExpressionStatement" and calleeName is "it"
          name = @read_test_name(child["expression"]?["arguments"]?[0])
          if name? and child["expression"]?["arguments"]?[1]?["loc"]?
            @astData.push({name: name, loc: child["expression"]["arguments"][1]["loc"], task_id: taskId})
          else
            console.log("incorrect")
        else if child["type"] is "ExpressionStatement" and calleeName is "describe"
          nextTaskId += 1
          search_keys(child, nextTaskId)
        else
          search_keys(child, taskId)

    for statement in ast.program?.body ? []
      search_keys(statement)

  read_test_name: (node) =>
    return unless node?
    return node.value if typeof node.value is "string"
    return unless node.type is "BinaryExpression" and node.operator is "+"

    left = @read_test_name(node.left)
    right = @read_test_name(node.right)
    return unless left? and right?

    left + right

  write_result: (status, test_cases = [], message = "") ->
    result = 
      version: 3
      status: status
      tests: test_cases
      message: message if message isnt ""

    
    
    fs.writeFile "#{process.argv[3]}/results.json", "#{JSON.stringify(result, null, "\t")}\n", (err) ->
      if err
        console.log err
      else
        console.log 'File written successfully'

testRunner = new TestRunner
testRunner.read_test_cases()
