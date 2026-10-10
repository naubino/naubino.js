export class Layer

  constructor: (@canvas) ->
    @name = "unnamed layer"

    @width   = @canvas.width
    @height  = @canvas.height
    @ctx     = @canvas.getContext('2d')
    @center  = -> new cp.v @width/2, @height/2
    @pointer = @center()

    @objects       = {}
    @objects_count = 0

    @fps       =   @default_fps       = Naubino.settings.graphics.fps
    @step_rate =   @default_step_rate = Naubino.settings.step_rate

    @actual_fps       = null
    @last_draw_time   = null
    @draw_accumulator = 0

    @actual_step_rate       = null
    @step_accumulator       = 0
    @step_rate_window_steps = 0
    @step_rate_window_time  = 0

    @fps_label_depth  = 0 # set by LayerManager so overlapping layers don't draw on top of each other

    @show()


  default_state_machine:
    initial: 'none'
    # not ready until runtime #events: Naubino.settings.events.default
    callbacks:
      error: (e, from, to, args, code, msg) -> console.error "#{@name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"


  setup_fsm: (special_events = []) ->
    @default_state_machine.target = this
    events = Naubino.settings.events.default.concat special_events
    @default_state_machine.events = events
    StateMachine.create @default_state_machine


  # describe all events here (except oninit)
  # describe all states elsewhere
  onplay: (e,f,t) ->
    @show()
    @start_drawing()
    @start_stepping()

  onpause: (e,f,t) ->
    @stop_stepping()
    @stop_drawing()

  onstop: (e,f,t) ->
    @stop_stepping()
    @stop_drawing()
    @clear()
    @clear_objects()

  #onchangestate: (e,f,t)-> console.info "#{@name} changed state #{e}: #{f} -> #{t}"
    #return true

  # stepping and drawing no longer own a timer each. a single shared
  # requestAnimationFrame loop (LayerManager#start_loop) calls @advance(dt)
  # on every layer, every frame, so all layers share one clock instead of
  # competing setInterval/rAF callbacks on the main thread.
  start_stepping: ->
    @step_accumulator = 0
    @stepping = yes

  stop_stepping: ->
    @stepping = no

  # layers that set @use_raf draw on every tick of the shared loop instead
  # of being throttled to @fps, i.e. as fast as the browser allows
  start_drawing: ->
    @draw_accumulator = 0
    @drawing = yes

  stop_drawing: ->
    @drawing = no
    @last_draw_time = null

  refresh_draw_rate: (fps = false) ->
    @fps = fps if fps
    @draw_accumulator = 0

  refresh_step_rate: (fps = false) ->
    @step_rate = fps if fps
    @step_accumulator = 0


  # overwrite these
  step: ->
  draw: ->


  # called every animation frame by LayerManager#start_loop with the real
  # time (ms) that passed since the previous frame. steps physics at a
  # fixed timestep (so simulation speed doesn't depend on frame rate) and
  # draws at @fps, or every frame if @use_raf is set.
  max_steps_per_frame = 5

  advance: (dt) ->
    @advance_stepping(dt) if @stepping
    @advance_drawing(dt)  if @drawing

  advance_stepping: (dt) ->
    @step_accumulator += dt
    step_interval = 1000 / @step_rate
    steps = 0
    while @step_accumulator >= step_interval and steps < max_steps_per_frame
      @step()
      @step_accumulator -= step_interval
      steps++
    @step_accumulator = 0 if steps == max_steps_per_frame # drop backlog, don't spiral

    @step_rate_window_steps += steps
    @step_rate_window_time  += dt
    if @step_rate_window_time >= 500
      @actual_step_rate = @step_rate_window_steps * 1000 / @step_rate_window_time
      @step_rate_window_steps = 0
      @step_rate_window_time  = 0

  advance_drawing: (dt) ->
    if @use_raf
      @draw()
      @draw_fps_overlay()
    else
      @draw_accumulator += dt
      draw_interval = 1000 / @fps
      if @draw_accumulator >= draw_interval
        @draw()
        @draw_fps_overlay()
        @draw_accumulator -= draw_interval
        @draw_accumulator = 0 if @draw_accumulator > draw_interval # drop backlog


  # measures the actual time between rendered frames and draws it, together
  # with the actual step rate, as a small label in the bottom right corner
  # of the layer's canvas
  draw_fps_overlay: ->
    return unless Naubino.settings.graphics.show_fps

    now = performance.now()
    if @last_draw_time?
      delta       = now - @last_draw_time
      instant_fps = 1000 / delta
      @actual_fps = if @actual_fps? then @actual_fps * 0.9 + instant_fps * 0.1 else instant_fps
    @last_draw_time = now

    return unless @actual_fps?

    line_height = 12
    y = @height - 4 - @fps_label_depth * line_height

    label = "#{@name}: #{Math.round(@actual_fps)} fps draw"
    label += " / #{Math.round(@actual_step_rate)} fps step" if @actual_step_rate?

    @ctx.save()
    @ctx.fillStyle    = "lime"
    @ctx.font         = "10px monospace"
    @ctx.textAlign    = "right"
    @ctx.textBaseline = "bottom"
    @ctx.fillText label, @width - 4, y
    @ctx.restore()


  resize_to: (width, height) ->
    @canvas.width  = width
    @canvas.height = height


  # scale: css px per game unit; backing store additionally scaled by dpr for crisp rendering
  scale_to: (scale) ->
    { width, height } = Naubino.settings.canvas
    dpr = window.devicePixelRatio or 1
    @canvas.style.width  = "#{width  * scale}px"
    @canvas.style.height = "#{height * scale}px"
    @canvas.width  = Math.round width  * scale * dpr
    @canvas.height = Math.round height * scale * dpr
    @ctx.setTransform scale * dpr, 0, 0, scale * dpr, 0, 0
    @clear()

  reset_resize: -> @scale_to 1

  fade_in: (callback = null) ->
    #console.log "fade in", @fadeloop
    @start_drawing()
    @canvas.style.opacity = 0.01
    @restore() if @backup_ctx?
    fade = =>
      if (@canvas.style.opacity *= 1.2) >= 1
        clearInterval @fadeloop
        #console.log "done"
        @show()
        if callback? and typeof callback == 'function'
          callback.call()
    clearInterval @fadeloop
    @fadeloop = setInterval( fade, 40 )

  fade_out: (callback = null)->
    #console.log "fade out", @fadeloop
    @start_drawing()
    @cache()
    fade = =>
      if (@canvas.style.opacity *= 0.8) <= 0.05
        clearInterval @fadeloop
        @hide()
        #@canvas.style.opacity = 1
        if callback? and typeof callback == 'function'
          callback.call()
          @stop_drawing()
    clearInterval @fadeloop
    @fadeloop = setInterval( fade, 70 )


  show: -> @canvas.style.opacity = 1

  hide: -> @canvas.style.opacity = 0

  clear: -> @ctx.clearRect(0, 0, @canvas.width, @canvas.height)

  cache: -> @backup_ctx = @ctx

  restore: -> @ctx = @backup_ctx


  # callback for mousedown signal
  click: (x, y) =>
    @mousedown = true
    [@pointer.x, @pointer.y] = [x,y]

    naub = @get_obj_in_pos @pointer
    if naub
      naub.focus()
      @focused_naub = naub

  # callback for mouseup signal
  unfocus: =>
    @mousedown = false
    if @focused_naub
      @focused_naub.unfocus()
    @focused_naub = null

  # callback for mousemove signal
  move_pointer: (x,y) =>
    [@pointer.x, @pointer.y] = [x,y] if @mousedown

  # housekeeping
  add_object: (obj)->
    obj.center = @center()
    ++@objects_count
    obj.number = @objects_count
    @objects[@objects_count] = obj
    @objects_count

  remove_obj: (id) ->
    obj = @get_object id
    delete @objects[id]


  get_object: (id)-> @objects[id]

  # asks all objects whether they have been hit by pointer
  get_obj_in_pos: (pos) ->
    for id, obj of @objects
      if obj.isHit(pos.x, pos.y) and obj.isClickable
        return obj

  clear_objects: -> @objects = {}

  for_each: (callback) ->
    callback(v) for k, v of @objects
    return

  one_after_another: (callback, callback2, list = Object.keys(@objects)) =>
    i = list.shift()
    if i?
      setTimeout (=> @one_after_another(callback,callback2,list)), 150
      callback(@get_object(i))
    else
      callback2()

  # visible utilites
  draw_point: (pos, color = "black") ->
    @ctx.beginPath()
    @ctx.arc(pos.x, pos.y, 4, 0, 2 * Math.PI, false)
    @ctx.arc(pos.x, pos.y, 1, 0, 2 * Math.PI, false)
    @ctx.lineWidth = 1
    @ctx.strokeStyle = color
    @ctx.stroke()
    @ctx.closePath()
