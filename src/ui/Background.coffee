import {Layer} from '../core/Layer'

export class Background extends Layer
  constructor: (canvas, viewport) ->
    super(canvas, viewport)
    @name = 'background'
    @setup_fsm()

  onplay: ->
    @show()
    @draw()

  draw: -> @clear()

  draw_line: (x0, y0, x1 = @center().x, y1 = @center().y, color = 'black') ->
    @ctx.beginPath()
    @ctx.moveTo(x0, y0)
    @ctx.lineTo(x1, y1)
    @ctx.lineWidth = 2
    @ctx.strokeStyle = color
    @ctx.stroke()
    @ctx.closePath()
