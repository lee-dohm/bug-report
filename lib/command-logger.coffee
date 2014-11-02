
{$}    = require 'atom'
moment = require 'moment'

logSize = 16
logSizeMask = 0xf
ignoredCommands = 
  'show.bs.tooltip':   yes
  'shown.bs.tooltip':  yes
  'hide.bs.tooltip':   yes
  'hidden.bs.tooltip': yes
  
prop =
  getOwnEnumerables: (obj) ->
    @_getPropertyNames obj, true, false, @_enumerable

  getOwnNonenumerables: (obj) ->
    @_getPropertyNames obj, true, false, @_notEnumerable

  getOwnEnumerablesAndNonenumerables: (obj) ->
    @_getPropertyNames obj, true, false, @_enumerableAndNotEnumerable

  getPrototypeEnumerables: (obj) ->
    @_getPropertyNames obj, false, true, @_enumerable

  getPrototypeNonenumerables: (obj) ->
    @_getPropertyNames obj, false, true, @_notEnumerable

  getPrototypeEnumerablesAndNonenumerables: (obj) ->
    @_getPropertyNames obj, false, true, @_enumerableAndNotEnumerable

  getOwnAndPrototypeEnumerables: (obj) ->
    @_getPropertyNames obj, true, true, @_enumerable

  getOwnAndPrototypeNonenumerables: (obj) ->
    @_getPropertyNames obj, true, true, @_notEnumerable

  getOwnAndPrototypeEnumerablesAndNonenumerables: (obj) ->
    @_getPropertyNames obj, true, true, @_enumerableAndNotEnumerable

  _enumerable: (obj, prop) ->
    obj.propertyIsEnumerable prop

  _notEnumerable: (obj, prop) ->
    not obj.propertyIsEnumerable(prop)

  _enumerableAndNotEnumerable: (obj, prop) ->
    true

  _getPropertyNames: getAllPropertyNames = (obj, iterateSelfBool, iteratePrototypeBool, includePropCb) ->
    props = []
    loop
      if iterateSelfBool
        Object.getOwnPropertyNames(obj).forEach (prop) ->
          props.push prop  if props.indexOf(prop) is -1 and includePropCb(obj, prop)
      break  unless iteratePrototypeBool
      iterateSelfBool = true
      break unless obj = Object.getPrototypeOf(obj)
    props
    

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
      if typeof e is 'string' then name = e
      else 
        name = e.type
        # the following doesn't work because the event object is weird
        # the console says e.target is defined but this code thinks it isn't
        # if (tgt = e.target)
        #   name += ' ' + tgt.nodeName
        #   if tgt.id then name += '#' + tgt.id
        #   if tgt.classList?.length then name += '.' + tgt.classList.join '.'
      
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
      
  getText: (cmdArgInfo) ->
    text    = '```\n'
    dateFmt = 'm:ss.S'
    if cmdArgInfo then lastTime = cmdArgInfo.time
    else
      for ofs in [1..logSize]
        {name, time} = @eventLog[(@logIdxPos + ofs) & logSizeMask]
        lastTime = time
        if name is 'bug-report:open' then break
    for ofs in [1..logSize]
      {name, count, time} = @eventLog[(@logIdxPos + ofs) & logSizeMask]
      if time > lastTime then break
      if name is 'empty' or lastTime - time >= 10*60*1000 then continue
      text += switch
        when count < 10 then '  '
        when count < 100 then ' '
      text += (if count > 1 then count + 'x ' else '   ') +
        '-' + moment(lastTime - time).format(dateFmt) +
        ' ' + name + '\n'
      if name is 'bug-report:open' then break
    if cmdArgInfo
      text += '     -' + moment(0).format(dateFmt) + 
              ' ' + cmdArgInfo.title + '\n'
    @initLog()
    text + '```'

  destroy: ->
    if @originalTrigger? then $.fn.trigger = @originalTrigger 
    @keymapMatchedSubscription?.off()

