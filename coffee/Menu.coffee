# TODO cliean up menu code
class Naubino.Menu extends Naubino.Layer
  constructor: (canvas) ->
    super(canvas)

    @objs = {}
    @hovering = false
    @gravity = Naubino.Settings.gravity.menu

    @listener_size = @default_listener_size = 45
    Naubino.mousemove.add @move_pointer
    Naubino.mousedown.add @click
    Naubino.naub_destroyed.add -> Naubino.menu.objs.main.shape.pre_render()
    
    @position = new b2Vec2(20,25)
    @cube_size = 45
    

    ### definition of each button
    TODO: position should be dynamic
    ###
    @buttons = {
      play:
        function: -> Naubino.menu_play.dispatch()
        position: new b2Vec2(65,35)
        content: (ctx) ->
          ctx.save()
          ctx.beginPath()
          ctx.fillStyle = "#ffffff"
          ctx.moveTo(-5,-5)
          ctx.lineTo(-5, 5)
          ctx.lineTo( 7, 0)
          ctx.lineTo(-5,-5)
          ctx.closePath()
          ctx.fill()
          ctx.restore()
      pause:
        function: -> Naubino.menu_pause.dispatch()
        content: (ctx) => @draw_pause_icon(ctx)
        position: new b2Vec2(65,35)
        disabled: true
        content: (ctx)->
          ctx.save()
          ctx.fillStyle = "#ffffff"
          ctx.beginPath()
          ctx.rect(-5,-6,4,12)
          ctx.rect( 1,-6,4,12)
          ctx.closePath()
          ctx.fill()
          ctx.restore()
      help:
        function: -> Naubino.menu_help.dispatch()
        content: (ctx) -> this.draw_string(ctx, '?')
        position: new b2Vec2(45,65)
      exit:
        function: -> Naubino.menu_exit.dispatch()
        content: (ctx) -> this.draw_string(ctx, 'X')
        position: new b2Vec2(14,80)
      }

    # fragile calibration! don't fuck it up!
    @fps = 1000 / 20
    @dt = @fps/100

    @add_buttons()
    @start_timer()

  mainloop: ()=>
    @draw()
    @draw_listener_region()
    @step()


  step: ->
    for name, naub of @objs
      naub.step (@dt)
      if @hovering
        naub.physics.gravitate()
      else
        naub.physics.gravitate(@position)


  ## can I touch this?

  move_pointer: (x,y) ->
    [@pointer.x, @pointer.y] = [x,y]


  add_buttons: ->
    @objs.main = new Naubino.Naub(this, null, @cube_size)
    @objs.main.physics.pos.Set(@position.x, @position.y)
    @objs.main.physics.attracted_to = @position.Copy()
    @objs.main.shape.size = @cube_size
    @objs.main.shape.render = @draw_main_button
    @objs.main.shape.pre_render()
    @objs.main.isClickable = no

    for name, attr of @buttons
      @objs[name] = new Naubino.Naub(this)
      @objs[name].physics.pos.Set attr.position.x, attr.position.y
      @objs[name].physics.attracted_to.Set attr.position.x, attr.position.y
      @objs[name].content = attr.content
      #@objs[name].shape.set_color_id 2
      @objs[name].shape.pre_render()
      @objs[name].focus = attr.function
      @objs[name].disable() if attr.disabled
      join = @objs[name].join_with( @objs.main, name )
      Naubino.graph.remove_join join

  switch_to_playing: ->
    console.log 'switching menu to playing mode'
    @objs.play.disable()
    @objs.pause.enable()

  switch_to_paused: ->
    console.log 'switching menu to paused mode'
    @objs.play.enable()
    @objs.pause.disable()


  draw: ->
    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
    @ctx.save()
    for name, naub of @objs
      naub.draw_joins(@ctx)if not naub.disabled
      naub.draw(@ctx) if not naub.disabled
    @objs.main.draw(@ctx)
    @objs.main.draw_joins()
    @draw_listener_region()
    @ctx.restore()


  draw_main_button: (ctx, x, y) ->

    ctx.save()
    ctx.translate(x,y)
    ctx.rotate(Math.PI/6)
    ctx.beginPath()
    ctx.rect( -@size/2, -@size/2, @size, @size)
    ctx.fillStyle = @color_to_rgba @style.fill
    ctx.fill()
    ctx.closePath()
    ctx.restore()

    ctx.save()
    ctx.translate(x,y)
    ctx.fillStyle = 'white'
    ctx.textAlign = 'center'
    ctx.font= 'bold 33px Helvetica'
    ctx.fillText(Naubino.game.points, 0,10, @size)
    ctx.restore()

  draw_listener_region: ->
    @ctx.save()
    @ctx.beginPath()
    @ctx.arc 0, 15, @listener_size, 0, Math.PI*2, true
    if @ctx.isPointInPath(@pointer.x,@pointer.y)
      unless @hovering
        #@hovering =  true
        Naubino.menu_focus.dispatch()
        @listener_size = 90
    else if @hovering
      #@hovering = false
      Naubino.menu_blur.dispatch()
      @listener_size = @default_listener_size
    #@ctx.stroke()
    @ctx.closePath()
    @ctx.restore()

