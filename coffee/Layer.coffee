Naubino.Layer = class Layer

  constructor: (@canvas) ->
    @width = @canvas.width
    @height = @canvas.height
    @center = new b2Vec2 @width/2, @height/2
    @ctx = @canvas.getContext('2d')
    @pointer = @center.Copy()
    @objs = {}
    @objs_count = 0

    @paused = true
    @fade_queue = new Naubino.Signal()

    # fragile calibration! don't fuck it up!
    
    @fps = 1000 / Naubino.Settings.fps
    @dt = @fps/1500

    @show()

  ### overwrite these ###
  draw: ->
  step: (dt) ->





  ### managing objects ###
  add_object: (obj)->
    obj.center = @center
    @objs_count++
    obj.number = @objs_count
    @objs[@objs_count] = obj

  get_object: (id)->
    @objs[id]

  remove_obj: (id) ->
    delete @objs[id]

  clear_objs: ->
    @objs = {}




  ## tempus fugit
  start_timer: ->
    if @paused
      @loop = setInterval(@mainloop, @fps )
      @paused = false

  stop_timer: ->
    clearInterval @loop
    @paused = true
  
  pause: ->
      if @paused
        @start_timer()
      else
        @stop_timer()

  mainloop: ()=>
    @step(@dt)
    #@keybindings.step(@dt) #
    if @drawing
      @draw()


  show: ->
    @canvas.style.opacity = 1

  hide: ->
    @canvas.style.opacity = 0

  fade_in: ->
    console.log "fade in"
    @canvas.style.opacity = 0.01
    fade = =>
      if (@canvas.style.opacity *= 1.2) >= 1
        clearInterval @fadeloop
        @show()
    clearInterval @fadeloop
    console.log @fadeloop = setInterval( fade, 40 )
      

  fade_out: (callback = null)->
    console.log "fade out"
    fade = =>
      if (@canvas.style.opacity *= 0.8) <= 0.05
        clearInterval @fadeloop
        @hide()
        @clear()
        #@canvas.style.opacity = 1
        if callback?
          callback.call()
    clearInterval @fadeloop
    console.log @fadeloop = setInterval( fade, 40 )
      



  ## can I touch this? (pointer interaction)
  click: (x, y) ->
    @mousedown = true
    [@pointer.x, @pointer.y] = [x,y]
    naub = @get_obj x, y
    if naub
      naub.focus()
      @focused_naub = naub

  unfocus: ->
    @mousedown = false
    if @focused_naub
      @focused_naub.unfocus()
    @focused_naub = null

  move_pointer: (x,y) ->
    if @mousedown
      [@pointer.x, @pointer.y] = [x,y]

  get_obj: (x, y) ->
    for id, obj of @objs
      if obj.isHit(x, y)
        return obj

  clear: ->
    @canvas.width = @canvas.width


  ### utils ###
  color_to_rgba: (color, shift = 0) =>
    r = Math.round((color[0] + shift))
    g = Math.round((color[1] + shift))
    b = Math.round((color[2] + shift))
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"
