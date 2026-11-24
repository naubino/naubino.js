export class Basket
  constructor: (@world, @field, @loss_requested, @naub_size = 42, max_naubs = 20) ->
    @severity = 0
    @set_capacity max_naubs

  check: ->
    capacity = @capacity()
    critical_capacity = 45
    @severity = Math.max 0, (critical_capacity - capacity) / critical_capacity
    if capacity < 5
      @loss_requested.dispatch 'Naub Overflow'
      return
    return

  max_naubs: -> @maximum

  set_capacity: (@maximum) ->

  count: (margin = 0) ->
    count = []
    radius = @basket_size()
    for naub in @world.naubs()
      diff = @field.center()
      diff.sub naub.physical_body.p
      count.push naub if cp.v.len(diff) < radius * (1 + margin) - naub.size / 2
    count

  basket_size: ->
    naub_radius = @naub_size / 2
    special_factor = .62
    Math.sqrt(@maximum * naub_radius * naub_radius / special_factor)

  current_count: -> @count(0.08).length

  capacity: -> 100 - @current_count() * 100 / @maximum
