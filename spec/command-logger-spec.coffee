{WorkspaceView} = require 'atom'

CommandLogger = require '../lib/command-logger'

describe 'CommandLogger', ->
  [logger] = []

  dispatch = (command) ->
    atom.commands.dispatch(atom.workspaceView.element, command)

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.getModel()

    logger = new CommandLogger

  describe 'logging of commands', ->
    it 'catches the name of the command', ->
      dispatch('foo:bar')

      expect(logger.latestEvent().name).toBe 'foo:bar'

    it 'catches the source of the command', ->
      dispatch('foo:bar')

      expect(logger.latestEvent().source).toBeDefined()

    it 'logs repeat commands as one command', ->
      dispatch('foo:bar')
      dispatch('foo:bar')

      expect(logger.latestEvent().name).toBe 'foo:bar'
      expect(logger.latestEvent().count).toBe 2

    it 'ignores some commands', ->
      dispatch('show.bs.tooltip')

      expect(logger.latestEvent().name).not.toBe 'show.bs.tooltip'

    it 'only logs sixteen commands max', ->
      dispatch(char) for char in ['a'..'z']

      expect(logger.eventLog.length).toBe 16

  describe 'formatting of text log', ->
    it 'does not output empty log items', ->
      expect(logger.getText()).toBe """
        ```
        ```
      """

    it 'formats commands with the time, name and source', ->
      atom.commands.dispatch(atom.workspaceView.element, 'foo:bar')

      expect(logger.getText()).toBe """
        ```
             -0:00.0 foo:bar (atom-workspace.workspace.scrollbars-visible-when-scrolling)
        ```
      """

    it 'formats commands in chronological order', ->
      dispatch('foo:first')
      dispatch('foo:second')
      dispatch('foo:third')

      expect(logger.getText()).toBe """
        ```
             -0:00.0 foo:first (atom-workspace.workspace.scrollbars-visible-when-scrolling)
             -0:00.0 foo:second (atom-workspace.workspace.scrollbars-visible-when-scrolling)
             -0:00.0 foo:third (atom-workspace.workspace.scrollbars-visible-when-scrolling)
        ```
      """

    it 'displays a multiplier for repeated commands', ->
      dispatch('foo:bar')
      dispatch('foo:bar')

      expect(logger.getText()).toBe """
        ```
          2x -0:00.0 foo:bar (atom-workspace.workspace.scrollbars-visible-when-scrolling)
        ```
      """
