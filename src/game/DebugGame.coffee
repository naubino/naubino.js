import {Game} from './Game'
import {StringShape} from './Shapes'
import {GestureSpawning} from '../modes/GestureSpawning'

export class DebugGame extends Game
  constructor: (args...) ->
    super args...
    population =
      activate: =>
        @factory.create_matching_naubs()
        @add_ball() for [0..5]
        return
    {two_finger_start, two_finger_end} = @app_events.input
    gestures = new GestureSpawning two_finger_start, two_finger_end, => @spawn_pair()
    @rules = [population, gestures]
    {signal} = @abort_controller
    @events.naub_replaced.add ((number) => @check_cycles number), signal
    @events.cycle_found.add ((list) => @destroy_naubs(list) unless @disposed), signal

  spawn_pair: ->
    return if @disposed
    color_count = Naubino.colors().palette().length
    color_a = Math.floor(Math.random() * color_count)
    color_b = Math.floor(Math.random() * color_count)
    position = new cp.v(@width * (0.35 + Math.random() * 0.3), @height * (0.35 + Math.random() * 0.3))
    first_number = @world.objects_count
    @factory.create_naub_pair position, color_a, color_b
    for number, naub of @objects when naub.number > first_number
      naub.life_rendering = yes
      naub.add_shape new StringShape naub.number, 'white'

  add_ball: (position = @factory.random_outside(), color = null) ->
    return if @disposed
    naub = @factory.add_ball position, color
    naub.life_rendering = yes
    naub.add_shape new StringShape naub.number, 'white'
    naub
