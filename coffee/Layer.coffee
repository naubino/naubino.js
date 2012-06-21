define -> class Layer

  constructor: (@canvas) ->
    @width = @canvas.width
    @height = @canvas.height
    @ctx = @canvas.getContext('2d')
    @pointer = new cp.v @width/2, @height/2
    @objects = {}
    @objects_count = 0


    @fps         = Naubino.settings.graphics.fps
    @physics_fps = Naubino.settings.physics.fps
    @dt          = Naubino.settings.physics.fps/1000 * Naubino.settings.physics.calming_const
    @time        = Date.now()

    @animation = {
      parent: this
      refresh_timer: (fps) =>
        @fps = fps
        @animation.stop_timer()
        @animation.start_timer()

      start_timer: =>
        #console.info @name, "start animation timer", @fps, "fps"
        @draw_loop = setInterval(@do_draw, 1000 / @fps ) unless @draw_loop?
      stop_timer: =>
        #console.info @name, "stop animation timer"
        clearInterval @draw_loop
        @draw_loop = null
    }

    StateMachine.create {
      target: @animation
      initial: 'stopped'
      events: Naubino.settings.layer_events
      callbacks:{
        # states (overwrite these)
        # place only onenterevent here
        # place onenterstate into the concrete implementation

        error: (e, from, to, args, code, msg) -> console.error "#{@name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"
        onbeforeplay:(e, f, t) -> @start_timer()
        onbeforepause: (e,f,t) -> @stop_timer()
        onbeforestop: (e,f,t) ->
          @stop_timer()
          @parent.clear()

        onchangestate: (e,f,t)->
          #console.info "#{@name} changed state #{e}: #{f} -> #{t}"
          #return true
      }
    }

    # set opacity
    # TODO perhaps have zepto do it
    @show()

  setup_physics: ->
    @GRABABLE_MASK_BIT = 1<<31
    @NOT_GRABABLE_MASK = ~@GRABABLE_MASK_BIT

    @space = new cp.Space() # so far so good
    @space.damping = Naubino.settings.physics.damping

    @mouseBody = new cp.Body(Infinity, Infinity)
    @mouseBody.name = "mouseBody"
    @mouseBody.p = cp.vzero

    @space.addBody @mouseBody


 
  add_walls: ->
    ws = 15 #wall_strength
    @walls = {}
    walls=
      ceil  : new cp.SegmentShape(@space.staticBody, cp.vzero, cp.v(@width, 0), ws)
      floor : new cp.SegmentShape(@space.staticBody, cp.v(0,@height), cp.v(@width, @height), ws)
      left  : new cp.SegmentShape(@space.staticBody, cp.vzero, cp.v(0,@height), ws)
      right : new cp.SegmentShape(@space.staticBody, cp.v(@width, 0), cp.v(@width ,@height), ws)

    for w, wall of walls
      @walls[w] = @space.addShape(wall)
      @walls[w].setElasticity(.01)
      @walls[w].setFriction(3)
      @walls[w].setLayers(@NOT_GRABABLE_MASK)
      @walls[w].group = 1



  step: ->
  step_space: ->
    @space.step(1/@physics_fps)

    # Move mouse body toward the mouse
    newPoint = cp.v.lerp(@mouseBody.p, @pointer, 0.25)
    @mouseBody.v = cp.v.mult(cp.v.sub(newPoint, @mouseBody.p), 60)
    @mouseBody.p = newPoint


  start_stepper: => @loop = setInterval((=> @step(@dt)),  1000 / @physics_fps )
  stop_stepper: => clearInterval @loop

  add_object: (obj)->
    #chipmunk
    if @space?
      @space.addShape obj.physical_shape if obj.physical_shape?
      @space.addBody obj.physical_body if obj.physical_body?

    obj.center = @center()
    ++@objects_count
    obj.number = @objects_count
    @objects[@objects_count] = obj
    @objects_count

  remove_obj: (id) ->
    obj = @get_object id
    if @space?
      @space.removeShape obj.physical_shape if obj.physical_shape?
      @space.removeBody obj.physical_body if obj.physical_body?
      for constraint in obj.constraints
        console.log constraint
        @space.removeConstraint constraint
    delete @objects[id]


  get_object: (id)-> @objects[id]
  clear_objects: -> @objects = {}

  for_each: (callback) ->
    for k, v of @objects
      callback(v)



  ### overwrite these ###
  draw_point: (pos, color = "black") ->
    @ctx.beginPath()
    @ctx.arc(pos.x, pos.y, 4, 0, 2 * Math.PI, false)
    @ctx.arc(pos.x, pos.y, 1, 0, 2 * Math.PI, false)
    @ctx.lineWidth = 1
    @ctx.strokeStyle = color
    @ctx.stroke()
    @ctx.closePath()

    
  draw: ->

  do_draw: => @draw()


  #visibility
  
  center: ->
    new cp.v @width/2, @height/2

  resize_by: (ratio) ->
    @canvas.width *= ratio
    @canvas.height*= ratio
    @ctx.scale ratio, ratio
    @draw()

  reset_resize: ->
    @ctx.setTransform 1,0,0,1,0,0
    @canvas.width  = Naubino.settings.canvas.width
    @canvas.height = Naubino.settings.canvas.height
    @draw()


  fade_in: (callback = null) ->
    console.log "fade in", @fadeloop
    @canvas.style.opacity = 0.01
    @restore() if @backup_ctx?
    fade = =>
      if (@canvas.style.opacity *= 1.2) >= 1
        clearInterval @fadeloop
        console.log "done"
        @show()
        if callback?
          callback.call()
    clearInterval @fadeloop
    console.log @fadeloop = setInterval( fade, 40 )

  fade_out: (callback = null)->
    console.log "fade out", @fadeloop
    @cache()
    fade = =>
      if (@canvas.style.opacity *= 0.8) <= 0.05
        clearInterval @fadeloop
        @hide()
        #@canvas.style.opacity = 1
        if callback?
          callback.call()
    clearInterval @fadeloop
    console.log @fadeloop = setInterval( fade, 40 )

  show: -> @canvas.style.opacity = 1
  hide: -> @canvas.style.opacity = 0

  clear: ->
    @ctx.clearRect(0, 0, @canvas.width, @canvas.height)

    #@ctx.beginPath()
    #@ctx.rect(0, 0, @canvas.width, @canvas.height)
    #@ctx.fillStyle = "rgba(255,255,255,)"
    #@ctx.fill()
    #@ctx.lineWidth = 5
    #@ctx.strokeStyle = 'black'
    #@ctx.stroke()

    #@canvas.width = @canvas.width
  cache: -> @backup_ctx = @ctx
  restore: -> @ctx = @backup_ctx



  # callback for mousedown signal
  click: (x, y) =>
    @mousedown = true
    [@pointer.x, @pointer.y] = [x,y]

    shape = @space.pointQueryFirst(@pointer, @GRABABLE_MASK_BIT, cp.NO_GROUP) if @space?
    naub = @get_object shape.naub_number if shape?
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
    if @mousedown
      [@pointer.x, @pointer.y] = [x,y]

  # asks all objects whether they have been hit by pointer
  get_obj_in_pos: (pos) ->
    if @space?
      shape = @space.pointQueryFirst(pos, @GRABABLE_MASK_BIT, cp.NO_GROUP)
      console.log shape
      for id, obj of @objects
        if obj.isHit(pos.x, pos.y) and obj.isClickable
          return obj


  ### utils ###
  color_to_rgba: (color, shift = 0) =>
    r = Math.round((color[0] + shift))
    g = Math.round((color[1] + shift))
    b = Math.round((color[2] + shift))
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"
