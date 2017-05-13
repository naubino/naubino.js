import {Layer} from './Layer'
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

    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
    @ctx.save()
    # objects are all full size buffers
    for id, buffer of @objects
      buffer.render() if buffer.life?
      @fade_object buffer, id
      @ctx.globalAlpha = buffer.alpha if buffer.alpha?
      @ctx.drawImage(buffer.buffer, 0, 0)
      @ctx.globalAlpha = 1
    @ctx.restore()

  
  fade_in_message: (text, callback) ->
    mes_id = @message text
    mes = @get_object mes_id
    mes.alpha = 0.01
    mes.alpha_delta = Naubino.settings.overlay.fade_duration / @fps
    mes.callback = callback
    mes_id

  
  ### fading out a specific message by id ###
  fade_out_message: (mes_id, callback) ->
    @play() if @can "play"
    mes = @get_object(mes_id)
    console.log 'fade out message', mes.text
    mes.callback = callback
    mes.alpha_delta = -Naubino.settings.overlay.fade_duration / @fps if mes?


  ### fading out all messages ###
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


  queue_messages: (messages = ["hello..", "...world"], qcallback) =>
    if m = messages.shift()
      messages = messages[0..]
      @fade_in_and_out_message( m, (=> @queue_messages messages, qcallback))
    else
      qcallback() if qcallback?

  warning: (text) -> @fade_in_message {text: text, fontsize: 45, color: Util.color_to_rgba(Naubino.colors()[0])}

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
    @buffer.width  = Naubino.settings.canvas.width
    @buffer.height = Naubino.settings.canvas.height
    @alpha  = 1
    @ctx = @buffer.getContext('2d')

    @parse_text text
    @render()

  parse_text: (text) ->
    {@life, @color, @fontsize, @font, text, @pos, @weight, @align, x, y} = text unless typeof text == "string"
    @pos = new cp.v(x,y) if x? and y?
    @pos       ?= @layer.center()
    @color     ?= Naubino.settings.overlay.color
    @fontsize  ?= Naubino.settings.overlay.fontsize
    @fontsize   = Naubino.settings.overlay.fontsize unless typeof @fontsize == "number"
    @font      ?= Naubino.settings.overlay.font
    @align     ?= 'center'
    @weight    ?= ""
    @text = text

  render: ->
    @ctx.clearRect(0, 0, @buffer.width, @buffer.height)
    lines = @text.split("\n")
    pos = {x:@pos.x, y:@pos.y}
    pos.y -= @fontsize * lines.length /2
    for line in lines
      console.log "OVERLAY:", line unless @life
      @ctx.fillStyle = @color
      @ctx.shadowColor = '#fff'
      @ctx.shadowBlur = 3
      @ctx.strokeStyle = @color
      @ctx.textAlign = @align
      @ctx.font= "#{@weight} #{@fontsize}px #{@font}"
      @ctx.fillText(line, pos.x,pos.y)
      pos.y += @fontsize
