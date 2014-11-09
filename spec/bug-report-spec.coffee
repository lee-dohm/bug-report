fs = require 'fs'
path = require 'path'

BugReport = require '../lib/bug-report'

indent = (text) ->
  ("    #{line}" for line in text.split("\n")).join("\n")

getFixture = (name) ->
  fs.readFileSync(path.join(__dirname, 'fixtures', name)).toString()

describe 'BugReport', ->
  describe 'apmVersionText', ->
    it 'returns what is expected', ->
      expect(BugReport.apmVersionText(getFixture('apm-version.txt'))).toBe indent """
      * apm  0.109.0
      * npm  1.4.4
      * node 0.10.32
      * python 2.7.6
      * git 2.1.2
      """
