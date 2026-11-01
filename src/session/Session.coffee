# app lifecycle, drives the layers of its naubino. LayerManager forwards here
# game still has its own fsm: stop asks the game first, game's loose calls back in
export class Session
  constructor: (@naubino) ->
    StateMachine.create {
      target: this
      events: Naubino.settings.events.default.concat Naubino.settings.events.game
      error: (e, from, to, args, code, msg) =>
             console.error "#{@naubino.name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"
    }

  # switching between pause and play
  toggle: ->
    switch @current
      when 'playing' then @pause()
      when 'paused'  then @play()
      when 'stopped' then @play()

  oninit: ->
    for layer in @naubino.layers
      layer.init()

  onchangestate: (e,f,t) -> console.info "Naubino changed states #{e}: #{f} -> #{t}"

  onleavestopped: ->
    @naubino.menu.play() #if @menu.can 'play'
    #@overlay.fade_out_messages()

  onplay: (event, from, to) ->
    {game, overlay, background, menu} = @naubino
    for layer in [ game, overlay, background ]
      layer.play()
    menu.check_game_state game

  onbeforepause: ->
    {game, background} = @naubino
    game.can("pause") and background.can("pause")

  onpause: (event, from, to) ->
    {game, overlay, background, menu} = @naubino
    for layer in [ game, overlay, background ]
      layer.pause() if overlay.can 'pause'
    menu.check_game_state game

  # Game.onbeforestop checks this to skip the mode's confirm
  onbeforestop: (event, from, to, override = off) ->
    @naubino.override = override
    {game, overlay, background} = @naubino
    game.stop()
    if game.current == 'stopped'
      overlay.stop()
      background.stop()
    else
      return false

  onstopped: (e,f,t) ->
    {game, overlay, background, menu} = @naubino
    console.warn 'stopped'
    for layer in [ game, overlay, background ]
      layer.init()
    #setTimeout (=> @overlay.fade_in_message({text:'naubino', fontsize:75})), 100
    menu.check_game_state game
    unless f == 'none' or @naubino.temp_score.points == 0
      name = prompt("Enter your name for the highscore")
      @naubino.store_score name if name?


  onloose:(e,f,t,msg="Game Over") ->
    {game, overlay, background} = @naubino
    game.loose() if game.can 'loose'
    overlay.warning (msg)

    leavelost= =>
      console.warn 'leaving lost'
      overlay.stop()
      background.stop()
      game.fade_out(=> (setTimeout (=> @stop(yes)), 2000))

    game.one_after_another ((n) -> n.grey_out()), leavelost

  onleavelost: ->
