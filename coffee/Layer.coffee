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

  clear: ->
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



Naubino.Background = class Background extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @fps = 1000 / 5
    @drawing = true
    @basket_size = 170
    @basket_thickness = 4

  draw: () ->
    width = @canvas.width
    height = @canvas.height
    centerX = width/2
    centerY = height/2

    @ctx.clearRect(0, 0, width, height)

    @ctx.save()
    @ctx.beginPath()
    @ctx.arc centerX, centerY, @basket_size, 0, Math.PI*2, false

    @ctx.lineWidth = @basket_thickness
    @ctx.strokeStyle = 'rgba(0,0,0,0.5)'
    @ctx.stroke()
    @ctx.closePath()
    @ctx.restore()

  pulse: () ->
    default_fps = @fps
    @default_thickness = @basket_thickness
    @seed = 0
    @fps = 1000 / 40
    @start_timer()

    animate = =>
      @basket_thickness = Math.abs(Math.sin(@seed/10))  * 2 *   @default_thickness + @default_thickness
      @seed++

    stop = =>
      clearInterval @animation
      @fps = default_fps
      @basket_thickness = @default_thickness

    @animation = setInterval animate, 50
    setTimeout stop, 13000



    
  draw_marker: (x,y, color = 'black') ->
    @ctx.beginPath()
    @ctx.arc(x, y, 4, 0, 2 * Math.PI, false)
    @ctx.arc(x, y, 1, 0, 2 * Math.PI, false)
    @ctx.lineWidth = 1
    @ctx.strokeStyle = color
    @ctx.stroke()
    @ctx.closePath()

  draw_line: (x0, y0, x1 = @center.x, y1 = @center.y, color = 'black') ->

    @ctx.beginPath()
    @ctx.moveTo(x0, y0)
    @ctx.lineTo(x1, y1)
    @ctx.lineWidth = 2
    @ctx.strokeStyle = color
    @ctx.stroke()
    @ctx.closePath()

  draw_text: (x,y,text,color = 'black') ->
    @ctx.fillStyle = color
    @ctx.strokeStyle = color
    @ctx.textAlign = 'center'
    @ctx.font= "#{@size+4}px Helvetica"
    @ctx.fillText(text, x, y)


