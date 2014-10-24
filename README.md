# Bug Report

Creates a nicely formatted Markdown file for reporting an Atom bug and posts the issue to a GitHub repo.



![Image inserted by Atom editor package auto-host-markdown-image](http://i.imgur.com/Qqly4fh.gif?delhash=3twrbCTSe3osipc)



## Installation

The package can be installed by using the Settings screen and searching for `bug-report`.

It can also be installed from the command line with the command:

```bash
apm install bug-report
```

## Usage

* Enter the `bug-report:open` command (`ctrl-alt-shift-B` by default) and a new Markdown file will be opened with important version information and fields for inputting repro steps to help make great Atom bug reports.

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

* Also, a pane will appear below that enables posting your bug report as a GitHub repository issue directly to the issues section.



![Image inserted by Atom editor package auto-host-markdown-image](http://i.imgur.com/727WlFi.gif?delhash=bSoVlsJB963PZKL)

* Enter a title for the issue.  

* Next, specify the repository to post to as `user/reponame`.  This can be found in the url for the repo.  E.g https://github.com/lee-dohm/bug-report would be `lee-dohm/bug-report`.  

* The default repo is for the Atom editor `atom/atom`.  Only post there if you have checked that the problem isn't in a user-supplied package.  Do this by running Atom in safe mode with `atom --safe`.

* Finally, enter a GitHub personal API token.  You can get a token from GitHub in a few clicks [here](https://github.com/blog/1509-personal-api-tokens).  There is an option, enabled by default, that saves the token in a file location specified in the bug-report settings (see the next section). 

* Click on `Post Issue` and in a few seconds the panel will show you a link to the issue you just posted.  Once you have posted you will not be able to post this report again.  If you wish you may copy this report and open a new one to start over.


## Configuration

![Image inserted by Atom editor package auto-host-markdown-image](http://i.imgur.com/xnxByVq.gif?delhash=1E6Ovo5hYFWUUTH)

* If you enable saving to a file then bug-report will save the token you use to post an issue in the file path specified.  If you do not enable saving then the token won't be stored and you will need to enter a token each time you post an issue.

### Commands

* `bug-report:open` &mdash; Opens the bug report template with version information already included

### Keybinding

* `ctrl-shift-alt-b` &mdash; Executes `bug-report:open`

## Copyright

Copyright &copy; 2014 by [Lee Dohm](http://www.lee-dohm.com). See [LICENSE](https://github.com/lee-dohm/bug-report/blob/master/LICENSE.md) for details.
