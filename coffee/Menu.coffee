# TODO clean up menu code -- will do in naub_rethought
define ["Menu", "Layer", "Naub", "Graph", "Shapes"], (Menu, Layer, Naub, Graph, { Ball, StringShape, PlayButton, PauseButton, MainButton }) -> class Menu extends Layer
  constructor: (canvas) ->
    super(canvas)
    @name = "menu"
    @graph = new Graph(this)
    @animation.name = "menu.animation"

    @objects = {}
    @hovering = off
    @drawing = on
    @gravity = Naubino.settings.physics.gravity.menu

    @listener_size = @default_listener_size = 45
    Naubino.mousemove.add @move_pointer
    Naubino.mousedown.add @click
    Naubino.menu_button.active = false
   
    @physics_fps = 35
    @position = new b2Vec2(20,25)
    @cube_size = 45
    
    StateMachine.create {
      target:this
      events: Naubino.settings.events
      error: (e, from, to, args, code, msg) -> console.error "#{@name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"
    }

    ### definition of each button
    TODO: position should be dynamic
    ###


  # changing the state a little
  oninit: ->
    @add_buttons()
    @start_stepper()

  buttons:
    main:
      position:  new b2Vec2(20,25)
      shapes: [new MainButton]
    play:
      function: -> Naubino.play()
      position: new b2Vec2(65,35)
      shapes: [new Ball, new PlayButton]
    help:
      function: -> Naubino.tutorial()
      position: new b2Vec2(45,65)
      shapes: [new Ball, new StringShape "?", "white"]
    exit:
      function: -> Naubino.stop()
      position: new b2Vec2(14,80)
      shapes: [new Ball, new StringShape "X", "white"]

  add_buttons: ->
    for name, button of @buttons
      @objects[name] = new Naub(this)
      for shape in button.shapes
        @objects[name].add_shape shape
      @objects[name].update()
      @objects[name].focus = button.function
      @objects[name].disabled = button.disabled
      @objects[name].isClickable = no
      @objects[name].physics.pos.Set button.position.x, button.position.y
      @objects[name].physics.mass = Naubino.settings.naub.mass_menu
      @objects[name].physics.attracted_to.Set button.position.x, button.position.y
      @graph.remove_join @objects[name].join_with( @objects.main, name ) # add the object without managing the join

    @objects.main.life_rendering = on


  onenterplaying: ->
    @objects.play.focus = -> Naubino.pause()
    @objects.play.shapes.pop()
    @objects.play.add_shape new PauseButton
    @objects.play.update()


  onenterpaused: ->
    @objects.play.focus = -> Naubino.play()
    @objects.play.shapes.pop()
    @objects.play.add_shape new PlayButton
    @objects.play.update()

  onenterstopped: (e,f,t) ->
    unless e is 'init'
      @onenterpaused()


  step: (dt) ->
    for name, naub of @objects
      naub.step (dt)
      if @hovering
        naub.physics.gravitate(dt)
      else
        naub.physics.gravitate(dt, @position)


  #utility for Game
  update:-> @objects.main.update()

  ## can I touch this?

  move_pointer: (x,y) -> [@pointer.x, @pointer.y] = [x,y]

  draw: ->
    @draw_menu()
    @draw_listener_region()

  draw_menu: ->
    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
    @ctx.save()
    for name, naub of @objects
      naub.draw_joins(@ctx)if not naub.disabled
      naub.draw(@ctx) if not naub.disabled
    @objects.main.draw(@ctx)
    @objects.main.draw_joins()
    @draw_listener_region()
    @ctx.restore()

  draw_listener_region: ->
    @ctx.save()
    @ctx.beginPath()
    @ctx.arc 0, 15, @listener_size, 0, Math.PI*2, true
    if @ctx.isPointInPath(@pointer.x,@pointer.y)
      unless @hovering
        Naubino.menu_focus.dispatch()
        @for_each (b) -> b.isClickable = yes
        @listener_size = 90
        @start_stepper()
    else if @hovering
      Naubino.menu_blur.dispatch()
      @for_each (b) -> b.isClickable = no
      @listener_size = @default_listener_size
      setTimeout (@stop_stepper ),1000
    #@ctx.stroke() # like to see it
    @ctx.closePath()
    @ctx.restore()

