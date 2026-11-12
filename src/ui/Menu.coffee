# TODO clean up menu code
import {Layer} from "../core/Layer"
import {Graph} from "../game/Graph"
import { SoundButton, PlayButton, PauseButton, MainButton, ClearButton } from "../game/Shapes"
import {Factory} from "../game/Factory"

export class Menu extends Layer
  DEFAULT_STEP_RATE = 40

  constructor: (canvas, @events = Naubino.events) ->
    super(canvas)
    @name = "menu"
    @graph = new Graph this
    @factory = new Factory this

    @objects = {}
    @hovering = off
    @opened_without_interaction = no

    @listener_size = @default_listener_size = 45
    @events.menu.button.active = false

    @center = new cp.v(20,25)
    @cube_size = 45
    @default_fps = @fps = 35
    @min_fps = 15
    @min_step_rate= 15


    @min_fps = 3

    @step_rate = @default_step_rate = DEFAULT_STEP_RATE

    @setup_fsm()

  dispose: ->

    clearTimeout @deactivation_timeout if @deactivation_timeout?
    @stop_stepping()
    @stop_drawing()

  # changing the state a little
  oninit: ->
    @add_buttons()
    @start_stepping()
    @start_drawing()
    @deactivate_menu()

  buttons:
    main:
      position:  new cp.v(23,26)
      function: -> #console.info "menu"
      shapes: [new MainButton]
      #shapes: []
    play:
      command: 'play'
      position: new cp.v(70,32)
      shapes: [ new PlayButton]
    mute:
      function: -> Naubino.settings.toggle 'audio.muted'
      position: new cp.v(55,65)
      shapes: [new SoundButton -> Naubino.settings.audio.muted]
    exit:
      command: 'stop'
      position: new cp.v(20,80)
      shapes: [new ClearButton]

  command_callback: (command) -> => @events.commands[command].dispatch()

  add_buttons: ->
    for name, button of @buttons
      callback = if button.command? then @command_callback(button.command) else button.function
      @objects[name] = @factory.add_button button.position, callback, button.shapes
    @objects.main.life_rendering = on

  check_game_state: (game = Naubino.game) ->
    #console.log "checking game state"
    if @objects.play?
      if game.current == "playing"
        @objects.play.focus = => @events.commands.pause.dispatch()
        @objects.play.shapes.pop()
        @objects.play.add_shape new PauseButton
        @objects.play.update()
      else
        @objects.play.focus = => @events.commands.play.dispatch()
        @objects.play.shapes.pop()
        @objects.play.add_shape new PlayButton
        @objects.play.update()
      @draw()

  step: ->
    for name, naub of @objects
      if @hovering
        naub.pos = cp.v.lerp(naub.pos, naub.fixed_pos, 0.1) unless name == "main"
        naub.isClickable = yes if naub.pos == naub.fixed_pos
      else
        naub.pos = cp.v.lerp(naub.pos, @center, 0.15) unless name == "main"
        naub.isClickable = no

  ## can I touch this?
  accepts_pointer: (position) ->
    in_listener_region = Math.hypot(position.x, position.y - 15) < @listener_size
    over_button = no
    if @hovering
      for naub_name, naub of @objects when naub.isHit(cp.v(position.x, position.y))
        over_button = yes
        break
    in_listener_region or over_button

  pointer_start: (position) ->
    @click position.x, position.y
    yes

  pointer_end: -> @mousedown = no

  move_pointer: (x,y) =>
    @opened_without_interaction = no
    [@pointer.x, @pointer.y] = [x,y]
    @draw_listener_region()

  click: (x, y) =>
    @mousedown = true
    @opened_without_interaction = no
    # touch has no preceding mousemove, so the pointer may be stale
    [@pointer.x, @pointer.y] = [x, y]
    @draw_listener_region()

    for name, naub of @objects
      if naub.isHit @pointer
        naub.focus()
        @focused_naub = naub
        break

  open: ->
    @opened_without_interaction = yes
    @activate_menu()

  draw: ->
    @draw_menu()
    @draw_listener_region()

  draw_menu: ->
    return unless @objects.main?
    @clear()
    @ctx.save()
    for name, naub of @objects
      naub.draw_join(@ctx,@objects.main)
      naub.draw(@ctx)
    @objects.main.draw(@ctx)
    @objects.main.draw_joins()
    @ctx.restore()

  activate_menu: ->
    @hovering = on

    if @deactivation_timeout?
      clearTimeout @deactivation_timeout
      @deactivation_timeout = null
    else
      @refresh_draw_rate @default_fps
      @start_stepping()

    @listener_size = 90

  deactivate_menu: ->
    @hovering = off

    @for_each (b) -> b.isClickable = no
    @listener_size = @default_listener_size

    unless @deactivation_timeout?
      @deactivation_timeout = setTimeout (
        =>
          @stop_stepping()
          @deactivation_timeout = null
      ),1000



  draw_listener_region: ->
    # isPointInPath works in device pixels, the pointer is in game units
    inside = Math.hypot(@pointer.x, @pointer.y - 15) < @listener_size

    if inside or @opened_without_interaction
      @activate_menu() unless @hovering
    else
      @deactivate_menu() if @hovering
