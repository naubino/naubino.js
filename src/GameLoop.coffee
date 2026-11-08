export class GameLoop

  constructor: (@layers = []) ->
    @animation_frame_id = null
    @running = false

  start: ->
    return if @running
    @running = true
    last = performance.now()
    tick = (now) =>
      return unless @running
      dt = now - last
      last = now
      layer.advance(dt) for layer in @layers
      @animation_frame_id = requestAnimationFrame tick if @running
    @animation_frame_id = requestAnimationFrame tick

  stop: ->
    return unless @running
    @running = false
    cancelAnimationFrame @animation_frame_id if @animation_frame_id?
    @animation_frame_id = null
