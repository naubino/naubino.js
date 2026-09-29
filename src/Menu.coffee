# TODO clean up menu code -- will do in naub_rethought
import {Layer} from "./Layer"
import {Naub} from "./Naub"
import {Graph} from "./Graph"
import { Ball, StringShape, PlayButton, PauseButton, MainButton } from "./Shapes"
import {Factory} from "./Factory"

export class Menu extends Layer
  constructor: (canvas) ->
    super(canvas)
    @name = "menu"
    @graph = new Graph this
    @factory = new Factory this

    @objects = {}
    @hovering = off
    @opened_without_interaction = no

    @listener_size = @default_listener_size = 45
    Naubino.mousemove.add @move_pointer
    Naubino.mousedown.add @click
    Naubino.menu_button.active = false

    @center = new cp.v(20,25)
    @cube_size = 45
    @default_fps = @fps = 35
    @min_fps = 15
    @min_step_rate= 15


    @min_fps = 3

    @setup_fsm()

  # changing the state a little
  oninit: ->
    @add_buttons()
    @start_stepping()
    @start_drawing()

  buttons:
    main:
      position:  new cp.v(23,26)
      function: -> #console.info "menu"
      shapes: [new MainButton]
      #shapes: []
    play:
      function: -> Naubino.play()
      position: new cp.v(70,32)
      shapes: [new Ball, new PlayButton]
    help:
      function: -> alert("tutorial deactivated")#Naubino.tutorial()
      position: new cp.v(55,65)
      shapes: [new Ball, new StringShape "?", "white"]
    exit:
      function: -> Naubino.stop()
      position: new cp.v(20,80)
      shapes: [new Ball, new StringShape "X", "white"]

  add_buttons: ->
    @objects[name] = @factory.add_button(button.position, button.function, button.shapes) for name, button of @buttons
    @objects.main.life_rendering = on

  check_game_state: (game = Naubino.game) ->
    #console.log "checking game state"
    if @objects.play?
      if game.current == "playing"
        @objects.play.focus = -> Naubino.pause()
        @objects.play.shapes.pop()
        @objects.play.add_shape new PauseButton
        @objects.play.update()
      else
        @objects.play.focus = -> Naubino.play()
        @objects.play.shapes.pop()
        @objects.play.add_shape new PlayButton
        @objects.play.update()

  step: ->
    for name, naub of @objects
      if @hovering
        naub.pos = cp.v.lerp(naub.pos, naub.fixed_pos, 0.1) unless name == "main"
        naub.isClickable = yes if naub.pos == naub.fixed_pos
      else
        naub.pos = cp.v.lerp(naub.pos, @center, 0.15) unless name == "main"
        naub.isClickable = no

  ## can I touch this?
  move_pointer: (x,y) ->
    @opened_without_interaction = no
    [@pointer.x, @pointer.y] = [x,y]

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
    @ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height)
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

    @listener_size = 90

  deactivate_menu: ->
    @hovering = off

    @for_each (b) -> b.isClickable = no
    @listener_size = @default_listener_size

    unless @deactivation_timeout?
      @deactivation_timeout = setTimeout (
        =>
          @refresh_draw_rate @min_fps
          @deactivation_timeout = null
      ),1000



  draw_listener_region: ->
    # isPointInPath works in device pixels, the pointer is in game units
    inside = Math.hypot(@pointer.x, @pointer.y - 15) < @listener_size

    if inside or @opened_without_interaction
      @activate_menu() unless @hovering
    else
      @deactivate_menu() if @hovering
