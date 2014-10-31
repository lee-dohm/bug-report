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

Execute the `bug-report:open` command (`ctrl-alt-shift-B` by default) and a new Markdown file will be opened with important version information and fields for entering repro steps to help make great Atom bug reports.

Sample template:

```markdown
# Bug Report

[Enter description here]

* **Atom Version:** 0.139.0-4867e3e
* **OS Version:**   Mac OS X 10.10
* **Misc Versions**
    * apm  0.106.0
    * npm  1.4.4
    * node 0.10.32
    * python 2.7.6
    * git 2.0.3

## Repro Steps

1. [First Step]
2. [Second Step]
3. [and so on...]

**Expected:** [Enter expected behavior here]
**Actual:** [Enter actual behavior here]

![Screenshot or GIF movie](url)

---

This report was created in and posted from the Atom editor using the package
`bug-report` version 0.2.0.

```

### Automatic Posting to GitHub

When you create a new report, a pane will appear below the editor that enables posting your report as a GitHub Issue.

![Bug Report Post Form](https://raw.githubusercontent.com/lee-dohm/bug-report/master/images/form.gif)

For the Bug Report package to post on your behalf, you need to supply a GitHub API token. You may obtain one by [following the instructions](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) on GitHub. Your token will need at least the `repo` or `public repo` permission for posting to work.

Instructions:

1. Enter a title for the issue.
1. Specify the repository to post the Issue against as `user/reponame`.
    * This can be found in the URL for the repo, for example `https://github.com/lee-dohm/bug-report` would be `lee-dohm/bug-report`.
    * The default repository is for the core Atom editor at `atom/atom`. Only post there if you have checked that the problem isn't in a user-supplied package. Do this by running Atom in safe mode with `atom --safe`.
1. Enter your GitHub API token.
    * By default, this token is saved for future sessions. See the [Configuration](#configuration) section for more information.
1. Click `Post Issue`. It should only take a few seconds for Bug Report to post the Issue, after which the panel will show you a link to it.

Once you have posted you will not be able to post this same report again. If you wish, you may copy this report and open a new one to start over.

## Configuration

![Bug Report Configuration](https://raw.githubusercontent.com/lee-dohm/bug-report/master/images/configuration.png)

* `bug-report.saveToken`
    * `true` &mdash; Saves the token in the file specified by `tokenPath`
    * `false` &mdash; Does not save the token. It will need to be entered each time a report is posted on your behalf.
* `bug-report.tokenPath` &mdash; Path at which the API token will be saved if `saveToken` is enabled.

### Commands

* `bug-report:open` &mdash; Opens the bug report template with version information already included

### Keybinding

* `ctrl-shift-alt-b` &mdash; Executes `bug-report:open`

## Copyright

Copyright &copy; 2014 by [Lee Dohm](http://www.lee-dohm.com). See [LICENSE](https://github.com/lee-dohm/bug-report/blob/master/LICENSE.md) for details.
