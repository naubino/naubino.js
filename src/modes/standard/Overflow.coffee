import {Rule} from '../Rule'

export class Overflow extends Rule
  constructor: (@basket, @overflow_warning, @loss_requested) ->
    super()

  check: ->
    return if @disposed
    capacity = @basket.capacity()
    critical_capacity = 45
    severity = Math.max 0, (critical_capacity - capacity) / critical_capacity
    @overflow_warning.dispatch severity
    if capacity < 5
      @loss_requested.dispatch 'Naub Overflow'
      return
