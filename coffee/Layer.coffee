define -> class Layer

  constructor: (@canvas) ->
    @width = @canvas.width
    @height = @canvas.height
    @center = new b2Vec2 @width/2, @height/2
    @ctx = @canvas.getContext('2d')
    @pointer = @center.Copy()
    @objects = {}
    @objects_count = 0


    # fragile calibration! don't fuck it up!
    @fps = 1000 / Naubino.settings.graphics.fps
    @dt = @fps/1500

    @show()

    @animation = {parent: this}

    StateMachine.create {
      target: @animation
      initial: 'stopped'
      events: Naubino.settings.layer_events
      callbacks:{
        # states (overwrite these)
        # place only onenterevent here
        # place onenterstate into the concrete implementation

        error: (e, from, to, args, code, msg) -> console.error "#{@name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"
        onbeforeplay:(e, f, t) -> @parent.start_timer()
        onbeforepause: (e,f,t) -> @parent.stop_timer()
        onbeforestop: (e,f,t) ->
          @parent.stop_timer()
          @parent.clear()

        onchangestate: (e,f,t)->
          #console.info "#{@name} changed state #{e}: #{f} -> #{t}"
          #return true
      }
    }


  ### overwrite these ###
  draw: ->
  step: (dt) ->



  ### managing objects ###
  add_object: (obj)->
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


  start_timer: => @animation.loop = setInterval(@mainloop, @fps )
  stop_timer: => clearInterval @animation.loop

  mainloop: ()=>
    @step(@dt)
    #@keybindings.step(@dt) #
    if @drawing
      @draw()


  show: -> @canvas.style.opacity = 1
  hide: -> @canvas.style.opacity = 0



  fade_in: (callback = null) ->
    console.log "fade in"
    @canvas.style.opacity = 0.01
    @restore() if @backup_ctx?
    fade = =>
      if (@canvas.style.opacity *= 1.2) >= 1
        clearInterval @fadeloop
        @show()
        if callback?
          callback.call()
    clearInterval @fadeloop
    console.log @fadeloop = setInterval( fade, 40 )


  fade_out: (callback = null)->
    console.log "fade out"
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
      

  clear: -> @canvas.width = @canvas.width
  cache: -> @backup_ctx = @ctx
  restore: ->
    @ctx = @backup_ctx
    unset = null




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
