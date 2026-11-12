import {Layer} from '../core/Layer'

FLY_MIN_SCALE = 0.2
FLY_MAX_SCALE = 5

export class Overlay extends Layer
  constructor: (canvas) ->
    super(canvas)
    @name = "overlay"
    @fps = 20 # 5fps

    @setup_fsm()

  active_objects: ->
    active_objects = 0
    for id, object of @objects
      if object.life isnt true
        active_objects++
    active_objects


  draw: ->
    @pause() if @active_objects() == 0 and @can 'pause'

    @clear()
    @ctx.save()
    # objects are all full size buffers
    for id, buffer of @objects
      buffer.render() if buffer.life? or buffer.buffer.width isnt @canvas.width or buffer.buffer.height isnt @canvas.height or buffer.dark_mode isnt Util.isDarkMode()
      @fade_object buffer, id
      @ctx.save()
      @ctx.globalAlpha = buffer.alpha if buffer.alpha?
      if buffer.scale?
        center_x = buffer.pos.x
        center_y = buffer.pos.y
        @ctx.translate(center_x, center_y)
        @ctx.scale(buffer.scale, buffer.scale)
        @ctx.translate(-center_x, -center_y)
      @ctx.drawImage(buffer.buffer, 0, 0, @width, @height)
      @ctx.restore()
    @ctx.restore()


  fade_in_message: (text, callback) ->
    mes_id = @message text
    mes = @get_object mes_id
    mes.alpha = 0.01
    mes.alpha_delta = Naubino.settings.overlay.fade_duration / @fps
    mes.callback = callback
    mes_id


  # fading out a specific message by id
  fade_out_message: (mes_id, callback) ->
    @play() if @can "play"
    mes = @get_object(mes_id)
    console.log 'fade out message', mes.text
    mes.callback = callback
    mes.alpha_delta = -Naubino.settings.overlay.fade_duration / @fps if mes?


  # fading out all messages
  fade_out_messages: (callback) ->
    @play() if @can "play"
    @fade_out_message id for id, message of @objects when message.life isnt on
    k = Object.keys(@objects)
    @objects[k[k.length-1]].callback = callback if callback?



  fade_in_and_out_message: (text, callback = null) ->
    mes_id = @fade_in_message text
    mes = @get_object mes_id
    mes.callback = (=> @fade_out_message mes_id, callback)
    mes.duration = text.duration ? Naubino.settings.overlay.duration


  fly_in_and_out_message: (text, callback = null) ->
    mes_id = @message text
    mes = @get_object mes_id
    mes.alpha = 0
    mes.scale = FLY_MIN_SCALE
    mes.fly_age = 0
    mes.fly_duration = Math.max(text.duration ? Naubino.settings.overlay.duration, 0.1)
    mes.fly_callback = callback
    mes_id

  queue_messages: (messages = ["hello..", "...world"], qcallback) =>
    if m = messages.shift()
      messages = messages[0..]
      @fade_in_and_out_message( m, (=> @queue_messages messages, qcallback))
    else
      qcallback() if qcallback?

  warning: (text) -> @fade_in_message {text: text, fontsize: 45, color: Util.color_to_rgba(Naubino.colors().warn)}

  reset_osd: (text) ->
    @objects['OSD'] = new TextBuffer text, this
    @objects['OSD'].life = on
    @draw()

  set_osd: (text) ->
    unless @objects['OSD']
      @reset_osd text
    else
      @set_text 'OSD', text
      @objects['OSD'].life = on
      @draw()

  set_text: (id, text)->
    @objects[id].parse_text text
    @draw()

  fade_object: (buffer,id) ->
    if buffer.fly_duration?
      buffer.fly_age++
      progress = Math.min(buffer.fly_age / (buffer.fly_duration * @fps), 1)
      buffer.scale = FLY_MIN_SCALE + (FLY_MAX_SCALE - FLY_MIN_SCALE) * progress
      buffer.alpha = Math.sin(Math.PI * progress)
      if progress >= 1
        delete @objects[id]
        callback = buffer.fly_callback
        delete buffer.fly_duration
        callback.call() if callback?
      return

    if buffer.alpha_delta? and 0 < buffer.alpha <= 1
      buffer.alpha += buffer.alpha_delta
      buffer.alpha = Math.min buffer.alpha, 1
      buffer.alpha = Math.max buffer.alpha, 0
      delete buffer.alpha_delta if 1 <= buffer.alpha or buffer.alpha <= 0
    else
      if buffer.duration?
        buffer.age = if buffer.age? then buffer.age+1 else 0
        #console.time("fade #{id}") if buffer.age == 0
        if buffer.age >= buffer.duration*@fps
          delete buffer.duration
          #console.timeEnd("fade #{id}")
      else if buffer.callback?
        cb = buffer.callback
        delete @objects[id]    if buffer.alpha <= 0
        if buffer.alpha >=1
          delete buffer.callback
          delete buffer.age
        cb.call()
      else
        delete @objects[id]    if buffer.alpha <= 0


  message: (text, ctx = @ctx) ->
    @play() if @can 'play'
    buffer = new TextBuffer text, this
    @add_object buffer

class TextBuffer
  constructor: (text,@layer) ->
    @buffer        = document.createElement('canvas')
    @buffer.width  = @layer.canvas.width
    @buffer.height = @layer.canvas.height
    @alpha  = 1
    @ctx = @buffer.getContext('2d')

    @parse_text text
    @render()

  parse_text: (text) ->
    {@life, @color, @fontsize, @font, text, @pos, @weight, @align, x, y} = text unless typeof text == "string"
    @pos = new cp.v(x,y) if x? and y?
    @pos       ?= @layer.center()

    @fontsize  ?= Naubino.settings.overlay.fontsize
    @fontsize   = Naubino.settings.overlay.fontsize unless typeof @fontsize == "number"
    @font      ?= Naubino.settings.overlay.font
    @align     ?= 'center'
    @weight    ?= ""
    @text = text

  render: ->
    @buffer.width = @layer.canvas.width if @buffer.width isnt @layer.canvas.width
    @buffer.height = @layer.canvas.height if @buffer.height isnt @layer.canvas.height
    @ctx.setTransform(1, 0, 0, 1, 0, 0)
    @ctx.clearRect(0, 0, @buffer.width, @buffer.height)
    @ctx.setTransform(@buffer.width / @layer.width, 0, 0, @buffer.height / @layer.height, 0, 0)
    dark_mode = Util.isDarkMode()
    text_color = @color ? (if dark_mode then 'white' else 'black')
    @dark_mode = dark_mode
    lines = @text.split("\n")
    pos = {x:@pos.x, y:@pos.y}
    pos.y -= @fontsize * (lines.length - 1) / 2
    for line in lines
      console.log "OVERLAY:", line unless @life
      @ctx.fillStyle = text_color
      @ctx.shadowColor = if dark_mode then 'black' else 'white'
      @ctx.shadowBlur = 2
      @ctx.strokeStyle = text_color
      @ctx.textAlign = @align
      @ctx.textBaseline = 'middle'
      @ctx.font= "#{@weight} #{@fontsize}px #{@font}"
      @ctx.fillText(line, pos.x,pos.y)
      pos.y += @fontsize
