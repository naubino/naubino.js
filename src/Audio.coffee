export class Audio

  path: "sound/"
  i: 0

  blub_names: [
    "8000__cfork__cf-fx-bloibb"
    "8001__cfork__cf-fx-doppp-01"
    "8003__cfork__cf-fx-doppp-03-dry"
    "8008__cfork__cf-fx-plopp-01"
    "8009__cfork__cf-fx-plopp-02"
  ]

  _pick_format: ->
    probe = document.createElement 'audio'
    if probe.canPlayType('audio/ogg') isnt '' then 'ogg' else 'mp3'

  constructor: (@settings) ->
    @ctx = new AudioContext()
    @buffers = []
    @_load()

  _load: ->
    fmt = @_pick_format()
    @buffers = await Promise.all @blub_names.map (name) =>
      @ctx.decodeAudioData await (await fetch("#{@path}#{name}.#{fmt}")).arrayBuffer()

  random_blub: =>
    return if @settings.audio.muted
    return unless @buffers.length
    si = @i++ % @buffers.length
    source = @ctx.createBufferSource()
    source.buffer = @buffers[si]
    source.connect @ctx.destination
    source.start 0
