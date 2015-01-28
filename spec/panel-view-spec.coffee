fs = require 'fs'
path = require 'path'
temp = require 'temp'

PanelView = require '../lib/panel-view'

helper = require './spec-helper'

describe 'PanelView', ->
  [panel, editor, tokenPath, workspaceElement] = []

  beforeEach ->
    directory = temp.mkdirSync()
    tokenPath = path.join(directory, 'faketoken.txt')
    workspaceElement = atom.views.getView(atom.workspace)

    atom.config.set('bug-report.saveToken', true)
    atom.config.set('bug-report.tokenPath', tokenPath)

    waitsForPromise ->
      atom.workspace.open().then (e) ->
        editor = e

    runs ->
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
      fs.writeFileSync(tokenPath, 'foo')

      waitsForPromise ->
        atom.workspace.open().then (e) ->
          editor = e
          panel = new PanelView(editor)

      runs ->
        expect(panel.tokenInput.prop('placeholder')).toBe 'Default: stored in file'

    it 'adds command listeners for core:focus-next and core:confirm to titleInput', ->
      titleInput = workspaceElement.querySelector('.title-input')
      expect(helper.hasCommand(titleInput, 'core:focus-next')).toBeTruthy()
      expect(helper.hasCommand(titleInput, 'core:confirm')).toBeTruthy()

    it 'adds command listeners for core:focus-next and core:confirm to repoInput', ->
      repoInput = workspaceElement.querySelector('.repo-input')
      expect(helper.hasCommand(repoInput, 'core:focus-next')).toBeTruthy()
      expect(helper.hasCommand(repoInput, 'core:confirm')).toBeTruthy()

    it 'adds command listeners for core:focus-next and core:confirm to tokenInput', ->
      tokenInput = workspaceElement.querySelector('.token-input')
      expect(helper.hasCommand(tokenInput, 'core:focus-next')).toBeTruthy()
      expect(helper.hasCommand(tokenInput, 'core:confirm')).toBeTruthy()

    it 'adds a command listener for core:cancel to the workspace view', ->
      expect(helper.hasCommand(workspaceElement, 'core:cancel')).toBeTruthy()

  describe 'destruction', ->
    it 'disposes of the commands', ->
      spyOn(panel.disposables, 'dispose')
      spyOn(editor, 'destroy')

      panel.destroy()

      expect(panel.disposables.dispose).toHaveBeenCalled()
      expect(editor.destroy).toHaveBeenCalled()

  describe 'core:cancel', ->
    it 'destroys the editor and panel when Abandon is chosen', ->
      spyOn(atom, 'confirm').andReturn(0)
      spyOn(panel.disposables, 'dispose')
      spyOn(editor, 'destroy')

      atom.commands.dispatch(workspaceElement, 'core:cancel')

      expect(panel.disposables.dispose).toHaveBeenCalled()
      expect(editor.destroy).toHaveBeenCalled()

    it 'does not destroy the editor nor panel when Keep is chosen', ->
      spyOn(atom, 'confirm').andReturn(1)
      spyOn(panel.disposables, 'dispose')
      spyOn(editor, 'destroy')

      atom.commands.dispatch(workspaceElement, 'core:cancel')

      expect(panel.disposables.dispose).not.toHaveBeenCalled()
      expect(editor.destroy).not.toHaveBeenCalled()

  describe 'storedToken', ->
    it 'is falsy when bug-report.saveToken is false', ->
      atom.config.set('bug-report.saveToken', false)

      expect(panel.storedToken()).toBeUndefined()

    it 'is falsy when saveToken is true but tokenPath is unset', ->
      atom.config.set('bug-report.tokenPath', undefined)

      expect(panel.storedToken()).toBeUndefined()

    it 'is falsy when saveToken is true, tokenPath is set but the token file does not exist', ->
      expect(panel.storedToken()).toBeUndefined()

    it 'is undefined when the saveToken is false, even if the token file exists', ->
      atom.config.set('bug-report.saveToken', false)
      fs.writeFileSync(tokenPath, 'foo')

      expect(panel.storedToken()).toBeUndefined()

    it 'returns the token when the token is set', ->
      fs.writeFileSync(tokenPath, 'foo')

      expect(panel.storedToken()).toBe 'foo'

  describe 'posting', ->
    [postActualSpy] = []

    beforeEach ->
      postActualSpy = spyOn(panel, 'postActual')

    describe 'titleInput', ->
      beforeEach ->
        spyOn(atom, 'confirm')

      it 'displays a dialog if the title is empty', ->
        panel.post()

        expect(atom.confirm).toHaveBeenCalled()
        expect(postActualSpy).not.toHaveBeenCalled()

      it 'displays a dialog if the title consists only of whitespace', ->
        panel.titleInput.val('     ')
        panel.post()

        expect(atom.confirm).toHaveBeenCalled()
        expect(postActualSpy).not.toHaveBeenCalled()

    describe 'repoInput', ->
      beforeEach ->
        spyOn(atom, 'confirm')
        panel.titleInput.val('test')
        panel.tokenInput.val('foo')

      it 'displays a dialog if the repo is formatted incorrectly', ->
        panel.repoInput.val('foo')
        panel.post()

        expect(atom.confirm).toHaveBeenCalled()
        expect(postActualSpy).not.toHaveBeenCalled()

      it 'defaults to atom/atom if empty', ->
        panel.repoInput.val('')

        panel.post()

        expect(postActualSpy).toHaveBeenCalledWith('test', 'atom', 'atom', 'foo')

      it 'parses user/repo input', ->
        panel.repoInput.val('user/repo')

        panel.post()

        expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')

      it 'parses GitHub web URLs', ->
        panel.repoInput.val('https://github.com/user/repo')

        panel.post()

        expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')

      it 'parses GitHub https repository URLs', ->
        panel.repoInput.val('https://github.com/user/repo.git')

        panel.post()

        expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')

      it 'parses GitHub ssh repository URLs', ->
        panel.repoInput.val('git@github.com:user/repo.git')

        panel.post()

        expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')

    describe 'tokenInput', ->
      beforeEach ->
        spyOn(atom, 'confirm')
        panel.titleInput.val('test')
        panel.repoInput.val('user/repo')

      describe 'saveToken is false', ->
        beforeEach ->
          atom.config.set('bug-report.saveToken', false)

        it 'does not save the token if it is supplied', ->
          panel.tokenInput.val('foo')

          panel.post()

          expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')
          expect(fs.existsSync(tokenPath)).toBeFalsy()

        it 'does not use the stored token if one is not supplied', ->
          fs.writeFileSync(tokenPath, 'foo')

          panel.post()

          expect(postActualSpy).not.toHaveBeenCalled()

      describe 'saveToken is true', ->
        beforeEach ->
          atom.config.set('bug-report.saveToken', true)

        it 'saves the token if it is supplied', ->
          atom.config.set('bug-report.saveToken', true)
          panel.tokenInput.val('foo')

          panel.post()

          expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')
          expect(fs.readFileSync(tokenPath).toString()).toBe 'foo'

        it 'saves the token if it is supplied even if a different one is already stored', ->
          fs.writeFileSync(tokenPath, 'bar')
          atom.config.set('bug-report.saveToken', true)
          panel.tokenInput.val('foo')

          panel.post()

          expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')
          expect(fs.readFileSync(tokenPath).toString()).toBe 'foo'

        it 'uses the stored token if one is not supplied', ->
          fs.writeFileSync(tokenPath, 'foo')
          atom.config.set('bug-report.saveToken', true)

          panel.post()

          expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')
          expect(fs.readFileSync(tokenPath).toString()).toBe 'foo'

    describe 'happy path', ->
      it 'posts', ->
        panel.titleInput.val('test')
        panel.repoInput.val('user/repo')
        panel.tokenInput.val('foo')

        panel.post()

        expect(postActualSpy).toHaveBeenCalledWith('test', 'user', 'repo', 'foo')
