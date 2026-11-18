import {Game} from './Game'
import {StringShape} from './Shapes'

export class DebugGame extends Game
  constructor: (args...) ->
    super args...
    @gesture_timer = null
    @subscriptions = @subscriptions.concat [
      @app_events.input.two_finger_start.add => @begin_spawning()
      @app_events.input.two_finger_end.add => @end_spawning()
      @events.naub_replaced.add (number) => @check_cycles number
      @events.cycle_found.add (list) =>
        @destroy_naubs(list) unless @disposed
    ]

  onplaying: (event, from, to) ->
    super event, from, to
    return if @disposed or from isnt 'ready'
    @factory.create_matching_naubs()
    @add_ball() for [0..5]

  onleaveplaying: ->
    @end_spawning()
    super()

  dispose: ->
    @end_spawning()
    super()

  begin_spawning: ->
    @end_spawning()
    return if @disposed or @current isnt 'playing'
    @spawn_pair()
    @gesture_timer = setInterval (=>
      @spawn_pair() unless @disposed or @current isnt 'playing'
    ), 300

  end_spawning: ->
    clearInterval @gesture_timer if @gesture_timer?
    @gesture_timer = null

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
