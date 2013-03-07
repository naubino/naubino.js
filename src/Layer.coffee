define -> class Layer

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

  ### manage timers for drawing and stepping ###
  start_stepping: -> @step_loop = setInterval((=> @step()),  1000 / @step_rate) unless @step_loop?
  stop_stepping: ->
    clearInterval @step_loop
    @step_loop = null

  start_drawing: -> @draw_loop = setInterval (=> @draw()), 1000 / @fps  unless @draw_loop?
  stop_drawing: ->
    clearInterval @draw_loop
    @draw_loop = null

  refresh_draw_rate: (fps = false) ->
    @fps = fps if fps
    @stop_drawing()
    @start_drawing()

  refresh_step_rate: (fps = false) ->
    @step_rate = fps if fps
    @stop_drawing()
    @start_drawing()


  ### overwrite these ###
  step: ->
  draw: ->




  resize_by: (ratio) ->
    @canvas.width *= ratio
    @canvas.height*= ratio
    @ctx.scale ratio, ratio
    @clear()

  reset_resize: ->
    @ctx.setTransform 1,0,0,1,0,0
    @canvas.width  = Naubino.settings.canvas.width
    @canvas.height = Naubino.settings.canvas.height
    @clear()

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

  ### housekeeping ###
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
  
  ### visible utilites ###
  draw_point: (pos, color = "black") ->
    @ctx.beginPath()
    @ctx.arc(pos.x, pos.y, 4, 0, 2 * Math.PI, false)
    @ctx.arc(pos.x, pos.y, 1, 0, 2 * Math.PI, false)
    @ctx.lineWidth = 1
    @ctx.strokeStyle = color
    @ctx.stroke()
    @ctx.closePath()


