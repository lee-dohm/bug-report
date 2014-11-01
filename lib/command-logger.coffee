
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
class CommandLogger
  
  initLog: ->
    @logIdxPos = 0
    @eventLog = for i in [0...logSize]
      name: 'empty'
      count: 0
      time: null
  
  constructor: ->
    @initLog()
    
    addEventToLog = (e) =>
      name = e.type ? e
      entry = @eventLog[@logIdxPos]
      if entry.name is name then entry.count++
      else
        if name of ignoredCommands then return
        @logIdxPos = (@logIdxPos+1) & logSizeMask
        entry = @eventLog[@logIdxPos]
        entry.name  = name
        entry.count = 1
        entry.time = Date.now()
      
    trigger = $.fn.trigger
    @originalTrigger = trigger
    $.fn.trigger = (e) ->
      addEventToLog e
      trigger.apply(this, arguments)

    @keymapMatchedSubscription = atom.keymap.on 'matched', ({binding}) =>
      addEventToLog binding.command
      
  getText: ->
    text    = '```\n'
    dateFmt = 'm:ss.S'
    for ofs in [1..logSize]
      {name, time} = @eventLog[(@logIdxPos + ofs) & logSizeMask]
      lastTime = time
      if name is 'bug-report:open' then break
    for ofs in [1..logSize]
      {name, count, time} = @eventLog[(@logIdxPos + ofs) & logSizeMask]
      if name is 'empty' or lastTime - time >= 10*60*1000 then continue
      text += switch
        when count < 10 then '  '
        when count < 100 then ' '
      text += (if count > 1 then count + 'x ' else '   ') +
        '-' + moment(lastTime - time).format(dateFmt) +
        ' ' + name + '\n'
      if name is 'bug-report:open' then break
    @initLog()
    text + '```'

  destroy: ->
    if @originalTrigger? then $.fn.trigger = @originalTrigger 
    @keymapMatchedSubscription?.off()

