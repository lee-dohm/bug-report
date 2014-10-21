fs = require('fs')
os = require('os')
path = require('path')
plist = require('plist')
spawnSync = require('child_process').spawnSync
PanelView = require('./panel-view')

# Handles package activation and deactivation.
class BugReport
  configDefaults: 
    GithubLoginUserName: ''
    GithubPassword: ''
    orPathToFileWithUserAndPwd: 'none, file format is user:password.'
  
  # Public: Activates the package.
  activate: ->
    atom.workspaceView.command 'bug-report:open', =>
      @open()

  # Public: Opens the bug report.
  open: ->
    atom.workspace.open('Bug Report').then (editor) =>
      editor.setGrammar(atom.syntax.grammarForScopeName('source.gfm'))
      editor.setText """
        # Bug Report

        [Enter description here]

        * **Atom Version:** #{atom.getVersion()    }
        * **OS Version:**   #{@osMarketingVersion()}
        * **Misc Versions**
        #{@extendedVersion()}

        ## Repro Steps

        1. [First Step]
        2. [Second Step]
        3. [and so on...]

        **Expected:** [Enter expected behavior here]
        **Actual:** [Enter actual behavior here]

        ![Screenshot or GIF movie](url)

      """
      new PanelView editor

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

  # Private: Generates the marketing version text for Windows systems.
  #
  # Returns a {String} containing the version text.
  winMarketingVersion: ->
    info = spawnSync('systeminfo').stdout.toString()
    if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'

module.exports = new BugReport()
