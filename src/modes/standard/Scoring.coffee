import {Rule} from '../Rule'

export class Scoring extends Rule
  constructor: (game) ->
    super game
    @abort_controller = new AbortController
    {signal} = @abort_controller
    @game.events.naub_destroyed.add ((id) => @add_points @game.get_object(id).points_on_destroy()), signal
    @game.events.cycle_found.add ((list) => @calculate_points(list)), signal
    @game.points = 0
    @game.ex_naubs = 0
    @game.naubs_count = 0
    @game.duration = 0
    @game.events.score_changed.dispatch @game.points

  start: -> @game.begin_time ?= Date.now() unless @disposed

  dispose: ->
    super()
    @abort_controller.abort()

  check: ->
    return if @disposed
    @game.duration = Date.now() - @game.begin_time

  add_points: (points) ->
    return if @disposed
    @game.points += points
    @game.events.score_changed.dispatch @game.points

  calculate_points: (list) ->
    return if @disposed
    @game.ex_naubs += list.length
    max_grow = 3 # may be moved to settings some day
    factor = (max_grow-1) / @game.basket.max_naubs
    points = Math.floor(factor * list.length * list.length)
    @add_points points
    @game.events.chain_bonus.dispatch points if points > 0
