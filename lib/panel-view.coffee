
# lib/panel-view

{View}  = require 'atom'
fs      = require 'fs'
request = require 'request'

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
            placeholder: 'Default: mark-hahn/brtest'
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
    @subscribe @titleInput, 'keydown', (e) =>
      switch e.which
        when  9 then @repoInput.focus() # tab
        when 27 then @titleInput.val '' # esc           
        when 13 then @post()            # cr
        else return
      false
      
    @subscribe @repoInput, 'keydown',  (e) =>
      switch e.which
        when  9 then @titleInput.focus() # tab
        when 27 then @repoInput.val ''   # esc           
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
    
  userPwdErr: ->
    atom.confirm
      message: 'Bug-Report Error:\n'
      detailedMessage: 'Your GitHub username and password must be ' +
                       'set in the bug-report package settings. '   +
                       'These are missing or invalid.\n\n' +
                       'Instructions: ' +
                       'Open Atom settings (ctrl-,), enter bug-report ' +
                       'in the package search field, and click on bug-report. ' +
                       'The GitHub login settings fields User and Password will ' +
                       'appear on the right. ' +
                       'Fill in these fields or alternatively, ' +
                       'enter a path to a text file containing USER:PASSWORD.'
      buttons: ['OK']
      
  trim: (str) -> str.replace(/^\s*|\s*$/g, '')
  
  getLogin: -> 
    user = atom.config.get('bug-report.GithubLoginUserName')
    pwd  = atom.config.get('bug-report.GithubPassword')
    path = atom.config.get('bug-report.orPathToFileWithUserAndPwd')
    user = @trim user
    pwd  = @trim pwd
    if not user or not pwd
      try
        userPwd = fs.readFileSync(path, 'utf8')
        [user, pwd] = userPwd.split(':')
        user = @trim user
        pwd  = @trim pwd
        if not user or not pwd
          @userPwdErr()
          return {}
      catch e
        @userPwdErr()
        return{}
    loginUser: user, loginPwd: pwd
    
  post: -> 
    title = @trim @titleInput.val()
    if not title
      atom.confirm
        message: 'Bug-Report Error:\n'
        detailedMessage: 'The title field is empty.'
        buttons: ['OK']
      return
    
    userSlashRepo = @repoInput.val().replace(/\s/g, '')
    userSlashRepo or= 'mark-hahn/brtest'
    if not (userRepo = /^([^\/]+)\/([^\/]+)$/.exec userSlashRepo)
      atom.confirm
        message: 'Bug-Report Error:\n'
        detailedMessage: 'The GitHub Repo field should be of the form ' +
                         '"USER/REPO" where USER is the GitHub user and ' +
                         'REPO is the name of the repository.  This can ' +
                         'be found at the end of the URL for the repo.'
        buttons: ['OK']
      return
    
    {loginUser, loginPwd} = @getLogin()
    if loginUser
      @prePost.hide()
      @postMsg.css display:'inline-block'
      user = userRepo[1]
      repo = userRepo[2].replace(/\.git$/i, '')
      url  = "https://api.github.com/repos/#{user}/#{repo}/issues"
      options = 
        url: url
        method: 'POST'
        headers:
          "User-Agent": "mark-hahn"
          Authorization: 'Basic ' +
            new Buffer(loginUser + ':' + loginPwd).toString('base64')
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
