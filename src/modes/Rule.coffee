# Game calls the hooks in list order.
#   start  entering playing
#   stop   leaving playing
#   check  every 300ms while playing
export class Rule
  constructor: (@game) ->

  start: ->
  stop:  ->
  check: ->
