{WorkspaceView} = require 'atom'

CommandLogger = require '../lib/command-logger'

describe 'CommandLogger', ->
  [logger] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.getModel()

    logger = new CommandLogger

  describe 'catching onWillDispatch', ->
    it 'catches the name of the command', ->
      atom.commands.dispatch(atom.workspaceView.element, 'foo:bar')

      expect(logger.latestEvent().name).toBe 'foo:bar'

    it 'catches the source of the command', ->
      atom.commands.dispatch(atom.workspaceView.element, 'foo:bar')

      expect(logger.latestEvent().source).toBeDefined()
