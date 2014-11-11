{$}    = require 'atom'
moment = require 'moment'

logSize = 16
logSizeMask = 0xf
ignoredCommands =
  'show.bs.tooltip':   yes
  'shown.bs.tooltip':  yes
  'hide.bs.tooltip':   yes
  'hidden.bs.tooltip': yes

module.exports =
# Handles logging all of the Atom commands for the automatic repro steps feature.
class CommandLogger
  # Public: Creates a new logger.
  constructor: ->
    @initLog()

    atom.commands.onWillDispatch (event) =>
      {type: name, target: source} = event
      entry = @eventLog[@logIndex]

      if entry.name is name
        entry.count++
      else
        return if name of ignoredCommands

        @logIndex = (@logIndex+1) & logSizeMask
        entry = @eventLog[@logIndex]
        entry.name   = name
        entry.source = source
        entry.count  = 1
        entry.time   = Date.now()

  # Public: Formats the command log for the bug report.
  #
  # externalData - Other information to include in the log.
  #
  # Returns a {String} containing the Markdown for the report.
  getText: (externalData) ->
    text    = '```\n'
    dateFmt = 'm:ss.S'

    if externalData then lastTime = externalData.time
    else
      for ofs in [1..logSize]
        {name, time} = @eventLog[(@logIndex + ofs) & logSizeMask]
        lastTime = time
        if name is 'bug-report:open' then break

    for ofs in [1..logSize]
      {name, source, count, time} = @eventLog[(@logIndex + ofs) & logSizeMask]
      if time > lastTime then break
      if not name or lastTime - time >= 10*60*1000 then continue

      {nodeName, id, classList} = source
      srcText = nodeName.toLowerCase()
      if id then srcText += '#' + id
      if classList?.length
        # wtf -  classList.join is undefined!
        for klass in classList then srcText += '.' + klass

      text += switch
        when count < 10 then '  '
        when count < 100 then ' '
      text += (if count > 1 then count + 'x ' else '   ') +
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

  # Private: Initializes the log structure for speed.
  initLog: ->
    @logIndex = 0
    @eventLog = for i in [0...logSize]
      name: null
      count: 0
      time: null

  # Unused?
  destroy: ->
    if @originalTrigger? then $.fn.trigger = @originalTrigger
    @keymapMatchedSubscription?.off()
