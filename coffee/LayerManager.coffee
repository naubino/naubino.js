define [ "Background", "Game", "Menu", "Overlay", "StandardGame", "TestCase", "Tutorial" ],(Background, Game, Menu, Overlay, StandardGame, TestCase, Tutorial)-> class LayerManager

  setup_fsm: ->
    StateMachine.create {
      target: this
      events: Naubino.settings.events.default.concat Naubino.settings.events.game
      error: (e, from, to, args, code, msg) -> console.error "#{@name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"
    }



  setup_layers: ->
    @background    = new Background   @canvases.background_canvas
    @menu          = new Menu         @canvases.menu_canvas
    @overlay       = new Overlay      @canvases.overlay_canvas
    @game_standard = new StandardGame @canvases.game_canvas

    #@game_testcase = new TestCase(@game_canvas)
    #@game_tutorial = new Tutorial(@game_canvas)
    @game          = @game_standard
    #@game          = @game_testcase
    #@game          = @game_tutorial
    #@game = new Game @game_canvas
    @layers = [ @background, @game, @menu, @overlay ]

  oninit: -> @init_layers()

  init_layers:->
    @menu.init()
    @background.init()
    @game.init()
    @overlay.init()


  demaximize: ->
    for layer in  @layers
      layer.reset_resize()
    @scale = 1

  maximize: ->
    if @scale is 1
      win_width = screen.width
      win_height= screen.height
      game_width = $("canvas#game_canvas").width()
      oscale = 1

      @scale = Naubino.settings.canvas.scale = win_width / game_width
      document.querySelector("#gamediv").style.width = ""
      console.log ratio = Naubino.settings.canvas.scale/oscale
      for layer in  @layers
        layer.resize_by ratio
      
  stretch: (width = "100%")->
    for name in 'background game menu overlay'.split ' '
      document.querySelector("canvas##{name}_canvas").style.width = width
    console.log @scale = $("canvas#game_canvas").width()/Naubino.settings.canvas.width


  list_states: ->
    @.name = "Naubino"
    for o in [ @, @menu, @game, @overlay, @background]
      switch o.current
        when 'playing' then console.info o.name, o.current
        when 'paused'  then console.warn o.name, o.current
        when 'stopped' then console.warn o.name, o.current
        else console.error o.name, o.current


  # switching between pause and play
  toggle: ->
    switch @current
      when 'playing' then @pause()
      when 'paused'  then @play()
      when 'stopped' then @play()

  onchangestate: (e,f,t) ->
    console.info "Naubino changed states #{e}: #{f} -> #{t}"

  onleavestopped: -> @menu.play() if @menu.can 'play'

  onplay: (event, from, to) ->
    @game.play()
    @overlay.play()
    @background.play()
    @menu.check_game_state @game

  onbeforepause: -> @game.can("pause") and @background.can("pause")

  onpause: (event, from, to) ->
    @game.pause()
    @background.pause()
    @overlay.pause() if @overlay.can 'pause'
    @menu.check_game_state @game

  onstopped: (e,f,t) ->
    @menu.stop()
    @init_layers()

  onleavelost: ->
    @game.fade_out()
    @overlay.fade_out()
    @background.fade_out @transition
    StateMachine.ASYNC

  onbeforestop: (event, from, to, @override = off) ->
    @game.stop()
    if @game.current == 'stopped'
      @overlay.stop()
      @background.stop()
    else
      return false

  onloose:(e,f,t,msg="GameOver") ->
    @game.for_each (n) -> n.grey_out()
    setTimeout (=> @game.pause()), 500
    @overlay.warning (msg)
    setTimeout (=> @stop(true)), 4000

  onleavelost: ->
    @game.fade_out( )


