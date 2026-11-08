# game logic a mode plugs in, Game calls the hooks in list order
#   init   every game init, signals and space are already fresh
#   start  entering playing
#   stop   leaving playing
#   check  every 300ms while playing
export class Rule
  constructor: (@game) ->

  init:  ->
  start: ->
  stop:  ->
  check: ->
