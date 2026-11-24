import {Rule} from '../Rule'

export class Scoring extends Rule
  constructor: (@world, @basket, naub_destroyed, cycle_found, @score_changed, @chain_bonus) ->
    super()
    @points = 0
    @cleared = 0
    @duration = 0
    @abort_controller = new AbortController
    {signal} = @abort_controller
    naub_destroyed.add ((id) => @add_points @world.get_object(id).points_on_destroy()), signal
    cycle_found.add ((list) => @calculate_points list), signal

  cleared_naubs: -> @cleared

  start: -> @begin_time ?= Date.now() unless @disposed

  dispose: ->
    super()
    @abort_controller.abort()

  check: ->
    return if @disposed
    @duration = Date.now() - @begin_time

  add_points: (points) ->
    return if @disposed
    @points += points
    @score_changed.dispatch @points

  calculate_points: (list) ->
    return if @disposed
    @cleared += list.length
    max_grow = 3
    factor = (max_grow - 1) / @basket.max_naubs()
    points = Math.floor(factor * list.length * list.length)
    @add_points points
    @chain_bonus.dispatch points if points > 0
