import {Util} from '../../core/Util'

export class BasketRenderer
  constructor: (@basket, @field) ->

  draw: (ctx, frame) ->
    color = if Util.isDarkMode() then [190,190,190] else [100,100,100]
    thickness = 4
    severity = @basket.severity
    if severity > 0
      frequency = Util.interpolate 1, 4, severity
      pulse = (Math.sin(frame.time / 1000 * Math.PI * 2 * frequency) + 1) / 2
      thickness = Util.interpolate 2, 12, pulse
      color = Util.interpolate_color color, Naubino.colors().warn, pulse * severity
    center = @field.center()
    ctx.save()
    ctx.beginPath()
    ctx.arc center.x, center.y, @basket.basket_size() + thickness * 2, 0, Math.PI * 2, false
    ctx.lineWidth = thickness
    ctx.strokeStyle = Util.color_to_rgba color
    ctx.stroke()
    ctx.closePath()
    ctx.restore()
    return
