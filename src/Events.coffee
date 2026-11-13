import {Signal} from './core/Signal'

# One hub per application. Simulation-local signals stay on the game/world.
export class Events
  constructor: ->
    @input =
      two_finger_start: new Signal
      two_finger_end: new Signal
      two_finger_tap: new Signal

    @commands =
      play: new Signal
      pause: new Signal
      stop: new Signal
      toggle: new Signal


    @session =
      state_changed: new Signal

    @menu =
      button: new Signal
      focus: new Signal
      blur: new Signal

export class GameEvents
  constructor: ->
    @outcome = new Signal
    @overflow_warning = new Signal
    @basket_changed = new Signal
    @level_changed = new Signal
    @chain_bonus = new Signal
    @score_changed = new Signal
