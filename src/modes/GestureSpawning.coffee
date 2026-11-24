export class GestureSpawning
  constructor: (@two_finger_start, @two_finger_end, @spawn) ->
    @disposed = no
    @abort_controller = null
    @timer = null

  start: ->
    return if @disposed or @abort_controller?
    @abort_controller = new AbortController
    {signal} = @abort_controller
    @two_finger_start.add (=> @begin_spawning()), signal
    @two_finger_end.add (=> @end_spawning()), signal

  stop: ->
    @abort_controller?.abort()
    @abort_controller = null
    @end_spawning()

  dispose: ->
    @disposed = yes
    @stop()

  begin_spawning: ->
    @end_spawning()
    return if @disposed or not @abort_controller?
    @spawn()
    return if @disposed or not @abort_controller?
    @timer = setInterval (=>
      @spawn() if not @disposed and @abort_controller?
    ), 300

  end_spawning: ->
    clearInterval @timer if @timer?
    @timer = null
