import {Rule} from './Rule'
import {Util} from '../Util'

export class Overflow extends Rule

  check: ->
    capacity = @game.capacity()
    critical_capacity = 45

    # start warning
    if capacity < critical_capacity
      if Naubino.background.pulsating == off
        Naubino.background.pulse()
      Naubino.background.ttl = Math.floor capacity/2

      Naubino.background.pulse_speed = Util.interpolate(3,25,(critical_capacity-capacity)/critical_capacity)


    else if Naubino.background.pulsating == on
      Naubino.background.stop_pulse()
      Naubino.background.ttl = critical_capacity

    @game.loose() if @game.capacity() < 5
