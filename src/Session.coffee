# Coordinates the game, menu, and visual layers through one lifecycle FSM.
export class Session
  constructor: ({@game, @menu, @overlay, @background, @events, @name = 'Naubino', @on_finished = ->}) ->
    StateMachine.create {
      target: this
      events: @events.default.concat @events.game
      error: (e, from, to, args, code, msg) =>
        console.error "#{@name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"
    }

  # switching between pause and play
  toggle: ->
    switch @current
      when 'playing' then @pause()
      when 'paused'  then @play()
      when 'stopped' then @play()

  oninit: ->
    layer.init() for layer in [@background, @game, @menu, @overlay]

  onchangestate: (e, f, t) -> console.info "#{@name} changed states #{e}: #{f} -> #{t}"

  onleavestopped: ->
    @menu.play()

  onplay: (event, from, to) ->
    layer.play() for layer in [@game, @overlay, @background]
    @menu.check_game_state @game

  onbeforepause: ->
    for layer in [@game, @overlay, @background]
      return false unless layer.can 'pause'
    true

  onpause: (event, from, to) ->
    layer.pause() for layer in [@game, @overlay, @background]
    @menu.check_game_state @game

  onbeforestop: (event, from, to, force = off) ->
    @completed_snapshot = null
    snapshot = @game.score_snapshot() if from isnt 'stopped'
    @game.stop force
    if @game.current == 'stopped'
      @completed_snapshot = snapshot
      @overlay.stop()
      @background.stop()
    else
      return false

  onstopped: (e, from, to) ->
    layer.init() for layer in [@game, @overlay, @background]
    @menu.check_game_state @game
    if @completed_snapshot?
      snapshot = @completed_snapshot
      @completed_snapshot = null
      @on_finished snapshot

  onloose: (e, from, to, msg = 'Game Over') ->
    @game.loose() if @game.can 'loose'
    @overlay.warning msg

    leave_lost = =>
      @overlay.stop()
      @background.stop()
      @game.fade_out => setTimeout (=> @stop yes), 2000

    @game.one_after_another ((n) -> n.grey_out()), leave_lost

  onleavelost: ->
