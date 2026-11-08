import {KeyBindings} from './config/Keybindings'

export class Input
  constructor: ({@canvas, @viewport, @signals, @toggle, @stop, @keyboard_target = window}) ->
    @keybindings = new KeyBindings()
    @keybindings.enable 32, => @toggle()
    @keybindings.enable 27, => @stop()
    @gesture = null
    @bound = false

    @onkeydown = (event) => @keybindings.keydown event
    @onkeyup = (event) => @keybindings.keyup event
    @onmousedown = (event) => @dispatch 'mousedown', event
    @onmousemove = (event) => @dispatch 'mousemove', event
    @onmouseup = (event) => @dispatch 'mouseup', event
    @ontouchstart = (event) =>
      if event.touches.length is 2
        @onmouseup event
        @gesture = start: Date.now()
      else if @gesture?
        event.preventDefault()
      else
        @onmousedown event
    @ontouchmove = (event) =>
      if @gesture? then event.preventDefault() else @onmousemove event
    @ontouchend = (event) =>
      if @gesture?
        event.preventDefault()
        if event.touches.length is 0
          @toggle() if event.type is 'touchend' and Date.now() - @gesture.start < 400
          @gesture = null
      else
        @onmouseup event

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
    @bound = true
    this

  unbind: ->
    return this unless @bound

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
    @gesture = null
    @bound = false
    this

  dispatch: (name, event) ->
    point = event.changedTouches?[0] ? event
    {x, y} = @viewport.to_local point.clientX, point.clientY, @canvas
    event.preventDefault() if event.changedTouches?
    @signals[name].dispatch x, y
