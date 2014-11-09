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

  describe 'atomShellVersionText', ->
    it 'returns the atom-shell version number', ->
      expect(BugReport.atomShellVersionText(atomShellVersion: '1.2.3')).toBe '1.2.3'

    it 'returns the empty string if there is no atom-shell version info', ->
      expect(BugReport.atomShellVersionText({})).toBe ''

  describe 'macVersionText', ->
    it 'returns the ProductName and ProductVersion', ->
      info =
        ProductName: 'foo'
        ProductVersion: 'bar'

      expect(BugReport.macVersionText(info)).toBe 'foo bar'

    it 'returns Unknown OS X version when no ProductName is supplied', ->
      expect(BugReport.macVersionText(ProductVersion: 'bar')).toBe 'Unknown OS X version'

    it 'returns Unknown OS X version when no ProductVersion is supplied', ->
      expect(BugReport.macVersionText(ProductName: 'foo')).toBe 'Unknown OS X version'
