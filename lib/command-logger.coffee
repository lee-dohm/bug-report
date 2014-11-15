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
    dateFmt = 'm:ss.S'
    text    = '```\n'

    if externalData
      lastTime = externalData.time
    else
      for offset in [1..@logSize]
        {name, time} = @eventLog[(@logIndex + offset) % @logSize]
        lastTime = time
        break if name is 'bug-report:open'

    for offset in [1..@logSize]
      {name, source, count, time} = @eventLog[(@logIndex + offset) % @logSize]
      break if time > lastTime
      continue if not name or lastTime - time >= 10*60*1000

      srcText = @formatSource(source)
      countText = @formatCount(count)

      text += countText +
        '-' + moment(lastTime - time).format(dateFmt) +
        ' ' + name + ' (' + srcText + ')\n'
      if name is 'bug-report:open' then break

    if externalData
      text += '     -' + moment(0).format(dateFmt) +
              ' ' + externalData.title + '\n'

    @initLog()
    text + '```'

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

  # Private: Format the command count for reporting.
  #
  # Returns the {String} format of the command count.
  formatCount: (count) ->
    switch
      when count < 2 then '     '
      when count < 10 then "  #{count}x "
      when count < 100 then " #{count}x "

  # Private: Format the command source for reporting.
  #
  # Returns the {String} format of the command source.
  formatSource: (source) ->
    {nodeName, id, classList} = source
    nodeText = nodeName.toLowerCase()
    idText = if id then "##{id}" else ''
    classText = ''
    classText += ".#{klass}" for klass in classList if classList

    "#{nodeText}#{idText}#{classText}"

  # Private: Initializes the log structure for speed.
  initLog: ->
    @logIndex = 0
    @eventLog = for i in [0...@logSize]
      name: null
      count: 0
      time: null

  # Unused?
  destroy: ->
    if @originalTrigger? then $.fn.trigger = @originalTrigger
    @keymapMatchedSubscription?.off()
