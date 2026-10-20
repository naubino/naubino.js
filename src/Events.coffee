import {Signal} from './core/Signal'

# One hub per application. Simulation-local signals stay on the game/world.
export class Events
  constructor: ->
    @input =
      pointer_start: new Signal
      pointer_move: new Signal
      pointer_end: new Signal
      two_finger_start: new Signal
      two_finger_end: new Signal
      two_finger_tap: new Signal

    @commands =
      play: new Signal
      pause: new Signal
      stop: new Signal
      toggle: new Signal

    @game =
      outcome: new Signal
      overflow_warning: new Signal
      basket_changed: new Signal

    @session =
      state_changed: new Signal

    @menu =
      button: new Signal
      focus: new Signal
      blur: new Signal
