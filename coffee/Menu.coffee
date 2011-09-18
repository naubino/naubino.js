Naubino.Menu = class Menu extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @canvas = Naubino.background
    @position = new b2Vec2(20,25)
    @buttons = {}
    @pointer
    @paused = true
    @pointer = @center
    @hovering = false
    @listener_size = @default_listener_size = 45

    # fragile calibration! don't fuck it up!
    @fps = 1000 / 20
    @dt = @fps/100
    
    @add_buttons()
    @pause()

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


  add_buttons: ->

    @buttons.main = new Naubino.Naub(this)
    @buttons.main.draw = @draw_main_button
    @buttons.main.physics.pos.Set(@position.x, @position.y)
    @buttons.main.physics.attracted_to= @position.Copy()

    @buttons.play = new Naubino.Naub(this)
    @buttons.play.physics.pos.Set(70,30)
    @buttons.play.physics.attracted_to.Set(70,30)
    @buttons.play.focus = -> Naubino.game.pause()

    @buttons.restart = new Naubino.Naub(this)
    @buttons.restart.physics.pos.Set(55,65)
    @buttons.restart.physics.attracted_to.Set(55,65)
    @buttons.restart.focus = -> console.log "restarting"

    @buttons.main.join_with(@buttons.play)
    @buttons.main.join_with(@buttons.restart)

  mainloop: ()=>
    @draw()
    @draw_listener_region()
    @step()

  step: ->
    for name, naub of @buttons
      naub.step (@dt)
      if @hovering
        naub.physics.gravitate()
      else
        naub.physics.gravitate(@position)


  draw_main_button: (ctx) ->
    cube_size = 80

    ctx.save()
    ctx.translate(@physics.pos.x, @physics.pos.y)
    ctx.rotate(Math.PI/6)
    ctx.beginPath()
    ctx.rect( -cube_size/4, -cube_size/4, cube_size/2, cube_size/2)
    ctx.fillStyle = @shape.color_to_rgba @shape.style.fill
    ctx.fill()
    ctx.closePath()
    ctx.restore()

    ctx.save()
    ctx.translate(@physics.pos.x, @physics.pos.y)
    ctx.fillStyle = 'white'
    ctx.textAlign = 'center'
    ctx.font= 'bold 33px Helvetica'
    ctx.fillText(Naubino.game.points, 0,10, cube_size)
    ctx.restore()

  draw_listener_region: ->
    @ctx.save()
    @ctx.beginPath()
    @ctx.arc 0, 15, @listener_size, 0, Math.PI*2, true
    if @ctx.isPointInPath(@pointer.x,@pointer.y)
      unless @hovering
        @hovering =  true
        @listener_size = 90
    else if @hovering
      @hovering = false
      @listener_size = @default_listener_size
    #@ctx.stroke()
    @ctx.closePath()
    @ctx.restore()


  draw: ->
    @ctx.clearRect(0, 0, Naubino.world_canvas.width, Naubino.world_canvas.height)
    @ctx.save()
    @buttons.main.draw_joins(@ctx)
    @buttons.play.draw(@ctx)
    @buttons.restart.draw(@ctx)
    @buttons.main.draw(@ctx)
    @ctx.restore()

  ## can I touch this?
  click: (x, y) ->
    @mousedown = true
    button = @get_obj x, y
    if button
      button.focus()

  get_obj: (x, y) ->
    for name, naub of @buttons
      if naub.isHit(x, y)
        return naub

  move_pointer: (x,y) ->
    [@pointer.x, @pointer.y] = [x,y]

