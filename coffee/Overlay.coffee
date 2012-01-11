Naubino.Overlay = class Overlay extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @fps = 1000 / 15 # 5fps
    @drawing = true
    @start_timer()


  draw:  ->
    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
    @ctx.save()

    # objects are all full size buffers
    for id, buffer of @objs
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
    fade = =>
      if (mes.alpha *= 1.2) >= 1
        clearInterval mes.fadeloop
        mes.alpha = 1
        if callback?
          callback.call()
        console.log 'fade in:', text
    clearInterval mes.fadeloop
    mes.fadeloop = setInterval( fade, 40 )
    mes_id

  ### fading out a specific message by id ###
  fade_out_message: (mes_id, callback = null)->
    #console.log "fade out"
    mes = @get_object mes_id
    fade = =>
      if (mes.alpha *= 0.8) <= 0.05
        #console.log mes.alpha
        clearInterval mes.fadeloop
        if callback?
          callback.call()
        @remove_obj mes_id

    clearInterval mes.fadeloop
    #console.log mes
    if mes?
      mes.fadeloop = setInterval( fade, 40 )


  ### fading out all messages ###
  fade_out_messages: (callback = null) ->
    for id, message of @objs
      @fade_out_message id
    if callback?
      callback()

  kill: ->
    @queue_messages [['Hallo Gilbert',1000],["kill me"],"Kill me nau"]

  fade_in_and_out_message: (text, callback = null, font_size = 15, color = 'black',  x = @center.x, y = @center.y, ctx = @ctx) ->
    if Array.isArray(text)
      console.log 42, text[2]
      time = if text[1]? then text[1] else 1000
      text = if text[0]? then text[0] else "Sorry for putting this here, but something went wrong."
    else
      time = 2000

    fade_out = => setTimeout =>
      @fade_out_message mes_id, callback
    ,time

    mes_id = @fade_in_message text, fade_out, font_size , color,  x, y, ctx
    mes = @get_object mes_id

  queue_messages: (messages = ["hello", "world"], callback = null) =>
    if m = messages.shift()
      console.log "message '#{m}' still there"
      messages = messages[0..]
      @fade_in_and_out_message m, => @queue_messages messages
    else
      callback() if callback?

    return

  message: (text,font_size = 15,color = 'black',  x = @center.x, y = @center.y, ctx = @ctx) ->
    buffer = document.createElement('canvas')
    buffer.width = Naubino.Settings.canvas.width
    buffer.height = Naubino.Settings.canvas.height
    buffer.alpha = 1

    ctx = buffer.getContext('2d')

    lines = text.split("\n")
    y -= font_size * lines.length /2
    for line in lines
      #console.log line
      @render_text(line, font_size, color, x, y, ctx)
      y += font_size
    @add_object buffer


  render_text: (text, font_size = 15, color = 'black', x = @center.x, y = @center.y, ctx = @ctx) ->
    ctx.fillStyle = color
    ctx.strokeStyle = color
    ctx.textAlign = 'center'
    ctx.font= "#{font_size}px Helvetica"
    ctx.fillText(text, x,y)

