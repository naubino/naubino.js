import {Mode} from './Mode'
import {Factory} from '../game/Factory'
import {JoinPolicy} from '../game/JoinPolicy'
import {StringShape} from '../game/Shapes'
import {GestureSpawning} from './GestureSpawning'
import {ConnectionAnalysis} from './ConnectionAnalysis'

export class DebugMode extends Mode
  constructor: (config = {auto_start: yes, game: {creation_offset: -200}}) ->
    super config

  assemble: ({config, world, events, input, field, layer}) ->
    factory = new Factory layer, world, field, config
    decorate = (naub) ->
      naub.life_rendering = yes
      naub.add_shape new StringShape naub.number, 'white'
      naub
    playing = no
    disposed = no
    command_lifecycle =
      start: ->
        return if disposed
        playing = yes
        return
      stop: ->
        playing = no
        return
      dispose: ->
        disposed = yes
        playing = no
        return
    commands =
      pair: (first_color = 0, second_color = 1) ->
        return null unless playing
        naubs = factory.create_naub_pair null, first_color, second_color
        return (decorate naub for naub in naubs)
      triple: (first_color = 0, second_color = 1, third_color = 2) ->
        return null unless playing
        naubs = factory.create_naub_triple null, first_color, second_color, third_color
        return (decorate naub for naub in naubs)
      ball: (color = null) ->
        return null unless playing
        return decorate factory.add_ball factory.random_outside(), color
    population =
      activate: ->
        factory.create_matching_naubs()
        decorate factory.add_ball() for [0..5]
        return
    spawn_pair = ->
      color_count = Naubino.colors().palette().length
      first_color = Math.floor Math.random() * color_count
      second_color = Math.floor Math.random() * color_count
      bounds = field.view_bounds()
      position = new cp.v(
        bounds.left + (bounds.right - bounds.left) * (0.35 + Math.random() * 0.3),
        bounds.top + (bounds.bottom - bounds.top) * (0.35 + Math.random() * 0.3))
      decorate naub for naub in factory.create_naub_pair position, first_color, second_color
      return
    {two_finger_start, two_finger_end} = input
    gestures = new GestureSpawning two_finger_start, two_finger_end, spawn_pair
    connections = new ConnectionAnalysis events.join_added, events.join_removed,
      events.naub_replaced, events.cycle_found
    abort_controller = new AbortController
    events.cycle_found.add ((ids) -> world.destroy_naubs ids), abort_controller.signal
    cycle_handling =
      dispose: -> abort_controller.abort()
    rules = [command_lifecycle, population, gestures, connections, cycle_handling]
    {rules, connections, commands, join_policy: new JoinPolicy config.game}
