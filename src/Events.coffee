import {Signal} from './core/Signal'

# One hub per application. Simulation-local signals stay on each game.
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




export class GameEvents
  constructor: ->

    @overflow_warning = new Signal
    @basket_changed = new Signal
    @level_changed = new Signal
    @chain_bonus = new Signal
    @score_changed = new Signal
    @state_changed = new Signal
    @lost = new Signal
    @finished = new Signal
    @naub_joined = new Signal
    @naub_destroyed = new Signal
    @naub_focused = new Signal
    @naub_replaced = new Signal
    @cycle_found = new Signal
