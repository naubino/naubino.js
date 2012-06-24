define ["Layer"], (Layer) -> class Overlay extends Layer
  constructor: (canvas) ->
    super(canvas)
    @name = "overlay"
    @animation.name = "overlay.animation"
    @fps = 20 # 5fps

    @fade_duration = 1 # in seconds
    @default_duration = 1 # in seconds 
    @default_font = "Helvetica"
    @default_color= "black"
    @default_fontsize = 15


  draw: ->
    if Object.keys(@objects).length == 0 and @animation.can "pause"
      @animation.pause()

    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
    @ctx.save()
    # objects are all full size buffers
    for id, buffer of @objects
      @fade_object buffer, id
      @ctx.globalAlpha = buffer.alpha if buffer.alpha?
      @ctx.drawImage(buffer, 0, 0)
      @ctx.globalAlpha = 1
    @ctx.restore()

  
  fade_in_message: (text, callback) ->
    mes_id = @message text
    mes = @get_object mes_id
    mes.alpha = 0.01
    mes.alpha_delta = @fade_duration / @fps
    mes.callback = callback
    mes_id

  
  ### fading out a specific message by id ###
  fade_out_message: (mes_id, callback) ->
    mes = @get_object(mes_id)
    mes.callback = callback
    mes.alpha_delta = -@fade_duration / @fps if mes?


  ### fading out all messages ###
  fade_out_messages: (callback) ->
    @fade_out_message id for id, message of @objects
    k = Object.keys(@objects)
    @objects[k[k.length-1]].callback = callback



  fade_in_and_out_message: (text, callback = null) ->
    mes_id = @fade_in_message text
    mes = @get_object mes_id
    mes.callback = (=> @fade_out_message mes_id, callback)
    mes.duration = text.duration ? @default_duration


  queue_messages: (messages = ["hello..", "...world"], qcallback) =>
    if m = messages.shift()
      messages = messages[0..]
      @fade_in_and_out_message( m, (=> @queue_messages messages, qcallback))
    else
      qcallback() if qcallback?


  message: (text, ctx = @ctx) ->
    @animation.play() if @animation.can 'play'

    {color, fontsize, font, text,pos} = text unless typeof text == "string"
    pos       ?= @center()
    color     ?= @default_color
    fontsize  ?= @default_fontsize
    fontsize   = @default_fontsize unless typeof fontsize == "number"
    font      ?= @default_font

    buffer        = document.createElement('canvas')
    buffer.width  = Naubino.settings.canvas.width
    buffer.height = Naubino.settings.canvas.height
    buffer.alpha  = 1

    buffer.text = text
    ctx = buffer.getContext('2d')
    lines = text.split("\n")
    pos.y -= fontsize * lines.length /2
    for line in lines
      console.log "OVERLAY:", line

      ctx.fillStyle = color
      ctx.shadowColor = '#fff'
      ctx.shadowBlur = 3
      ctx.strokeStyle = color
      ctx.textAlign = 'center'
      ctx.font= "#{fontsize}px #{font}"
      ctx.fillText(line, pos.x,pos.y)

      pos.y += fontsize
    @add_object buffer


  fade_object: (buffer,id) ->
    if buffer.alpha_delta? and 0 < buffer.alpha <= 1
      buffer.alpha += buffer.alpha_delta
      buffer.alpha = Math.min buffer.alpha, 1
      buffer.alpha = Math.max buffer.alpha, 0
      delete buffer.alpha_delta if 1 <= buffer.alpha or buffer.alpha <= 0
    else
      if buffer.duration?
        buffer.age = if buffer.age? then buffer.age+1 else 0
        console.time("fade #{id}") if buffer.age == 0
        if buffer.age >= buffer.duration*@fps
          delete buffer.duration
          console.timeEnd("fade #{id}")
      else if buffer.callback?
        cb = buffer.callback
        delete @objects[id]    if buffer.alpha <= 0
        if buffer.alpha >=1
          delete buffer.callback
          delete buffer.age
        cb.call()
      else
        delete @objects[id]    if buffer.alpha <= 0

