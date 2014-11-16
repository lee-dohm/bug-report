{WorkspaceView} = require 'atom'
fs = require 'fs'
path = require 'path'
temp = require 'temp'

PanelView = require '../lib/panel-view'

helper = require './spec-helper'

describe 'PanelView', ->
  [panel, editor, tokenPath] = []

  beforeEach ->
    directory = temp.mkdirSync()
    tokenPath = path.join(directory, 'faketoken.txt')

    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.getModel()

    atom.config.set('bug-report.saveToken', true)
    atom.config.set('bug-report.tokenPath', tokenPath)

    waitsForPromise ->
      atom.workspace.open().then (e) ->
        editor = e
        panel = new PanelView(editor)

  describe 'initialization', ->
    it 'defaults the inputs to empty', ->
      expect(panel.titleInput.val()).toBe ''
      expect(panel.repoInput.val()).toBe ''
      expect(panel.tokenInput.val()).toBe ''

    it 'displays a placeholder for the repo', ->
      expect(panel.repoInput.prop('placeholder')).toBe 'Default: atom/atom'

    it 'does not display a placeholder for the token if a token has not been saved previously', ->
      expect(panel.tokenInput.prop('placeholder')).toBe ''

    it 'displays a placeholder for the token if a token has been saved previously', ->
      fs.writeFileSync(tokenPath, '')

      waitsForPromise ->
        atom.workspace.open().then (e) ->
          editor = e
          panel = new PanelView(editor)

      runs ->
        expect(panel.tokenInput.prop('placeholder')).toBe 'Default: stored in file'

    it 'adds command listeners for core:focus-next and core:confirm to titleInput', ->
      expect(helper.hasCommand(panel.titleInput, 'core:focus-next')).toBeTruthy()
      expect(helper.hasCommand(panel.titleInput, 'core:confirm')).toBeTruthy()

    it 'adds command listeners for core:focus-next and core:confirm to repoInput', ->
      expect(helper.hasCommand(panel.repoInput, 'core:focus-next')).toBeTruthy()
      expect(helper.hasCommand(panel.repoInput, 'core:confirm')).toBeTruthy()

    it 'adds command listeners for core:focus-next and core:confirm to tokenInput', ->
      expect(helper.hasCommand(panel.tokenInput, 'core:focus-next')).toBeTruthy()
      expect(helper.hasCommand(panel.tokenInput, 'core:confirm')).toBeTruthy()
