{WorkspaceView} = require 'atom'

BugReport = require '../lib/bug-report'

helper = require './spec-helper'

describe 'BugReport', ->
  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.getModel()

    waitsForPromise ->
      atom.packages.activatePackage('bug-report')

  describe 'activation', ->
    it 'creates the open command', ->
      expect(helper.hasCommand(atom.workspaceView, 'bug-report:open')).toBeTruthy()

    it 'creates the insert version info command', ->
      expect(helper.hasCommand(atom.workspaceView, 'bug-report:insert-version-info')).toBeTruthy()

    it 'creates the command logger', ->
      expect(BugReport.commandLogger).not.toBeNull()

    it 'creates an openReport service', ->
      bugReport = null
      spyOn(BugReport, 'openReport')

      waitsFor (done) ->
        atom.services.consume 'bug-report', '1.0.0', (report) ->
          bugReport = report
          done()

      runs ->
        bugReport.openReport('foo')
        expect(BugReport.openReport).toHaveBeenCalledWith('foo')

  describe 'deactivation', ->
    beforeEach ->
      atom.packages.deactivatePackage('bug-report')

    it 'removes the open command', ->
      expect(helper.hasCommand(atom.workspaceView, 'bug-report:open')).toBeFalsy()

    it 'removes the insert version info command', ->
      expect(helper.hasCommand(atom.workspaceView, 'bug-report:insert-version-info')).toBeFalsy()

    it 'destroys the command logger', ->
      expect(BugReport.commandLogger).toBeNull()

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

  describe 'packageVersionText', ->
    it 'returns the package name and version', ->
      expect(BugReport.packageVersionText(name: 'foo', version: 'bar')).toBe '`foo` vbar'

    it 'returns `bug-report` and version when no name is given', ->
      expect(BugReport.packageVersionText(version: 'bar')).toBe '`bug-report` vbar'

    it 'returns the package name when there is no version', ->
      expect(BugReport.packageVersionText(name: 'foo')).toBe '`foo`'

  describe 'insert version info command', ->
    describe 'when an editor is open', ->
      [editor] = []

      beforeEach ->
        waitsForPromise -> atom.workspace.open('foo.txt').then (e) -> editor = e

      it 'inserts the version information into the editor', ->
        atom.commands.dispatch(atom.workspaceView.element, 'bug-report:insert-version-info')

        expect(editor.getText()).toEqual BugReport.versionSection()
