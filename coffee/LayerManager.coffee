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
      ratio = Naubino.settings.canvas.scale/oscale
      for layer in  @layers
        layer.resize_by ratio
      
  stretch: (width = "100%")->
    for name in 'background game menu overlay'.split ' '
      document.querySelector("canvas##{name}_canvas").style.width = width
    #console.log @scale = $("canvas#game_canvas").width()/Naubino.settings.canvas.width


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

  oninit: ->
    for layer in @layers
      layer.init()

  onchangestate: (e,f,t) -> console.info "Naubino changed states #{e}: #{f} -> #{t}"

  onleavestopped: ->
    @menu.play() if @menu.can 'play'
    @overlay.fade_out_messages()

  onplay: (event, from, to) ->
    for layer in [ @game, @overlay, @background ]
      layer.play()
    @menu.check_game_state @game

  onbeforepause: -> @game.can("pause") and @background.can("pause")

  onpause: (event, from, to) ->
    for layer in [ @game, @overlay, @background ]
      layer.pause() if @overlay.can 'pause'
    @menu.check_game_state @game

  onbeforestop: (event, from, to, @override = off) ->
    @game.stop()
    if @game.current == 'stopped'
      @overlay.stop()
      @background.stop()
    else
      return false

  onstopped: (e,f,t) ->
    console.warn 'stopped'
    for layer in [ @game, @overlay, @background ]
      layer.init()
    setTimeout (=> @overlay.fade_in_message({text:'naubino', fontsize:75})), 100
    @menu.check_game_state @game


  onloose:(e,f,t,msg="Game Over") ->
    @game.loose() if @game.can 'loose'
    @overlay.warning (msg)

    leavelost= =>
      console.warn 'leaving lost'
      @overlay.stop()
      @background.stop()
      @game.fade_out(=> (setTimeout (=> @stop(yes)), 2000))

    @game.one_after_another ((n) -> n.grey_out()), leavelost

  onleavelost: ->
    name = prompt("Enter your name for the highscore")
    alert("Thank you #{name}, unfortunately a highscore has not been implemented yet")
    #Naubino 
