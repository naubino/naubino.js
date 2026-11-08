# what a Game is configured with instead of being subclassed
#   rules         once, from the Game constructor
#   init          every game init, after the rules' init
#   playing       entering playing, after the rules started
#   confirm_stop  false keeps the game running
export class Mode
  version: 0

  rules: (_game) -> []
  init: (_game) ->
  playing: (_game, _from) ->
  confirm_stop: -> yes
