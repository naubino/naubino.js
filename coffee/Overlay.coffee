Naubino.Overlay = class Overlay extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)
    @fps = 1000 / 5

  

  warning:(text, font_size = 25,x = @center.x, y = @center.y) ->
    @ctx.fillStyle = @color_to_rgba(Naubino.colors[0])
    @ctx.strokeStyle = @color_to_rgba(Naubino.colors[0])
    @ctx.textAlign = 'center'
    @ctx.font= "bold #{font_size+4}px Helvetica"
    @ctx.fillText(text, x, y)

  fade_in_message: (text, font_size = null) ->
    @hide()
    @message text, font_size
    console.log "fade_in: #{text}"
    @fade_in()

  # uses render text
  message: (text,font_size = 15,color = 'black',  x = @center.x, y = @center.y) ->
    lines = text.split("\n")
    y -= font_size * lines.length /2
    for line in lines
      @render_text(line, font_size, color, x, y)
      y += font_size
    return

  render_text: (text, font_size = 15, color = 'black', x = @center.x, y = @center.y) ->
    @ctx.fillStyle = color
    @ctx.strokeStyle = color
    @ctx.textAlign = 'center'
    @ctx.font= "#{font_size}px Helvetica"
    @ctx.fillText(text, x,y)
