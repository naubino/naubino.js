class Naubino.Overlay extends Naubino.Layer
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
    clearInterval mes.fadeloop
    mes.fadeloop = setInterval( fade, 40 )
    mes_id

  fade_in_and_out_message: (text, time = 1000, callback = null, font_size = 15, color = 'black',  x = @center.x, y = @center.y, ctx = @ctx) ->
    fade_out = => setTimeout =>
      @fade_out_message mes_id, callback
    ,time

    mes_id = @fade_in_message text, fade_out, font_size , color,  x, y, ctx
    mes = @get_object mes_id


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

