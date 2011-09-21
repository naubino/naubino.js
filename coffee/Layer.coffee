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
    # fragile calibration! don't fuck it up!
    @fps = 1000 / Naubino.Settings.fps
    @dt = @fps/1500

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

  ## can I touch this? (pointer interaction)
  click: (x, y) ->
    @mousedown = true
    [@pointer.x, @pointer.y] = [x,y]
    naub = @get_obj x, y
    if naub and not naub.disabled
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




Naubino.Background = class Background extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @fps = 1000 / 10
    @drawing = true

  draw: () ->
    width = @canvas.width
    height = @canvas.height
    centerX = width/2
    centerY = height/2

    @ctx.clearRect(0, 0, width, height)

    @ctx.save()
    @ctx.beginPath()
    @ctx.arc centerX, centerY, 160, 0, Math.PI*2, false

    @ctx.lineWidth = 5
    @ctx.strokeStyle = 'rgba(0,0,0,0.5)'
    @ctx.stroke()
    @ctx.closePath()
    @ctx.restore()
    
