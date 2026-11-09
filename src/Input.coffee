import {KeyBindings} from './config/Keybindings'
import {Settings} from './config/Settings'

KEYS =
  SPACE: 32, ESC: 27
  C: 67, E: 69, F: 70, M: 77

export class Input
  constructor: ({@canvas, @viewport, @events, @keyboard_target = window}) ->
    @keybindings = new KeyBindings()

    @keybindings.enable KEYS.SPACE, => @events.commands.toggle.dispatch()
    @keybindings.enable KEYS.ESC, => @events.commands.stop.dispatch()
    @keybindings.enable KEYS.F, => Settings.toggle 'graphics.fullscreen'
    @keybindings.enable KEYS.E, => Settings.toggle 'graphics.effects'
    @keybindings.enable KEYS.M, => Settings.toggle 'audio.muted'
    @keybindings.enable KEYS.C, => Settings.toggle 'graphics.draw_constraints'

    @gesture = null
    @suppress_mouse_until = 0
    @bound = false

    @onkeydown = (event) => @keybindings.keydown event
    @onkeyup = (event) => @keybindings.keyup event
    @onmousedown = (event) => @dispatch('pointer_start', event) unless @emulated_mouse()
    @onmousemove = (event) => @dispatch('pointer_move', event) unless @emulated_mouse()
    @onmouseup = (event) => @dispatch('pointer_end', event) unless @emulated_mouse()
    @ontouchstart = (event) =>
      @suppress_emulated_mouse()
      if @gesture?
        @finish_gesture no
        event.preventDefault()
      else if event.touches.length is 2
        @dispatch 'pointer_end', event
        @gesture = start: Date.now(), eligible: yes, ended: no
        @events.input.two_finger_start.dispatch()
        event.preventDefault()
      else if event.touches.length > 2
        @dispatch 'pointer_end', event
        event.preventDefault()
      else
        @dispatch 'pointer_start', event
    @ontouchmove = (event) =>
      @suppress_emulated_mouse()
      if @gesture?
        @finish_gesture(no) unless event.touches.length is 2
        event.preventDefault()
      else
        @dispatch 'pointer_move', event
    @ontouchend = (event) =>
      @suppress_emulated_mouse()
      if @gesture?
        event.preventDefault()
        if event.type is 'touchcancel'
          @finish_gesture no
          @gesture = null
        else if event.touches.length is 0
          gesture = @gesture
          @finish_gesture yes unless gesture.ended
          tap = gesture.eligible and Date.now() - gesture.start < 400
          @gesture = null
          @events.input.two_finger_tap.dispatch() if tap
        else if event.touches.length isnt 2
          @finish_gesture(event.touches.length is 1)
      else
        @dispatch 'pointer_end', event

  bind: ->
    return this if @bound

    @keyboard_target.addEventListener 'keydown', @onkeydown, false
    @keyboard_target.addEventListener 'keyup', @onkeyup, false
    @canvas.addEventListener 'mousedown', @onmousedown, false
    @canvas.addEventListener 'mousemove', @onmousemove, false
    @canvas.addEventListener 'mouseup', @onmouseup, false
    @canvas.addEventListener 'mouseout', @onmouseup, false
    @canvas.addEventListener 'touchstart', @ontouchstart, passive: false
    @canvas.addEventListener 'touchmove', @ontouchmove, passive: false
    @canvas.addEventListener 'touchend', @ontouchend, passive: false
    @canvas.addEventListener 'touchcancel', @ontouchend, passive: false
    @unsubscribe_session = @events.session.state_changed.add (state) =>
      @cancel_gesture() unless state is 'playing'
    @bound = true
    this

  unbind: ->
    return this unless @bound

    @cancel_gesture()
    @unsubscribe_session?()
    @unsubscribe_session = null
    @keyboard_target.removeEventListener 'keydown', @onkeydown, false
    @keyboard_target.removeEventListener 'keyup', @onkeyup, false
    @canvas.removeEventListener 'mousedown', @onmousedown, false
    @canvas.removeEventListener 'mousemove', @onmousemove, false
    @canvas.removeEventListener 'mouseup', @onmouseup, false
    @canvas.removeEventListener 'mouseout', @onmouseup, false
    @canvas.removeEventListener 'touchstart', @ontouchstart, passive: false
    @canvas.removeEventListener 'touchmove', @ontouchmove, passive: false
    @canvas.removeEventListener 'touchend', @ontouchend, passive: false
    @canvas.removeEventListener 'touchcancel', @ontouchend, passive: false
    @keybindings.active_bindings = {}
    @bound = false
    this

  cancel_gesture: ->
    @finish_gesture no
    @gesture = null

  finish_gesture: (eligible = yes) ->
    return unless @gesture?
    @gesture.eligible = no unless eligible
    unless @gesture.ended
      @gesture.ended = yes
      @events.input.two_finger_end.dispatch()

  suppress_emulated_mouse: ->
    @suppress_mouse_until = Date.now() + 700

  emulated_mouse: -> Date.now() < @suppress_mouse_until

  dispatch: (name, event) ->
    point = event.changedTouches?[0] ? event
    {x, y} = @viewport.to_local point.clientX, point.clientY, @canvas
    event.preventDefault() if event.changedTouches?
    @events.input[name].dispatch x, y
