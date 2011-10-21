Naubino.Menu = class Menu extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @canvas = Naubino.background

    @objs = {}
    @hovering = false
    @gravity = Naubino.Settings.gravity.menu

    @listener_size = @default_listener_size = 45

    # fragile calibration! don't fuck it up!
    @fps = 1000 / 20
    @dt = @fps/100
    
    @position = new b2Vec2(20,25)
    @draw_play_icon = (ctx) ->
      ctx.save()
      ctx.beginPath()
      ctx.fillStyle = "#ffffff"
      ctx.moveTo(-5,-5)
      ctx.lineTo(-5, 5)
      ctx.lineTo( 7, 0)
      ctx.lineTo(-5,-5)
      ctx.closePath()
      ctx.fill()
      ctx.restore()

    @draw_pause_icon = (ctx) ->
      ctx.save()
      ctx.fillStyle = "#ffffff"
      ctx.beginPath()
      ctx.rect(-5,-6,4,12)
      ctx.rect( 1,-6,4,12)
      ctx.closePath()
      ctx.fill()
      ctx.restore()



    @buttons = {
      play:
        function: -> Naubino.state_machine.menu_play.dispatch()
        content: (ctx) => @draw_play_icon(ctx)
        position: new b2Vec2(65,35)
      pause:
        function: -> Naubino.state_machine.menu_pause.dispatch()
        content: (ctx) => @draw_pause_icon(ctx)
        position: new b2Vec2(65,35)
        disabled: true
      help:
        function: -> Naubino.state_machine.menu_help.dispatch()
        content: (ctx) -> this.draw_string(ctx, '?')
        position: new b2Vec2(45,65)
      exit:
        function: -> Naubino.state_machine.menu_exit.dispatch()
        content: (ctx) -> this.draw_string(ctx, 'X')
        position: new b2Vec2(14,80)
      }

    @add_buttons()
    @start_timer()

  draw_play_icon: (ctx) ->

  mainloop: ()=>
    @draw()
    @draw_listener_region()
    @step()


  step: ->
    for name, naub of @objs
      naub.step (@dt)
      if @hovering
        naub.physics.gravitate()
      else
        naub.physics.gravitate(@position)


  ## can I touch this?

  move_pointer: (x,y) ->
    [@pointer.x, @pointer.y] = [x,y]


  add_buttons: ->

    @objs.main = new Naubino.Naub(this)
    @objs.main.draw = @draw_main_button
    @objs.main.physics.pos.Set(@position.x, @position.y)
    @objs.main.physics.attracted_to = @position.Copy()

    for name, attr of @buttons
      @objs[name] = new Naubino.Naub(this)
      @objs[name].physics.pos.Set attr.position.x, attr.position.y
      @objs[name].physics.attracted_to.Set attr.position.x, attr.position.y
      @objs[name].content = attr.content
      #@objs[name].shape.set_color_id 2
      @objs[name].shape.pre_render()
      @objs[name].focus = attr.function
      @objs[name].disable() if attr.disabled
      join = @objs[name].join_with( @objs.main, name )
      Naubino.graph.remove_join join

  switch_to_playing: ->
    console.log 'switching menu to playing mode'
    @objs.play.disable()
    @objs.pause.enable()

  switch_to_paused: ->
    console.log 'switching menu to paused mode'
    @objs.play.enable()
    @objs.pause.disable()


  draw: ->
    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
    @ctx.save()
    for name, naub of @objs
      naub.draw_joins(@ctx)if not naub.disabled
      naub.draw(@ctx) if not naub.disabled
    @objs.main.draw(@ctx)
    @objs.main.draw_joins()
    @draw_listener_region()
    @ctx.restore()


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

