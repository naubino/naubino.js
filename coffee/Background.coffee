define ["Layer"], (Layer) -> class Background extends Layer
  constructor: (canvas) ->
    super(canvas)
    @name = "background"
    @animation.name = "background.animation"

    @drawing = true
    @default_thickness = @basket_thickness = 4
    @ttl = 12
    @color = [0,0,0,0.5]
    @pulsating = off
    @seed = 0


  draw: () ->
    @draw_basket()

  # TODO ISSUE #38 Make every animation framerate aware
  step: (dt) ->
    if @pulsating
      @pulse()




  draw_basket: () ->
    width = @canvas.width
    height = @canvas.height
    centerX = width/2
    centerY = height/2
    @basket_size = Naubino.game.basket_size or 10

    @ctx.clearRect(0, 0, width, height)

    @ctx.save()
    @ctx.beginPath()
    @ctx.arc centerX, centerY, @basket_size+@basket_thickness/2, 0, Math.PI*2, false

    @ctx.lineWidth = @basket_thickness
    @ctx.strokeStyle = @color_to_rgba(@color)
    @ctx.stroke()
    @ctx.closePath()
    @ctx.restore()




  start_pulse: ->
    if @animation.current != "playing"
      @animation.play()
    @pulsating = on

  stop_pulse: ->
    @pulse_ends = true

  pulse: () ->
    if @pulse_ends and Math.abs(@default_thickness - @basket_thickness) < 1
      @pulsating = off
      @pulse_ends = false
      @basket_thickness = @default_thickness
      @color[0] = 0
      @color[3] = 0.5
      @animation.pause()

    @basket_thickness = Math.abs(Math.sin(@seed/@ttl))  * 2 *   @default_thickness + @default_thickness
    rot = Math.sin(@seed/@ttl)
    @color[0] = Math.abs(rot) * 200
    @color[3] = Math.abs(rot) * 0.5 + 0.5
    #@drawTextAlongArc("naub warning", -@seed/30)
    @seed++



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
