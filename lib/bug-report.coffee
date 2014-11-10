fs = require('fs')
os = require('os')
path = require('path')
plist = require('plist')
spawnSync = require('child_process').spawnSync
PanelView = require('./panel-view')
CommandLogger = require('./command-logger')

defaultTokenPath = if process.platform is 'win32'
                     path.join(process.env['USERPROFILE'], 'bug-report.token')
                   else
                     path.join(process.env['HOME'], '.bug-report.token')

# Handles package activation and deactivation.
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
    @commandLogger = new CommandLogger
    openReport = (@externalData) =>
      @open()

    @command = atom.commands.add 'atom-workspace', 'bug-report:open', (event, externalData) ->
      if externalData and not externalData.body
        externalData =
          title: 'Error'
          time:   Date.now()
          body:   externalData

      openReport(externalData)

  # Public: Deactivates the package.
  deactivate: ->
    @command.dispose()

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

      ## Versions

      * **Atom:**       #{atom.getVersion()}
      * **Atom-Shell:** #{@atomShellVersionText()}
      * **OS:**         #{@osMarketingVersion()}
      * **Misc**
      #{@apmVersionText()}

      ---

      <small>This report was created in and posted from the Atom editor using the package #{@packageVersionText()}.</small>
      """

      new PanelView(editor)

  # Private: Gets the `apm --version` information.
  #
  # Returns the output of `apm --version`.
  apmVersionInfo: ->
    cmd = path.join(atom.packages.resourcePath, 'apm/node_modules/atom-package-manager/bin/apm')
    cmd += '.cmd' if os.platform() is 'win32'
    spawnSync(cmd, ['--version']).stdout.toString()

  # Private: Generates the apm version text.
  #
  # Returns a {String} containing the apm version info.
  apmVersionText: (info = @apmVersionInfo())->
    text = @stripAnsi(info.trim())
    ("    * #{line}" for line in text.split("\n")).join("\n")

  # Private: Extracts the Atom `package.json` information.
  #
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

  # Private: Gets the OS X version information.
  #
  # Returns an {Object} containing the version info.
  macVersionInfo: ->
    try
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

  # Private: Get the package information.
  #
  # Returns the package metadata.
  packageVersionInfo: ->
    try
      JSON.parse(fs.readFileSync(path.join(__dirname, '../package.json')))
    catch e
      {}

  # Private: Get bug-report version number text.
  #
  # Returns the package name and version.
  packageVersionText: (info = @packageVersionInfo()) ->
    text = "`#{info.name ? 'bug-report'}`"
    text += " v#{info.version}" if info.version
    text

  # Private: Strips ANSI escape codes from the given text.
  #
  # Returns the text without the ANSI gobbledygook.
  stripAnsi: (text) ->
    text.replace(/\x1b[^m]*m/g, '')

  # Private: Generates the marketing version text for Windows systems.
  #
  # Returns a {String} containing the version text.
  winMarketingVersion: ->
    info = spawnSync('systeminfo').stdout.toString()
    if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'

module.exports = new BugReport()
