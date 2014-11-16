{$}    = require 'atom'
moment = require 'moment'

ignoredCommands =
  'show.bs.tooltip':   yes
  'shown.bs.tooltip':  yes
  'hide.bs.tooltip':   yes
  'hidden.bs.tooltip': yes

module.exports =
# Handles logging all of the Atom commands for the automatic repro steps feature.
#
# It uses an array as a circular data structure to log only the most recent commands.
class CommandLogger
  # Public: Format of time information.
  dateFmt: '-m:ss.S'

  # Public: Maximum size of the log.
  logSize: 16

  # Public: Creates a new logger.
  constructor: ->
    @initLog()
    atom.commands.onWillDispatch (event) =>
      @logCommand(event)

  # Public: Formats the command log for the bug report.
  #
  # externalData - Other information to include in the log.
  #
  # Returns a {String} containing the Markdown for the report.
  getText: (externalData) ->
    lines = []
    lastTime = @calculateLastEventTime(externalData)

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

  # Public: Logs the command.
  #
  # command - Command to be logged.
  logCommand: (command) ->
    {type: name, target: source} = command
    return if name of ignoredCommands

    event = @latestEvent()

    if event.name is name
      event.count++
    else
      @logIndex = (@logIndex + 1) % @logSize
      event = @latestEvent()
      event.name   = name
      event.source = source
      event.count  = 1
      event.time   = Date.now()

  # Private: Calculates the time of the last event to be reported.
  #
  # data - Data from an external bug passed in from another package.
  #
  # Returns the {Date} of the last event that should be reported.
  calculateLastEventTime: (data) ->
    return data.time if data

    lastTime = null
    @eachEvent (event) ->
      lastTime = event.time
      return true if event.name is 'bug-report:open'

    lastTime

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
  # event - Event to be formatted.
  # lastTime - Time of the last event to report.
  #
  # Returns the {String} format of the command event.
  formatEvent: (event, lastTime) ->
    {count, time, name, source} = event
    "#{@formatCount(count)} #{@formatTime(lastTime - time)} #{name} #{@formatSource(source)}"

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
      source: null
      time: null
