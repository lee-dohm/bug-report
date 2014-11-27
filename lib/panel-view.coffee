{View} = require 'atom'
{CompositeDisposable} = require 'event-kit'
fs = require 'fs'
request = require 'request'

oldView = null
errorMessages =
  404: "
    A 404 error was returned when posting this issue. This is usually caused by an authentication
    problem such as a bad token. The token must have at least \"repo\" or \"public repo\"
    permission. See the instructions in the README for obtaining a GitHub API Token.
  "

# Public: Panel placed at the bottom of the bug report editor pane that allows posting the report
#         directly to GitHub.
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

  # Public: Initializes the {PanelView}.
  #
  # * `editor` {TextEditor} instance within which to display the panel.
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

    atom.workspace.addBottomPanel
      item: this

  # Public: Destroys the {PanelView}.
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
  # * `detailed` {String} containing the detailed error message to display.
  displayError: (detailed) ->
    atom.confirm
      message: 'Bug-Report Error:'
      detailedMessage: detailed
      buttons: ['OK']

  # Private: Performs the actual post to GitHub.
  #
  # * `title` Title {String} of the bug to post.
  # * `user` User name {String} of the GitHub repository owner.
  # * `repo` Repo name {String} of the GitHub repository.
  # * `token` {String} containing the current user's personal API token.
  postActual: (title, user, repo, token) ->
    @prePost.hide()
    @postMsg.css display:'inline-block'
    url = "https://api.github.com/repos/#{user}/#{repo}/issues"
    options =
      url: url
      method: 'POST'
      headers:
        "User-Agent": "atom.io/packages/bug-report"
        Authorization: 'token ' + token
      json: true
      body:
        title: title
        body: @editor.getText()

    request options, (err, res, body) =>
      if err or body?.message or res?.statusCode isnt 201
        detailedMessage = errorMessages[res?.statusCode] ? @standardMessage(err, res, body)
        @displayError(detailedMessage)

        @prePost.css display: 'inline-block'
        @postMsg.hide()
        @postPost.hide()
        return

      @postMsg.hide()

      @linkRepo.attr(href:"https://github.com/#{user}/#{repo}")
      @linkRepo.text("#{user}/#{repo}")
      @linkIssue.attr(href: body.html_url)
      @linkIssue.text("Issue ##{body.number}")

      @postPost.css(display: 'inline-block')

  # Private: Formats the standard error message from the response information.
  #
  # * `err` Error information
  # * `res` HTTP response information
  # * `body` HTTP response body
  #
  # Returns a {String} containing the error message to display.
  standardMessage: (err, res, body) ->
    "
      Error posting to GitHub repo #{url}\n\n
      #{err?.message ? ''} - #{body?.message ? ''} - #{res?.statusCode ? ''} -
      #{res?.statusMessage ? ''} - #{res?.body ? ''}
    "

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
  # * `str` {String} to be trimmed.
  #
  # Returns the trimmed version of the {String}.
  trim: (str) -> str.replace(/^\s*|\s*$/g, '')

  # Private: Validates the repo input text.
  #
  # Returns an {Array} containing the user and repo values. It will be empty if there is a problem.
  validateRepo: ->
    repoText = @repoInput.val().replace(/\s/g, '') or 'atom/atom'
    if not (match = /([^:\/]+)\/([^.\/]+)(\.git)?$/.exec repoText)
      @displayError "The GitHub Repo field should be of the form \"USER/REPO\" where USER is the
                     GitHub user and REPO is the name of the repository. This can be found at the
                     end of the URL for the repo."

      []
    else
      [match[1], match[2]]

  # Private: Validates the bug title.
  #
  # Returns a {String} containing the title or `undefined` if there was a problem.
  validateTitle: ->
    title = @trim @titleInput.val()
    if not title
      @displayError 'The title field is empty'

      undefined
    else
      title

  # Private: Validates the token input text.
  #
  # Returns a {String} containing the token or `undefined` if there was a problem.
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
      @displayError 'You must enter a GitHub personal API token.
        See https://help.github.com/articles/creating-an-access-token-for-command-line-use/'

      undefined
