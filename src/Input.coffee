import {KeyBindings} from './config/Keybindings'
import {Settings} from './config/Settings'

KEYS =
  SPACE: 32, ESC: 27
  C: 67, E: 69, F: 70, M: 77, S: 83

export class Input
  constructor: ({@events, @keyboard_target = window}) ->
    @keybindings = new KeyBindings()

    @keybindings.enable KEYS.SPACE, =>
      @events.commands.toggle.dispatch()
      console.log 'space'
    @keybindings.enable KEYS.ESC, => @events.commands.stop.dispatch()
    @keybindings.enable KEYS.F, -> Settings.toggle 'graphics.fullscreen'
    @keybindings.enable KEYS.E, -> Settings.toggle 'graphics.effects'
    @keybindings.enable KEYS.M, -> Settings.toggle 'audio.muted'
    @keybindings.enable KEYS.C, -> Settings.toggle 'graphics.draw_constraints'
    @keybindings.enable KEYS.S, -> Settings.toggle 'graphics.draw_constraints'

    @bound = false
    @onkeydown = (event) => @keybindings.keydown event
    @onkeyup = (event) => @keybindings.keyup event

  bind: ->
    return this if @bound

    @keyboard_target.addEventListener 'keydown', @onkeydown, false
    @keyboard_target.addEventListener 'keyup', @onkeyup, false
    @bound = true
    this

  unbind: ->
    return this unless @bound

    @keyboard_target.removeEventListener 'keydown', @onkeydown, false
    @keyboard_target.removeEventListener 'keyup', @onkeyup, false
    @keybindings.active_bindings = {}
    @bound = false
    this
