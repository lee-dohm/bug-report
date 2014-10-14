os = require('os')

# Handles package activation and deactivation.
class BugReport
  activate: ->
    atom.workspaceView.command 'bug-report:open', =>
      @open()

  open: ->
    atom.workspace.open().then (editor) ->
      editor.setGrammar(atom.syntax.grammarForScopeName('source.gfm'))
      editor.setText """
        # Bug Report

        [Enter description here]

        **Atom Version:** #{atom.getVersion()}
        **OS Version:** #{os.platform()} #{os.release()}

        ## Repro Steps

        1. [First Step]
        2. [Second Step]
        3. [and so on...]

        **Expected:** [Enter expected behavior here]
        **Actual:** [Enter actual behavior here]

        ![Screenshot or GIF movie](url)

      """

module.exports = new BugReport()
