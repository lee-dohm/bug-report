# Bug Report

Dumps relevant information into a nicely formatted Markdown file for reporting an Atom bug.

## Installation

The package can be installed by using the Settings screen and searching for `bug-report`.

It can also be installed from the command line with the command:

```bash
apm install bug-report
```

## Use

`bug-report` opens a new Markdown file with important version information and fields for inputting repro steps to help make great Atom bug reports.

Sample template:

```markdown
# Bug Report

[Enter description here]

**Atom Version:** 0.137.0-95ee29e
**OS Version:** darwin 13.4.0

## Repro Steps

1. [First Step]
2. [Second Step]
3. [and so on...]

**Expected:** [Enter expected behavior here]
**Actual:** [Enter actual behavior here]

![Screenshot or GIF movie](url)

```

## Configuration

### Commands

* `bug-report:open` &mdash; Opens the bug report template with version information already included

### Keybinding

* `ctrl-shift-alt-b` &mdash; Executes `bug-report:open`

## Copyright

Copyright &copy; 2014 by [Lee Dohm](http://www.lee-dohm.com). See [LICENSE](https://github.com/lee-dohm/bug-report/blob/master/LICENSE.md) for details.