import {Rule} from '../Rule'

export class Scoring extends Rule
  constructor: (game) ->
    super game
    @game.events.naub_destroyed.add (id) => @add_points @game.get_object(id).points_on_destroy()
    @game.events.cycle_found.add (list) => @calculate_points(list)
    @game.points = 0
    @game.ex_naubs = 0
    @game.naubs_count = 0
    @game.duration = 0
    @game.events.score_changed.dispatch @game.points

  start: -> @game.begin_time ?= Date.now()

  check: ->
    @game.duration = Date.now() - @game.begin_time

  add_points: (points) ->
    @game.points += points
    @game.events.score_changed.dispatch @game.points

  calculate_points: (list) ->
    @game.ex_naubs += list.length
    max_grow = 3 # may be moved to settings some day
    factor = (max_grow-1) / @game.basket.max_naubs
    p = Math.floor(factor * list.length * list.length)
    @add_points p
    @game.events.chain_bonus.dispatch p if p > 0
