define ["Layer"], (Layer) -> class Background extends Layer
  constructor: (canvas) ->
    super(canvas)
    @name = "background"
    @setup_fsm Naubino.settings.events.background
    @fps = @default_fps = 2

  set_defaults: ->
    @p_min= { color: [130,130,130], thick: 2 }
    @p_max= { color: Naubino.colors()[0], thick: 12 }

    @target = undefined
    @default_thickness = @basket_thickness = 4
    @color = @default_color = [100,100,100]
    @pulse_speed = 10
    @pulsating = off
    @pulse_ends = false


  onstopped: -> @set_defaults()

  onbeforepulse: ->
    @refresh_draw_rate 25

  onenterpulsing: ->
    @pulsating = on

  onleavepulsing: (e,f,t)->
    if e is 'stop_pulse'
      @pulse_ends = true
      return StateMachine.ASYNC
    else
      @pulsating = off
      return true

  onstop_pulse: ->
    @pulsating = off
    @refresh_draw_rate @default_fps

  draw: ->
    @clear()
    @draw_basket()

  draw_basket: () ->
    center = @center()
    @basket_size = Naubino.game.basket_size() ? 150


    @ctx.save()
    @ctx.beginPath()
    @ctx.arc center.x, center.y, @basket_size + @basket_thickness*2, 0, Math.PI*2, false
    #@ctx.arc center.x, center.y, @basket_size, 0, Math.PI*2, false

    @ctx.lineWidth = @basket_thickness
    @ctx.strokeStyle = Util.color_to_rgba(@color)
    @ctx.stroke()
    @ctx.closePath()
    @ctx.restore()



  step: ->

    if @pulsating
      @target ?= @p_max
      @basket_thickness = Util.interpolate @basket_thickness, @target.thick, @pulse_speed/100
      @color = Util.interpolate_color @color, @target.color, @pulse_speed/100

      if Math.abs(@basket_thickness - @target.thick) < 1
        if @target == @p_max
          @target = @p_min
        else
          @target = @p_max

    if @pulse_ends and Math.abs(@default_thickness - @basket_thickness) < 1
      @set_defaults()
      @transition()
      @draw()
      console.log "pulsing stopped"


  drawTextAlongArc: (str, rot = 0) ->
    angle = str.length * 0.1
    @ctx.save()
    c= @center()
    @ctx.translate(c.x, c.y)
    @ctx.rotate(-1 * angle / 2)
    @ctx.rotate(-1 * (angle / str.length) / 2 + rot)
    for char in str
      @ctx.rotate(angle / str.length)
      #@ctx.rotate(str.length * 0.01)
      @ctx.save()
      @ctx.translate(0, (-1 *@basket_size + 15) )
      @ctx.fillStyle = Util.color_to_rgba(@color)
      @ctx.textAlign = 'center'
      @ctx.font= "#{20}px Helvetica"
      @ctx.fillText(char, 0, 0)
      @ctx.restore()
    @ctx.restore()
    

  draw_line: (x0, y0, x1 = @center().x, y1 = @center().y, color = 'black') ->
    @ctx.beginPath()
    @ctx.moveTo(x0, y0)
    @ctx.lineTo(x1, y1)
    @ctx.lineWidth = 2
    @ctx.strokeStyle = color
    @ctx.stroke()
    @ctx.closePath()
