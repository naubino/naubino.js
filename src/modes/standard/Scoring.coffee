import {Rule} from '../Rule'

export class Scoring extends Rule

  init: ->
    @game.naub_destroyed.add (id)   => @game.points += @game.get_object(id).points_on_destroy()
    @game.cycle_found.add    (list) => @calculate_points(list)

    @game.points = 0
    @game.ex_naubs = 0
    @game.naubs_count = 0

  check: ->
    @game.duration = Date.now() - @game.begin_time

  calculate_points: (list) ->
    @game.ex_naubs += list.length
    max_grow = 3 # may be moved to settings some day
    factor = (max_grow-1) / @game.basket.max_naubs
    p = Math.floor(factor * list.length * list.length)
    @game.points += p
    #Naubino.overlay.fade_in_and_out_message ("\n\nChain Bonus "+p) if p > 0
    # Newlines prevent Level + Bonus messages overlapping
