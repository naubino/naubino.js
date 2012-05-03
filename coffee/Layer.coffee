define -> class Layer

  constructor: (@canvas) ->
    @width = @canvas.width
    @height = @canvas.height
    @center = new b2Vec2 @width/2, @height/2
    @ctx = @canvas.getContext('2d')
    @pointer = @center.Copy()
    @objects = {}
    @objects_count = 0


    @fps         = Naubino.settings.graphics.fps
    @physics_fps = Naubino.settings.physics.fps
    @dt          = Naubino.settings.physics.fps/1000 * Naubino.settings.physics.calming_const
    @time        = Date.now()

    @animation = {
      parent: this
      start_timer: => @draw_loop = setInterval(@do_draw, 1000 / @fps )
      stop_timer: => clearInterval @draw_loop
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

    #chipmunk
    @remainder = 0
    @space = new cp.Space() # so far so good
    @space.gravity = cp.v 4,4


  # take some inspiration from chipmunk
  chip_step: ->
    #TODO checkout all that stepping rating crap in chipmunk demo
    @space.step(1/60)

    #TODO the pointer now has a mass



  ### managing objects ###
  add_object: (obj)->
    #chipmunk
    @space.addShape obj.physical_shape if obj.physical_shape?
    @space.addBody obj.physical_body if obj.physical_body?


    obj.center = @center
    @objects_count++
    obj.number = @objects_count
    @objects[@objects_count] = obj
    @objects_count

  get_object: (id)-> @objects[id]
  remove_obj: (id) -> delete @objects[id]
  clear_objects: -> @objects = {}

  for_each: (callback) ->
    for k, v of @objects
      callback(v)



  ### overwrite these ###
  draw: ->
  step: (dt) ->
    @chip_step()

  start_stepper: =>
    @loop = setInterval(@do_step, 1000 / @physics_fps )
  stop_stepper: =>
    clearInterval @loop

  do_step: () => @step(@dt)
  do_draw: => @draw() if @drawing


  #visibility

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

  clear: -> @canvas.width = @canvas.width
  cache: -> @backup_ctx = @ctx
  restore: -> @ctx = @backup_ctx




  # can I touch this? (pointer interaction)


  # callback for mousedown signal
  click: (x, y) =>
    @mousedown = true
    [@pointer.x, @pointer.y] = [x,y]
    naub = @get_obj x, y
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
  get_obj: (x, y) ->
    for id, obj of @objects
      if obj.isHit(x, y) and obj.isClickable
        return obj


  ### utils ###
  color_to_rgba: (color, shift = 0) =>
    r = Math.round((color[0] + shift))
    g = Math.round((color[1] + shift))
    b = Math.round((color[2] + shift))
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"
