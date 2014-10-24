{View}  = require 'atom'
fs      = require 'fs'
request = require 'request'

oldView = null

module.exports =
class PanelView extends View

  @content: ->
    @div class:'bug-report-panel tool-panel', tabindex:-1, =>
      @div class:'label-hdr',  'Bug Report'
      @div outlet:'prePost', class:'pre-post', =>

        @div class:'horiz-div', =>
          @div class:'inp-label', 'Issue Title:'
          @input
            outlet: 'titleInput'
            class:  'title-input native-key-bindings'

        @div class:'horiz-div', =>
          @div class:'inp-label', 'GitHub Repo:'
          @input
            outlet: 'repoInput'
            class:  'repo-input native-key-bindings'
            placeholder: 'Default: atom/atom'

        @div class:'horiz-div', =>
          @div class:'inp-label', 'GitHub Token:'
          @input
            outlet: 'tokenInput'
            class:  'token-input native-key-bindings'
          @input
            outlet: 'postBtn'
            class:  'post-btn btn'
            type:   'button'
            value:  'Post Issue'

      @div outlet:'postMsg', class:'post-msg', =>
        @div class:'label-msg', 'Posting, please wait ...'

      @div outlet:'postPost', class:'post-post', =>
        @span class:'label-link', 'This has been posted to the GitHub repository '
        @a   outlet:'linkRepo', class:'link-repo'
        @span class:'label-link', ' as '
        @a   outlet:'linkIssue', class:' link-issue '
        @span class:'label-period', '.'
        @input
          outlet: 'closeBtn'
          class:  'close-btn btn'
          type:   'button'
          value:  'Close Bug Report'

  initialize: (@editor) ->

    oldView?.destroy()
    oldView = @

    saveToken = atom.config.get 'bug-report.saveTokenToFile'
    if saveToken and
        fs.existsSync atom.config.get 'bug-report.filePathToSaveGithubPersonalApiToken'
      @tokenInput.attr placeholder: 'Default: stored in file'

    @subscribe @titleInput, 'keydown', (e) =>
      switch e.which
        when  9 then @repoInput.focus() # tab
        when 13 then @post()            # cr
        else return
      false

    @subscribe @repoInput, 'keydown',  (e) =>
      switch e.which
        when  9 then @tokenInput.focus() # tab
        when 13 then @post()             # cr
        else return
      false

    @subscribe @tokenInput, 'keydown',  (e) =>
      switch e.which
        when  9 then @titleInput.focus() # tab
        when 13 then @post()             # cr
        else return
      false

    @subscribe @postBtn,  'click', => @post()
    @subscribe @closeBtn, 'click', =>
      @editor.destroy()
      @destroy()

    disposable = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      if activeItem in [@editor, @] then @css display:'inline-block'
      else @hide()

    @disposables ?= []
    @disposables.push disposable

    atom.workspaceView.prependToBottom @

  trim: (str) -> str.replace(/^\s*|\s*$/g, '')

  post: ->
    title = @trim @titleInput.val()
    if not title
      atom.confirm
        message: 'Bug-Report Error:\n'
        detailedMessage: 'The title field is empty.'
        buttons: ['OK']
      return

    userSlashRepo = @repoInput.val().replace(/\s/g, '')
    userSlashRepo or= 'atom/atom'
    if not (userRepo = /^([^\/]+)\/([^\/]+)$/.exec userSlashRepo)
      atom.confirm
        message: 'Bug-Report Error:\n'
        detailedMessage: 'The GitHub Repo field should be of the form ' +
                         '"USER/REPO" where USER is the GitHub user and ' +
                         'REPO is the name of the repository.  This can ' +
                         'be found at the end of the URL for the repo.'
        buttons: ['OK']
      return

    token = @tokenInput.val().replace(/\s/g, '')
    saveToken = atom.config.get 'bug-report.saveTokenToFile'
    tokenPath = atom.config.get 'bug-report.filePathToSaveGithubPersonalApiToken'
    if not token and saveToken
      try
        token = fs.readFileSync tokenPath
      catch e
    if token
      if tokenPath and saveToken
        try
          fs.writeFileSync tokenPath, token
        catch e
          console.log 'bug-report: error writing token to path "' + tokenPath + '". ' + e.message
    else
      atom.confirm
        message: 'Bug-Report Error:\n'
        detailedMessage: 'You must enter a GitHub personal API token. ' +
                          'See https://github.com/blog/1509-personal-api-tokens.'
        buttons: ['OK']
      return

    @prePost.hide()
    @postMsg.css display:'inline-block'
    user = userRepo[1]
    repo = userRepo[2].replace(/\.git$/i, '')
    url  = "https://api.github.com/repos/#{user}/#{repo}/issues"
    options =
      url: url
      method: 'POST'
      headers:
        "User-Agent": "lee-bohm"
        Authorization: 'token ' + token
      json: true
      body:
        title: title
        body:  @editor.getText()

    request options, (err, res, body) =>
      if err or body?.message or res?.statusCode isnt 201
        console.log 'bug-report post error:',  {options, err, res, body}
        atom.confirm
          message: 'Bug-Report Error:\n'
          detailedMessage: 'Error posting to GitHub repo ' + url + '\n\n' +
                              (err?.message       ? '') + '  ' +
                              (body?.message      ? '') + '  ' +
                              (res?.statusCode    ? '') + '  ' +
                              (res?.statusMessage ? '') + '  ' +
                              (res?.body          ? '')
          buttons: ['OK']
        @prePost.css display:'inline-block'
        @postMsg.hide()
        @postPost.hide()
        return

      @postMsg.hide()
      @linkRepo.attr href:"https://github.com/#{user}/#{repo}"
      @linkRepo.text "#{user}/#{repo}"
      @linkIssue.attr href:body.html_url
      @linkIssue.text 'issue #' + body.number

      @postPost.css display:'inline-block'

  destroy: ->
    for disposable in @disposables then disposable.dispose()
    @unsubscribe()
    @detach()
