import {Rule} from './Rule'

# warns harder the fuller the basket gets, loses when it's nearly full
export class Overflow extends Rule

  check: ->
    capacity = @game.capacity()
    critical_capacity = 45

    severity = if capacity < critical_capacity
      (critical_capacity-capacity)/critical_capacity
    else
      0
    @game.overflow_warning.dispatch severity

    @game.loose() if @game.capacity() < 5
