define ["Layer"], (Layer) -> class Overlay extends Layer
  constructor: (canvas) ->
    super(canvas)
    @name = "overlay"
    @animation.name = "overlay.animation"
    @fps = 15 # 5fps
    @fade_speed = 40

  fade_object: (buffer,id) ->
    if buffer.alpha_delta? and 0 <= buffer.alpha <= 1
      buffer.alpha += buffer.alpha_delta

      if buffer.alpha > 1
        buffer.alpha = 1
        buffer.callback.call() if buffer.callback?
        delete buffer.callback
        delete buffer.alpha_delta

      if buffer.alpha <= 0
        buffer.alpha = 0
        buffer.callback.call() if buffer.callback?
        delete buffer.callback
        delete @objects[id]


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
  
  warning:(text, font_size = 25,x = @center.x, y = @center.y) ->
    color = @color_to_rgba(Naubino.colors[0])
    @message text, font_size , color,  x, y

  fade_in_warning:(text, callback = null, font_size = 25,x = @center.x, y = @center.y) ->
    color = @color_to_rgba(Naubino.colors[0])
    @fade_in_message text, callback, font_size , color,  x, y


  fade_in_message: (text, callback = null, font_size = 15, color = 'black',  x = @center.x, y = @center.y, ctx = @ctx) ->
    mes_id = @message text, font_size , color,  x, y, ctx
    mes = @get_object mes_id
    mes.alpha = 0.01
    mes.alpha_delta = 1 / @fps
    mes.callback = callback
    mes_id

  
  ### fading out a specific message by id ###
  fade_out_message: (mes_id, callback = null)->
    mes = @get_object(mes_id)
    mes.alpha_delta = -1 / @fps if mes?


  ### fading out all messages ###
  fade_out_messages: (callback = null) ->
    @fade_out_message id for id, message of @objects
    callback() if callback?


  fade_in_and_out_message: (text, callback = null, font_size = 15, color = 'black',  x = @center.x, y = @center.y, ctx = @ctx) ->
    if Array.isArray(text)
      # don't worry - both lines are supposed to do the same...
      font_size = text[2] ? font_size
      time      = text[1] ? 1000
      text      = text[0] ? ""
      
    else
      time = 2000

    fade_out = => setTimeout =>
      @fade_out_message mes_id, callback
    ,time

    mes_id = @fade_in_message text, fade_out, font_size , color,  x, y, ctx
    mes = @get_object mes_id


  queue_messages: (messages = ["hello", "world"], callback = null, font_size = 15) =>
    if m = messages.shift()
      messages = messages[0..]
      @fade_in_and_out_message m, (=> @queue_messages messages, callback, font_size), font_size
    else
      callback() if callback?


  message: (text,font_size = 15,color = 'black',  x = @center.x, y = @center.y, ctx = @ctx) ->
    if @animation.can 'play'
      @animation.play()
    buffer = document.createElement('canvas')
    buffer.width = Naubino.settings.canvas.width
    buffer.height = Naubino.settings.canvas.height
    buffer.alpha = 1
    buffer.text = text
    ctx = buffer.getContext('2d')
    lines = text.split("\n")
    y -= font_size * lines.length /2
    for line in lines
      console.log "OVERLAY:", line
      @render_text(line, font_size, color, x, y, ctx)
      y += font_size
    @add_object buffer


  render_text: (text, font_size = 15, color = 'black', x = @center.x, y = @center.y, ctx = @ctx) ->
    ctx.fillStyle = color
    ctx.shadowColor = '#fff'
    ctx.shadowBlur = 3
    ctx.strokeStyle = color
    ctx.textAlign = 'center'
    ctx.font= "#{font_size}px Helvetica"
    ctx.fillText(text, x,y)

