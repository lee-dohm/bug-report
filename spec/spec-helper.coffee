fs = require 'fs'
path = require 'path'

module.exports =
  # Public: Gets the text of the named fixture.
  #
  # Returns a {String} with the contents of the fixture.
  getFixture: (name) ->
    fs.readFileSync(path.join(__dirname, 'fixtures', name)).toString()

  # Public: Indicates whether `item` has a command named `commandName`.
  #
  # Returns a {Boolean} indicating if it has the given command.
  hasCommand: (item, commandName) ->
    commands = atom.commands.findCommands(target: item.element)
    found = true for command in commands when command.name is commandName

    found

  # Public: Indents the text one Markdown level.
  #
  # Returns the text with each line indented by four spaces.
  indent: (text) ->
    ("    #{line}" for line in text.split("\n")).join("\n")

  # Public: Gets the number of milliseconds equal to `n` minutes.
  #
  # Returns the {Number} of milliseconds.
  minutes: (n) ->
    n * @seconds(60)

  # Public: Gets the number of milliseconds equal to `n` seconds.
  #
  # Returns the {Number} of milliseconds.
  seconds: (n) ->
    n * 1000
