class Naubino.Background extends Naubino.Layer
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
