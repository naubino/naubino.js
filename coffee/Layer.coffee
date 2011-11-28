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
    #console.log "fade in"
    @canvas.style.opacity = 0.01
    fade = =>
      if (@canvas.style.opacity *= 1.2) >= 1
        clearInterval @fadeloop
        @show()
    clearInterval @fadeloop
    console.log @fadeloop = setInterval( fade, 40 )
      

  fade_out: ->
    #console.log "fade out"
    fade = =>
      if (@canvas.style.opacity *= 0.8) <= 0.05
        clearInterval @fadeloop
        @hide()
        @clear()
        #@canvas.style.opacity = 1
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


<<<<<<< HEAD
Naubino.Overlay = class Overlay extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @fps = 1000 / 5

  fade_in: ->
    @canvas.style.opacity = 0.01
    fade = =>
      if (@canvas.style.opacity *= 1.2) >= 1
        clearInterval @fadeloop
        @canvas.style.opacity = 1
    @fadeloop = setInterval( fade, 40 )
      

  fade_out: ->
    @canvas.style.opacity = 1 # TODO why is opacity not set to 1 by default?
    fade = =>
      if (@canvas.style.opacity *= 0.8) <= 0.05
        clearInterval @fadeloop
        #@clear()
        #@canvas.style.opacity = 1
    @fadeloop = setInterval( fade, 40 )
      

  

  warning:(text) ->
    @ctx.fillStyle = color
    @ctx.strokeStyle = Naubino.colors. # XXX interrupted work here
    @ctx.textAlign = 'center'
    @ctx.font= "bold #{font_size}px Helvetica"
    @ctx.fillText(text, x,y)

  draw_text: (text,color = 'black', font_size = 15, x = @center.x, y = @center.y) ->
    lines = text.split("\n")
    y -= font_size * lines.length /2
    for line in lines
      @render_text(line, color, font_size, x, y)
      y += font_size
    return

  render_text: (text,color = 'black', font_size = 15, x = @center.x, y = @center.y) ->
    @ctx.fillStyle = color
    @ctx.strokeStyle = color
    @ctx.textAlign = 'center'
    @ctx.font= "#{font_size}px Helvetica"
    @ctx.fillText(text, x,y)
=======
>>>>>>> d4a75e309a43b3f2fc937ea7f8f2ba42a57fac8a


Naubino.Background = class Background extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @fps = 1000 / 5
    @drawing = true
    @basket_size = 170
    @default_thickness = @basket_thickness = 4
    @ttl = 12
    @color = [0,0,0,0.5]

  draw: () ->
    width = @canvas.width
    height = @canvas.height
    centerX = width/2
    centerY = height/2

    @ctx.clearRect(0, 0, width, height)

    @ctx.save()
    @ctx.beginPath()
    @ctx.arc centerX, centerY, @basket_size+@basket_thickness/2, 0, Math.PI*2, false

    @ctx.lineWidth = @basket_thickness
    @ctx.strokeStyle = @color_to_rgba(@color)
    @ctx.stroke()
    @ctx.closePath()
    @ctx.restore()

  stop_pulse: ->
    @pulse_ends = true

  pulse: () ->
    @default_fps = @fps
    @seed = 0
    @fps = 1000 / 20
    @start_timer()
    if @animation?
      clearInterval(@animation)

    animate = =>
      if @pulse_ends and Math.abs(@default_thickness - @basket_thickness) < 1
        clearInterval(@animation)
        delete @animation
        @pulse_ends = false
        @basket_thickness = @default_thickness
        @color[0] = 0
        @color[3] = 0.5

      @basket_thickness = Math.abs(Math.sin(@seed/@ttl))  * 2 *   @default_thickness + @default_thickness
      rot = Math.sin(@seed/@ttl)
      @color[0] = Math.abs(rot) * 200
      @color[3] = Math.abs(rot) * 0.5 + 0.5
      #@drawTextAlongArc("naub warning", -@seed/30)
      @seed++

    @animation = setInterval animate, 50


  drawTextAlongArc: (str, rot = 0) ->
    angle = str.length * 0.1 
    @ctx.save()
    @ctx.translate(@center.x, @center.y)
    @ctx.rotate(-1 * angle / 2)
    @ctx.rotate(-1 * (angle / str.length) / 2 + rot)
    for char in str
      @ctx.rotate(angle / str.length)
      #@ctx.rotate(str.length * 0.01)
      @ctx.save()
      @ctx.translate(0, (-1 *@basket_size + 15) )
      @ctx.fillStyle = @color_to_rgba(@color)
      @ctx.textAlign = 'center'
      @ctx.font= "#{20}px Helvetica"
      @ctx.fillText(char, 0, 0)
      @ctx.restore()
    @ctx.restore()
    
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


