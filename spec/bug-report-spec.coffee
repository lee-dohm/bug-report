BugReport = require '../lib/bug-report'

helper = require './spec-helper'

describe 'BugReport', ->
  describe 'apmVersionText', ->
    it 'returns what is expected', ->
      versionText = helper.getFixture('apm-version.txt')
      expect(BugReport.apmVersionText(versionText)).toBe helper.indent """
      * apm  0.109.0
      * npm  1.4.4
      * node 0.10.32
      * python 2.7.6
      * git 2.1.2
      """
