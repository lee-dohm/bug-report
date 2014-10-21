
# lib/panel-view
        
{View}  = require 'atom'
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
        @div class:'label-repo', 'This has been posted to GitHub repo '
        @a   class:'link-repo'
        @div class:'label-issue', ' as issue '
        @a   class:'link-issue'
        @input
          outlet: 'closeBtn'
          class:  'close-btn btn'
          type:   'button'
          value:  'Close Bug Report'

  initialize: (@editor) ->
    @titleInput.focus()
    
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
      
    @subscribe @closeBtn, 'click', => @post()
      
    disposable = atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      console.log 'onDidChangeActivePaneItem', activeItem,
                  (activeItem is @editor), (activeItem is @)
      if activeItem in [@editor, @] then @show()
      else @hide()
    
    @disposables ?= []
    @disposables.push disposable

    atom.workspaceView.prependToBottom @
    
  getLogin: -> loginUser: 'mark-hahn', loginPwd: 'HJKuiobnm987'
    
  post: -> 
    title = @titleInput.val().replace(/^\s*|\s*$/g, '')
    if not title
      atom.confirm
        message: '-- Bug-Report Error: --\n'
        detailedMessage: 'The title field is empty.'
        buttons: ['OK']
      return
    
    userSlashRepo = @repoInput.val().replace(/\s/g, '')
    userSlashRepo or= 'mark-hahn/brtest'
    if not (userRepo = /^([^\/]+)\/([^\/]+)$/.exec userSlashRepo)
      atom.confirm
        message: '-- Bug-Report Error: --\n'
        detailedMessage: 'The GitHub Repo field should be of the form ' +
                         '"USER/REPO" where USER is the GitHub user and ' +
                         'REPO is the name of the repository.  This can ' +
                         'be found at the end of the URL for the repo.'
        buttons: ['OK']
      return
    
    @prePost.hide()
    @postMsg.show()
    
    {loginUser, loginPwd} = @getLogin()
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
          message: '-- Bug-Report Error: --\n'
          detailedMessage: 'Error posting to GitHub repo ' + url + '\n\n' +
                              (err?.message       ? '') + '  ' + 
                              (body?.message      ? '') + '  ' +
                              (res?.statusCode    ? '') + '  ' + 
                              (res?.statusMessage ? '') + '  ' + 
                              (res?.body          ? '')
          buttons: ['OK']
        @prePost.show()
        @postMsg.hide()
        @postPost.hide()
        return
        
      else console.log 'post success',  {options, err, res, body}
        
      @postMsg.hide()
      
      # fill post post links from res
      
      @postPost.show()

  destroy: ->
    for disposable in @disposables then disposable.dispose()
    @unsubscribe()
    @detach()
