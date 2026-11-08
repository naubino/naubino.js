import {JoinPolicy} from '../game/JoinPolicy'

# what a Game is configured with instead of being subclassed
#   rules         once, from the Game constructor
#   init          every game init, after the rules' init
#   playing       entering playing, after the rules started
#   confirm_stop  false keeps the game running
export class Mode
  id: 'standard'
  version: 0
  auto_start: no
  game_config: {}
  physics_config: {}

  rules: (_game) -> []
  join_policy: (game) -> new JoinPolicy game
  init: (_game) ->
  reset: (_game) ->
  playing: (_game, _from) ->
  stop: (_game) ->
  dispose: (_game) ->
  result: (_game) -> null
  # Bind application events once; return a disposer, not a per-reset hook.
  bind: (_game, _events) -> ->
  confirm_stop: -> yes
