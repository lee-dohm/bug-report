{WorkspaceView} = require 'atom'

CommandLogger = require '../lib/command-logger'

describe 'CommandLogger', ->
  [logger] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.getModel()

    logger = new CommandLogger

  describe 'logging of commands', ->
    it 'catches the name of the command', ->
      atom.commands.dispatch(atom.workspaceView.element, 'foo:bar')

      expect(logger.latestEvent().name).toBe 'foo:bar'

    it 'catches the source of the command', ->
      atom.commands.dispatch(atom.workspaceView.element, 'foo:bar')

      expect(logger.latestEvent().source).toBeDefined()

    it 'logs repeat commands as one command', ->
      atom.commands.dispatch(atom.workspaceView.element, 'foo:bar')
      atom.commands.dispatch(atom.workspaceView.element, 'foo:bar')

      expect(logger.latestEvent().name).toBe 'foo:bar'
      expect(logger.latestEvent().count).toBe 2

    it 'ignores some commands', ->
      atom.commands.dispatch(atom.workspaceView.element, 'show.bs.tooltip')

      expect(logger.latestEvent().name).not.toBe 'show.bs.tooltip'

    it 'only logs sixteen commands max', ->
      atom.commands.dispatch(atom.workspaceView.element, char) for char in ['a'..'z']

      expect(logger.eventLog.length).toBe 16
