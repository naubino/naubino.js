import {Rule} from '../Rule'

# warns harder the fuller the basket gets, loses when it's nearly full
export class Overflow extends Rule

  check: ->
    return if @disposed or not @game.basket?
    capacity = @game.basket.capacity()
    critical_capacity = 45

    severity = Math.max 0, (critical_capacity - capacity) / critical_capacity
    @game.events.overflow_warning.dispatch severity

    if @game.basket.capacity() < 5
      @game.events.loss_requested.dispatch 'Naub Overflow'
      return
