# Coordinates the game, menu, and visual layers through one lifecycle FSM.
export class Session

  constructor: ({@game, @menu, @overlay, @background, @transitions, @events, @name = 'Naubino', @on_finished = ->}) ->
    @disposed = no
    StateMachine.create {
      target: this
      events: @transitions.default.concat @transitions.game
      error: (e, from, to, args, code, msg) =>
        console.error "#{@name}.#{e}: #{from} -> #{to}\n#{code}::#{msg}"
    }
    @subscriptions = [
      @events.commands.play.add (args...) => @play args...
      @events.commands.pause.add (args...) => @pause args...
      @events.commands.stop.add (args...) => @stop args...
      @events.commands.toggle.add (args...) => @toggle(args...)
      @events.game.outcome.add (reason) => @report_outcome reason
      @events.game.level_up.add (level) => @overlay.fade_in_and_out_message "Level #{level}"
      # Keep bonuses below level announcements when both arrive together.
      @events.game.chain_bonus.add (points) => @overlay.fade_in_and_out_message "\n\nChain Bonus #{points}"
    ]

  dispose: ->
    @disposed = yes
    clearTimeout @loss_timeout if @loss_timeout?
    unsubscribe() for unsubscribe in @subscriptions
    @subscriptions = []

  # # switching between pause and play
  # toggle: ->
  #   switch @current
  #     when 'playing' then @pause()
  #     when 'paused'  then @play()
  #     when 'stopped' then @play()

  oninit: ->
    layer.init() for layer in [@background, @game, @menu, @overlay]

  onchangestate: (e, f, t) ->
    console.info "#{@name} changed states #{e}: #{f} -> #{t}"
    @events.session.state_changed.dispatch t

  onleavestopped: ->
    @menu.play()

  onplaying: (event, from, to) ->
    console.info("session playing")
    layer.play() for layer in [@game, @overlay, @background]
    @menu.check_game_state @game

  onbeforepause: ->
    for layer in [@game, @overlay, @background]
      return false unless layer.can 'pause'
    true

  onpaused: (event, from, to) ->
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

  report_outcome: (reason = 'Game Over') ->
    return if @handling_outcome or @current is 'lost'
    @loose reason if @can 'loose'

  onloose: (e, from, to, msg = 'Game Over') ->
    @handling_outcome = yes
    @game.loose(msg) if @game.can 'loose'
    @handling_outcome = no
    @overlay.warning msg

    leave_lost = =>
      return if @disposed
      @overlay.stop()
      @background.stop()
      @game.fade_out =>
        return if @disposed
        @loss_timeout = setTimeout (=> @stop yes unless @disposed), 2000

    @game.one_after_another ((n) -> n.grey_out()), leave_lost

  onleavelost: ->
