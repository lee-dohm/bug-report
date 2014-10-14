{WorkspaceView} = require 'atom'
BugReport = require '../lib/bug-report'

describe "BugReport", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('bug-report')

  describe "when the bug-report:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.bug-report')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'bug-report:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.bug-report')).toExist()
        atom.workspaceView.trigger 'bug-report:toggle'
        expect(atom.workspaceView.find('.bug-report')).not.toExist()
