import {Mode} from './Mode'
import {StringShape} from '../game/Shapes'

# Debug playground: numbered balls, no basket, scoring, or losing.
export class DebugMode extends Mode
  id: 'debug'
  auto_start: yes
  game_config:
    creation_offset: -200

  bind: (game, events) ->
    unsubscribe_start = events.input.two_finger_start.add => @begin_spawning game
    unsubscribe_end = events.input.two_finger_end.add => @end_spawning()
    =>
      @end_spawning()
      unsubscribe_start()
      unsubscribe_end()

  reset: -> @end_spawning()

  init: (game) ->
    game.naub_replaced.add (number) -> game.graph.cycle_test(number)
    game.cycle_found.add (list) -> game.destroy_naubs(list)

  playing: (game, from) ->
    return unless from is 'stopped'
    game.factory.create_matching_naubs()
    @add_ball game for [0..5]

  begin_spawning: (game) ->
    @end_spawning()
    return unless game.current is 'playing'
    @spawn_pair game
    @gesture_timer = setInterval (=> @spawn_pair(game) if game.current is 'playing'), 300

  end_spawning: ->
    clearInterval @gesture_timer if @gesture_timer?
    @gesture_timer = null

  stop: -> @end_spawning()

  dispose: -> @end_spawning()

  spawn_pair: (game) ->
    color_count = Naubino.colors().length
    color_a = Math.floor(Math.random() * color_count)
    color_b = Math.floor(Math.random() * color_count)
    pos = new cp.v(game.width * (0.35 + Math.random() * 0.3), game.height * (0.35 + Math.random() * 0.3))
    first_number = game.world.objects_count
    game.factory.create_naub_pair pos, color_a, color_b
    for id, naub of game.objects when naub.number > first_number
      naub.life_rendering = yes
      naub.add_shape new StringShape naub.number, 'white'

  add_ball: (game, pos = game.factory.random_outside(), color = null) ->
    naub = game.factory.add_ball pos, color
    naub.life_rendering = yes
    naub.add_shape new StringShape naub.number, 'white'
    naub
