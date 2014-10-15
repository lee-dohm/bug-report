fs = require('fs')
os = require('os')
plist = require('plist')

# Handles package activation and deactivation.
class BugReport
  # Public: Activates the package.
  activate: ->
    atom.workspaceView.command 'bug-report:open', =>
      @open()

  # Public: Opens the bug report.
  open: ->
    atom.workspace.open().then (editor) =>
      editor.setGrammar(atom.syntax.grammarForScopeName('source.gfm'))
      editor.setText """
        # Bug Report

        [Enter description here]

        **Atom Version:** #{atom.getVersion()}
        **OS Version:** #{@osMarketingVersion()}

        ## Repro Steps

        1. [First Step]
        2. [Second Step]
        3. [and so on...]

        **Expected:** [Enter expected behavior here]
        **Actual:** [Enter actual behavior here]

        ![Screenshot or GIF movie](url)

      """

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
      else "#{os.platform()} #{os.release()}"

module.exports = new BugReport()
