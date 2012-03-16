# TODO clean up menu code
class Naubino.Menu extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @name = "menu"
    @animation.name = "menu.animation"

    @objects = {}
    @hovering = false
    @gravity = Naubino.Settings.gravity.menu

    @listener_size = @default_listener_size = 45
    Naubino.mousemove.add @move_pointer
    Naubino.mousedown.add @click
    Naubino.naub_destroyed.add -> Naubino.menu.objects.main.shape.pre_render()
    Naubino.menu_button.active = false
   
    @position = new b2Vec2(20,25)
    @cube_size = 45
    
    StateMachine.create {
      target:this
      events: Naubino.Settings.events
    }

    ### definition of each button
    TODO: position should be dynamic
    ###

    # fragile calibration! don't fuck it up!
    @fps = 1000 / 20
    @dt = @fps/100


  buttons:
    play:
      function: ->
        console.time("init_play")
        Naubino.play()
      position: new b2Vec2(65,35)
      content: (ctx) ->
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
    pause:
      function: -> Naubino.pause()
      position: new b2Vec2(65,35)
      disabled: true
      content: (ctx) ->
        ctx.save()
        ctx.fillStyle = "#ffffff"
        ctx.beginPath()
        ctx.rect(-5,-6,4,12)
        ctx.rect( 1,-6,4,12)
        ctx.closePath()
        ctx.fill()
        ctx.restore()
    help:
      function: -> Naubino.help()
      content: (ctx) -> this.draw_string(ctx, '?')
      position: new b2Vec2(45,65)
    exit:
      function: -> Naubino.exit()
      content: (ctx) -> this.draw_string(ctx, 'X')
      position: new b2Vec2(14,80)

  # changing the state a little

  oninit: ->
    @add_buttons()

  onenterplaying: ->
    @objects.play.disable()
    @objects.pause.enable()

  onenterpaused: ->
    @objects.play.enable()
    @objects.pause.disable()

  mainloop: ()=>
    @draw()
    @draw_listener_region()
    @step()


  step: ->
    for name, naub of @objects
      naub.step (@dt)
      if @hovering
        naub.physics.gravitate()
      else
        naub.physics.gravitate(@position)


  ## can I touch this?

  move_pointer: (x,y) ->
    [@pointer.x, @pointer.y] = [x,y]


  add_buttons: ->
    @objects.main = new Naubino.Naub(this, null, @cube_size)
    @objects.main.physics.pos.Set(@position.x, @position.y)
    @objects.main.physics.attracted_to = @position.Copy()
    @objects.main.shape.size = @cube_size
    @objects.main.shape.render = @draw_main_button
    @objects.main.shape.life_rendering = yes
    @objects.main.shape.pre_render()
    @objects.main.isClickable = no

    for name, attr of @buttons
      @objects[name] = new Naubino.Naub(this)
      @objects[name].physics.pos.Set attr.position.x, attr.position.y
      @objects[name].physics.attracted_to.Set attr.position.x, attr.position.y
      @objects[name].content = attr.content
      #@objects[name].shape.set_color_id 2
      @objects[name].shape.pre_render()
      @objects[name].focus = attr.function
      @objects[name].disable() if attr.disabled
      @objects[name].isClickable = no
      @objects[name].isClickable = no
      join = @objects[name].join_with( @objects.main, name )
      Naubino.graph.remove_join join

  switch_to_playing: ->
    console.log 'switching menu to playing mode'
    @objects.play.disable()
    @objects.pause.enable()

  switch_to_paused: ->
    console.log 'switching menu to paused mode'
    @objects.play.enable()
    @objects.pause.disable()


  draw: ->
    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
    @ctx.save()
    for name, naub of @objects
      naub.draw_joins(@ctx)if not naub.disabled
      naub.draw(@ctx) if not naub.disabled
    @objects.main.draw(@ctx)
    @objects.main.draw_joins()
    @draw_listener_region()
    @ctx.restore()


  draw_main_button: (ctx, x, y) ->

    ctx.save()
    ctx.translate(x,y)
    ctx.rotate(Math.PI/6)
    ctx.beginPath()
    ctx.rect( -@size/2, -@size/2, @size, @size)
    ctx.fillStyle = @color_to_rgba @style.fill
    ctx.fill()
    ctx.closePath()
    ctx.restore()

    ctx.save()
    ctx.translate(x,y)
    ctx.fillStyle = 'white'
    ctx.textAlign = 'center'
    ctx.font= 'bold 33px Helvetica'
    ctx.fillText(Naubino.game.points, 0,10, @size)
    ctx.restore()

  draw_listener_region: ->
    @ctx.save()
    @ctx.beginPath()
    @ctx.arc 0, 15, @listener_size, 0, Math.PI*2, true
    if @ctx.isPointInPath(@pointer.x,@pointer.y)
      unless @hovering
        Naubino.menu_focus.dispatch()
        @for_each (b) -> b.isClickable = yes
        @listener_size = 90
    else if @hovering
      Naubino.menu_blur.dispatch()
      @for_each (b) -> b.isClickable = no
      @listener_size = @default_listener_size
    #@ctx.stroke()
    @ctx.closePath()
    @ctx.restore()

