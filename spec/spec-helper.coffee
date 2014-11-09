fs = require 'fs'
path = require 'path'

module.exports =
  # Public: Indents the text one Markdown level.
  #
  # Returns the text with each line indented by four spaces.
  indent: (text) ->
    ("    #{line}" for line in text.split("\n")).join("\n")

  # Public: Gets the text of the named fixture.
  #
  # Returns a {String} with the contents of the fixture.
  getFixture: (name) ->
    fs.readFileSync(path.join(__dirname, 'fixtures', name)).toString()
