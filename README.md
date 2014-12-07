# Bug Report

Creates a nicely formatted Markdown file for reporting an Atom bug and posts the issue to a GitHub repo.

![Bug Report Workflow](https://raw.githubusercontent.com/lee-dohm/bug-report/master/images/workflow.gif)

## Installation

The package can be installed by using the Settings screen and searching for `bug-report`.

It can also be installed from the command line with the command:

```bash
apm install bug-report
```

## Usage

Execute the `bug-report:open` command (<kbd>Ctrl+Alt+Shift+B</kbd> by default) and a new Markdown file will be opened with fields for entering description, repro steps and images or movies, plus important diagnostic information to help make great Atom bug reports.

Sample bug report output:

    [Enter description here]

    ![Screenshot or GIF movie](url)

    ## Repro Steps

    1. [First Step]
    2. [Second Step]
    3. [and so on...]

    **Expected:** [Enter expected behavior here]
    **Actual:** [Enter actual behavior here]

    ## Command History

    ```
        -0:22.6 pane-container:active-pane-item-changed (atom-pane-container.panes)
        -0:22.6 active-buffer-changed (div.status-bar)
        -0:22.6 pane:active-item-changed (atom-pane.pane.active.with-minimap)
        -0:22.6 editor:detached (atom-text-editor.editor.editor-colors)
        -0:22.6 editor:will-be-removed (atom-text-editor.editor.editor-colors)
        -0:22.6 pane:item-removed (atom-pane.pane.active.with-minimap)
        -0:22.5 editor:detached (atom-text-editor.editor.editor-colors)
        -0:22.5 editor:will-be-removed (atom-text-editor.editor.editor-colors)
        -0:22.5 minimap:scroll (div.minimap)
        -0:00.0 bug-report:open (input.hidden-input)
    ```

    ## Versions

    * **Atom:**       0.153.0-7738472
    * **Atom-Shell:** 0.19.4
    * **OS:**         Mac OS X 10.10.1
    * **Misc**
    * apm  0.111.0
    * npm  1.4.4
    * node 0.10.33
    * python 2.7.6
    * git 1.9.3

    ---

    <small>This report was created in and posted from the Atom editor using the package `bug-report` v0.5.3.</small>

### Automatic Posting to GitHub

When you create a new report, a pane will appear below the editor that enables posting your report as a GitHub Issue.

![Bug Report Post Form](https://raw.githubusercontent.com/lee-dohm/bug-report/master/images/form.gif)

For the Bug Report package to post on your behalf, you need to supply a GitHub API token. You may obtain one by [following the instructions](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) on GitHub. Your token will need at least the `repo` or `public repo` permission for posting to work.

Instructions:

1. Enter a title for the issue.
1. Specify the repository to post the Issue against. It can be specified in any of the following ways:
    * As a `user/repo` string &mdash; `lee-dohm/bug-report`
    * As the URL to the repository's main GitHub page &mdash; `https://github.com/lee-dohm/bug-report`
    * As the HTTPS repository remote &mdash; `https://github.com/lee-dohm/bug-report.git`
    * As the SSH repository remote &mdash; `git@github.com:lee-dohm/bug-report.git`
    * **Note:** The default repository is for the core Atom editor at `atom/atom`. Only post there if you have checked that the problem isn't in a user-supplied package. Do this by running Atom in safe mode with `atom --safe`.
1. Enter your GitHub API token.
    * By default, this token is saved for future sessions. See the [Configuration](#configuration) section for more information.
1. Click `Post Issue`. It should only take a few seconds for Bug Report to post the Issue, after which the panel will show you a link to it.

Once you have posted you will not be able to post this same report again. If you wish, you may copy this report and open a new one to start over.

## Configuration

![Bug Report Configuration](https://raw.githubusercontent.com/lee-dohm/bug-report/master/images/configuration.png)

* `bug-report.saveToken`
    * `true` &mdash; Saves the token in the file specified by `tokenPath`. Also uses the token from the file, if it exists.
    * `false` &mdash; Does not save the token nor does it use it if the file at `tokenPath` exists. It will need to be entered each time a report is posted on your behalf.
* `bug-report.tokenPath` &mdash; Path at which the API token will be saved to and loaded from if `saveToken` is enabled.

### Commands

* `bug-report:open` &mdash; Opens the bug report template with version information already included
* `bug-report:insert-version-info` &mdash; Inserts the formatted version information into the active text editor

### Keybinding

* `ctrl-shift-alt-b` &mdash; Executes `bug-report:open`

## Services

* `bug-report`
    * `openReport` &mdash; Opens a bug report

## Copyright

Copyright &copy; 2014 by [Lee Dohm](http://www.lee-dohm.com). See [LICENSE](https://github.com/lee-dohm/bug-report/blob/master/LICENSE.md) for details.
