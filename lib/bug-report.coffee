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
    atom.workspaceView.command 'bug-report:open', (e, @externalData) =>
      if @externalData and not @externalData.body
        @externalData = 
          title: 'Error'
          time:   Date.now()
          body:   @externalData
      @open()

  # Public: Opens the bug report.
  open: (errorInfo) ->
    atom.workspace.open('bug-report.md').then (editor) =>
      editor.setText """
        [Enter description here]

        * **Atom Version:**       #{atom.getVersion()}
        * **Atom-Shell Version:** #{@atomShellVersionText()}
        * **OS Version:**         #{@osMarketingVersion()}
        * **Misc Versions**
        #{@extendedVersion()}

        #{@errorSection()}

        ## Repro Steps

        1. [First Step]
        2. [Second Step]
        3. [and so on...]

        **Expected:** [Enter expected behavior here]
        **Actual:** [Enter actual behavior here]

        ## Command History:
        #{@commandLogger.getText(@externalData)}

        ![Screenshot or GIF movie](url)

        ---

        <small>This report was created in and posted from the Atom editor using the package `bug-report`#{@packageVersionText()}.</small>

      """
      new PanelView editor

  # Private: Get atom-shell version number text.
  atomShellVersionText: ->
    try
      JSON.parse(fs.readFileSync(path.join(atom.getLoadSettings().resourcePath, 'package.json'))).atomShellVersion
    catch e
      ""

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

  # Private: Generates the apm --version text on any platform
  #
  # Returns a {String} containing the extended version info.
  extendedVersion: ->
    cmd = path.join(atom.packages.resourcePath, 'apm/node_modules/atom-package-manager/bin/apm')
    cmd += '.cmd' if os.platform() is 'win32'
    '    * ' + spawnSync(cmd, ['--version']).stdout.toString()
                                .replace(/\[\d\dm/g, '')
                                .replace(/\n\s*$/, '')
                                .replace(/\n/g, '\n    * ')

  # Private: Generates the marketing version text for OS X systems.
  #
  # Returns a {String} containing the version text.
  macMarketingVersion: ->
    text = fs.readFileSync('/System/Library/CoreServices/SystemVersion.plist', 'utf8')
    versionInfo = plist.parse(text)
    "#{versionInfo['ProductName']} #{versionInfo['ProductVersion']}"

  # Private: Generates the marketing version text for the OS.
  #
  # Returns a {String} containing the version text.
  osMarketingVersion: ->
    switch os.platform()
      when 'darwin' then @macMarketingVersion()
      when 'win32' then @winMarketingVersion()
      else "#{os.platform()} #{os.release()}"

  # Private: Get bug-report version number text.
  packageVersionText: ->
    try
      ' version ' + JSON.parse(fs.readFileSync(path.join(__dirname, '../package.json'))).version
    catch e
      ""

  # Private: Generates the marketing version text for Windows systems.
  #
  # Returns a {String} containing the version text.
  winMarketingVersion: ->
    info = spawnSync('systeminfo').stdout.toString()
    if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'

module.exports = new BugReport()
