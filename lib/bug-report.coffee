fs = require 'fs'
os = require 'os'
path = require 'path'

spawnSync = undefined

defaultTokenPath =
  if process.platform is 'win32'
    path.join(process.env['USERPROFILE'], 'bug-report.token')
  else
    path.join(process.env['HOME'], '.bug-report.token')

# Public: Provides a system whereby the user can create and easily post high-quality bug reports.
#
# This system also allows other packages to report their bugs through the `bug-report` package.
class BugReport
  config:
    saveToken:
      type: 'boolean'
      default: true
    tokenPath:
      type: 'string'
      default: defaultTokenPath

  # Public: Activates the package.
  activate: ->
    CommandLogger = require './command-logger'
    @commandLogger = new CommandLogger
    openReport = (@externalData) =>
      @open()

    @commands = atom.commands.add 'atom-workspace',
      'bug-report:open': (event, externalData) ->
        if externalData and not externalData.body
          externalData =
            title: 'Error'
            time:   Date.now()
            body:   externalData

        openReport(externalData)

      'bug-report:insert-version-info': =>
        editor = atom.workspace.getActiveTextEditor()
        editor?.insertText(@versionSection())

  # Public: Deactivates the package.
  deactivate: ->
    @commands.dispose()
    @commandLogger = null

  # Public: Opens the bug report.
  open: ->
    atom.workspace.open('bug-report.md').then (editor) =>
      editor.setText """
      [Enter description here]

      ![Screenshot or GIF movie](url)

      #{@errorSection()}

      ## Repro Steps

      1. [First Step]
      2. [Second Step]
      3. [and so on...]

      **Expected:** [Enter expected behavior here]
      **Actual:** [Enter actual behavior here]

      ## Command History

      #{@commandLogger.getText(@externalData)}

      #{@versionSection()}

      ---

      <small>This report was created in and posted from the Atom editor using the package #{@packageVersionText()}.</small>
      """

      PanelView = require './panel-view'
      new PanelView(editor)

  # Private: Gets the `apm --version` information.
  #
  # Returns a {String} containing the output of `apm --version`.
  apmVersionInfo: ->
    spawnSync = require('child_process').spawnSync

    cmd = @findApm()
    spawnSync(cmd, ['--version']).stdout?.toString()

  # Private: Generates the apm version text.
  #
  # Returns a {String} containing the apm version info.
  apmVersionText: (info = @apmVersionInfo())->
    text = @stripAnsi(info.trim())
    ("    * #{line}" for line in text.split("\n")).join("\n")

  # Private: Extracts the Atom `package.json` information.
  #
  # Returns an empty {Object} if there was an error.
  # Returns an {Object} containing the package information.
  atomPackageInfo: ->
    try
      JSON.parse(fs.readFileSync(path.join(atom.getLoadSettings().resourcePath, 'package.json')))
    catch e
      {}

  # Private: Get atom-shell version number text.
  #
  # Returns a {String} containing the atom-shell version number.
  atomShellVersionText: (info = @atomPackageInfo())->
    info.atomShellVersion ? ''

  # Private: Creates the error information section if any was supplied.
  #
  # Returns a {String} containing the entire error information section.
  errorSection: ->
    if @externalData
      """
      ---
      #{@externalData.body}
      """
    else
      ''

  # Private: Finds the `apm` executable.
  #
  # Returns a {String} containing the absolute path to the executable.
  findApm: ->
    for location in ['apm/bin/apm', 'apm/node_modules/atom-package-manager/bin/apm']
      cmd = @safeScript(path.join(atom.packages.resourcePath, location))
      return cmd if fs.existsSync(cmd)

    @safeScript('apm')

  # Private: Gets the OS X version information.
  #
  # Returns an empty {Object} if an error occurred.
  # Returns an {Object} containing the following keys:
  #     * `ProductName` a {String} with the official name of the OS.
  #     * `ProductVersion` a {String} with the user-facing version number.
  macVersionInfo: ->
    try
      plist = require 'plist'

      text = fs.readFileSync('/System/Library/CoreServices/SystemVersion.plist', 'utf8')
      plist.parse(text)
    catch e
      {}

  # Private: Generates the marketing version text for OS X systems.
  #
  # Returns a {String} containing the version text.
  macVersionText: (info = @macVersionInfo()) ->
    return 'Unknown OS X version' unless info.ProductName and info.ProductVersion

    "#{info.ProductName} #{info.ProductVersion}"

  # Private: Generates the marketing version text for the OS.
  #
  # Returns a {String} containing the version text.
  osMarketingVersion: ->
    switch os.platform()
      when 'darwin' then @macVersionText()
      when 'win32' then @winMarketingVersion()
      else "#{os.platform()} #{os.release()}"

  # Private: Get the `bug-report` package information.
  #
  # Returns an {Object} containing the package metadata.
  packageVersionInfo: ->
    try
      JSON.parse(fs.readFileSync(path.join(__dirname, '../package.json')))
    catch e
      {}

  # Private: Get `bug-report` version number text.
  #
  # Returns a {String} containing the package name and version.
  packageVersionText: (info = @packageVersionInfo()) ->
    text = "`#{info.name ? 'bug-report'}`"
    text += " v#{info.version}" if info.version
    text

  # Private: Gets a safe script name for the current platform.
  #
  # Returns a {String} containing the correct name.
  safeScript: (text) ->
    text += '.cmd' if os.platform() is 'win32'
    text

  # Private: Strips ANSI escape codes from the given text.
  #
  # * `text` {String} of text to remove the ANSI escape codes from.
  #
  # Returns the {String} without the ANSI gobbledygook.
  stripAnsi: (text) ->
    text.replace(/\x1b[^m]*m/g, '')

  # Private: Builds a collection of version information.
  #
  # Returns a {String} containing the version text.
  versionSection: ->
    """
    ## Versions

    * **Atom:**       #{atom.getVersion()}
    * **Atom-Shell:** #{@atomShellVersionText()}
    * **OS:**         #{@osMarketingVersion()}
    * **Misc**
    #{@apmVersionText()}
    """

  # Private: Generates the marketing version text for Windows systems.
  #
  # Returns a {String} containing the version text.
  winMarketingVersion: ->
    spawnSync = require('child_process').spawnSync

    info = spawnSync('systeminfo').stdout.toString()
    if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'

module.exports = new BugReport()
