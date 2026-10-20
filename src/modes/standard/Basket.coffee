# Standard mode's capacity and geometry; other modes need not provide a basket.
export class Basket
  constructor: (@game, @max_naubs = 20) ->

  count: (margin = 0) ->
    count = []
    radius = @basket_size()
    for id, naub of @game.objects
      diff = @game.center()
      diff.sub naub.physical_body.p
      count.push naub if cp.v.len(diff) < radius * (1 + margin) - naub.size / 2
    count

  basket_size: ->
    return unless @max_naubs?
    naub_radius = Naubino.settings.naub.size / 2
    special_factor = .62
    Math.sqrt(@max_naubs * naub_radius * naub_radius / special_factor)

  current_count: -> @count(0.08).length

  capacity: -> 100 - @current_count() * 100 / @max_naubs
