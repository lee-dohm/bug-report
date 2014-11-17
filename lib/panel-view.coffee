{View} = require 'atom'
{CompositeDisposable} = require 'event-kit'
fs = require 'fs'
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

  # Public: Initializes the `PanelView`.
  initialize: (@editor) ->
    oldView?.destroy()
    oldView = this

    if @storedToken()
      @tokenInput.attr(placeholder: 'Default: stored in file')

    @disposables = new CompositeDisposable

    @disposables.add atom.commands.add '.title-input',
      'core:focus-next': =>
        @repoInput.focus()
      'core:confirm': =>
        @post()

    @disposables.add atom.commands.add '.repo-input',
      'core:focus-next': =>
        @tokenInput.focus()
      'core:confirm': =>
        @post()

    @disposables.add atom.commands.add '.token-input',
      'core:focus-next': =>
        @titleInput.focus()
      'core:confirm': =>
        @post()

    @subscribe @postBtn, 'click', => @post()
    @subscribe @closeBtn, 'click', =>
      @editor.destroy()
      @destroy()

    @disposables.add atom.workspace.onDidChangeActivePaneItem (activeItem) =>
      if activeItem in [@editor, this]
        @css(display: 'inline-block')
      else
        @hide()

    atom.workspaceView.prependToBottom this

  # Public: Destroys the PanelView.
  destroy: ->
    @disposables.dispose()
    @unsubscribe()
    @detach()

  # Public: Posts the bug report to GitHub.
  post: ->
    title = @validateTitle()
    return unless title

    [user, repo] = @validateRepo()
    return unless user and repo

    token = @validateToken()
    return unless token

    @postActual(title, user, repo, token)

  # Private: Displays a standardized error dialog box.
  #
  # detailed - A {String} containing the detailed error message to display.
  displayError: (detailed) ->
    atom.confirm
      message: 'Bug-Report Error:'
      detailedMessage: detailed
      buttons: ['OK']

  # Private: Performs the actual post to GitHub.
  #
  # title - Title of the bug to post.
  # user - User name of the GitHub repo owner.
  # repo - Repo name of the GitHub repository.
  # token - Current user's personal API token.
  postActual: (title, user, repo, token) ->
    @prePost.hide()
    @postMsg.css display:'inline-block'
    url  = "https://api.github.com/repos/#{user}/#{repo}/issues"
    options =
      url: url
      method: 'POST'
      headers:
        "User-Agent": "atom.io/packages/bug-report"
        Authorization: 'token ' + token
      json: true
      body:
        title: title
        body:  @editor.getText()

    request options, (err, res, body) =>
      if err or body?.message or res?.statusCode isnt 201
        detailedMessage =
          'Error posting to GitHub repo ' + url + '\n\n' +
            (err?.message       ? '') + '  ' +
            (body?.message      ? '') + '  ' +
            (res?.statusCode    ? '') + '  ' +
            (res?.statusMessage ? '') + '  ' +
            (res?.body          ? '')
        detailedMessage = detailedMessage.replace \
          'Not Found  404  Not Found  [object Object]', """
            A 404 error was returned when posting this issue.
            This is usually caused by an authentication problem
            such as a bad token. The token must have at least
            "repo" or "public repo" permission. See the
            instructions in the readme for obtaining a
            GitHub API Token.
          """
        atom.confirm
          message: 'Bug-Report Error:\n'
          detailedMessage: detailedMessage
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

  # Private: Determines if a GitHub security token has been saved.
  #
  # Returns a {Boolean} indicating whether a security token is available.
  storedToken: ->
    saveToken = atom.config.get('bug-report.saveToken')
    tokenPath = atom.config.get('bug-report.tokenPath')

    return undefined unless saveToken

    try
      fs.readFileSync(tokenPath).toString()
    catch e
      undefined

  # Private: Trims all leading and trailing whitespace in `str`.
  #
  # str - A {String} to be trimmed.
  #
  # Returns the trimmed version of the {String}.
  trim: (str) -> str.replace(/^\s*|\s*$/g, '')

  # Private: Validates the repo input text.
  #
  # Returns an {Array} containing the user and repo values.
  validateRepo: ->
    repoText = @repoInput.val().replace(/\s/g, '') or 'atom/atom'
    if not (match = /([^:\/]+)\/([^.\/]+)(\.git)?$/.exec repoText)
      @displayError 'The GitHub Repo field should be of the form ' +
                    '"USER/REPO" where USER is the GitHub user and ' +
                    'REPO is the name of the repository.  This can ' +
                    'be found at the end of the URL for the repo.'

      []
    else
      [match[1], match[2]]

  # Private: Validates the bug title.
  #
  # Returns a {String} containing the title or `undefined`.
  validateTitle: ->
    title = @trim @titleInput.val()
    if not title
      @displayError 'The title field is empty'

      undefined
    else
      title

  # Private: Validates the token input text.
  #
  # Returns a {String} containing the token or `undefined`.
  validateToken: ->
    token = @tokenInput.val().replace(/\s/g, '') or @storedToken()

    if token
      saveToken = atom.config.get('bug-report.saveToken')
      tokenPath = atom.config.get('bug-report.tokenPath')

      if saveToken and tokenPath
        try
          fs.writeFileSync(tokenPath, token)
        catch e
          console.log "bug-report: Error writing token to path #{tokenPath}. #{e.message}"

      token
    else
      @displayError 'You must enter a GitHub personal API token. ' +
        'See https://help.github.com/articles/creating-an-access-token-for-command-line-use/'

      undefined
