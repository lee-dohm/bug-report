{$}    = require 'atom'
moment = require 'moment'

logSizeMask = 0xf
ignoredCommands =
  'show.bs.tooltip':   yes
  'shown.bs.tooltip':  yes
  'hide.bs.tooltip':   yes
  'hidden.bs.tooltip': yes

module.exports =
# Handles logging all of the Atom commands for the automatic repro steps feature.
class CommandLogger
  # Public: Format of time information.
  dateFmt: '-m:ss.S'

  # Public: Maximum size of the log.
  logSize: 16

  # Public: Creates a new logger.
  constructor: ->
    @initLog()
    atom.commands.onWillDispatch (event) =>
      @logEvent(event)

  # Public: Formats the command log for the bug report.
  #
  # externalData - Other information to include in the log.
  #
  # Returns a {String} containing the Markdown for the report.
  getText: (externalData) ->
    lines = []
    lastTime = null

    if externalData
      lastTime = externalData.time
    else
      @eachEvent (event) =>
        lastTime = event.time
        event.name is 'bug-report:open'

    @eachEvent (event) =>
      return true if event.time > lastTime
      return false if not event.name or lastTime - event.time >= 10*60*1000

      lines.push(@formatEvent(event, lastTime))

      return true if event.name is 'bug-report:open'

    if externalData
      lines.push("     #{@formatTime(0)} #{externalData.title}")

    @initLog()

    lines.unshift('```')
    lines.push('```')
    lines.join("\n")

  # Public: Gets the latest event from the log.
  #
  # Returns the event {Object}.
  latestEvent: ->
    @eventLog[@logIndex]

  # Public: Logs the command event.
  #
  # event - Command event to be logged.
  logEvent: (event) ->
    {type: name, target: source} = event
    return if name of ignoredCommands

    entry = @eventLog[@logIndex]

    if entry.name is name
      entry.count++
    else
      @logIndex = (@logIndex + 1) % @logSize
      entry = @eventLog[@logIndex]
      entry.name   = name
      entry.source = source
      entry.count  = 1
      entry.time   = Date.now()

  # Private: Executes a function on each event in chronological order.
  #
  # The function will receive an event object and the iteration will stop if the function returns a
  # truthy value.
  #
  # fn - {Function} to execute.
  eachEvent: (fn) ->
    for offset in [1..@logSize]
      stop = fn(@eventLog[(@logIndex + offset) % @logSize])
      break if stop

  # Private: Format the command count for reporting.
  #
  # Returns the {String} format of the command count.
  formatCount: (count) ->
    switch
      when count < 2 then '    '
      when count < 10 then "  #{count}x"
      when count < 100 then " #{count}x"

  # Private: Formats a command event for reporting.
  #
  # Returns the {String} format of the command event.
  formatEvent: (event, lastTime) ->
    "#{@formatCount(event.count)} #{@formatTime(lastTime - event.time)} #{event.name} #{@formatSource(event.source)}"

  # Private: Format the command source for reporting.
  #
  # Returns the {String} format of the command source.
  formatSource: (source) ->
    {nodeName, id, classList} = source
    nodeText = nodeName.toLowerCase()
    idText = if id then "##{id}" else ''
    classText = ''
    classText += ".#{klass}" for klass in classList if classList

    "(#{nodeText}#{idText}#{classText})"

  # Private: Format the command time for reporting.
  #
  # Returns the {String} format of the command time.
  formatTime: (time) ->
    moment(time).format(@dateFmt)

  # Private: Initializes the log structure for speed.
  initLog: ->
    @logIndex = 0
    @eventLog = for i in [0...@logSize]
      name: null
      count: 0
      time: null
