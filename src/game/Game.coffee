# controlls everything that has to do with logic and gameplay or menus
import {Layer, MAX_FRAME_TIME} from "../core/Layer"
import {Background} from "../ui/Background"
import {World} from "./World"
import {JoinPolicy} from "./JoinPolicy"
import {CollisionHandler} from "./CollisionHandler"

import {DragSystem} from "./DragSystem"
import {Mode} from "../modes/Mode"
import {GameEvents} from "../Events"

export class Game

  # get this started
  constructor: (@viewport, field_size, mode = new Mode,
    @config = mode.configuration(), @app_events = Naubino.events) ->
    {@width, @height} = field_size
    @world_center = new cp.v @width / 2, @height / 2
    @background_lease = @viewport.lease 0, 'canvas-background'
    @field_lease = @viewport.lease 1, 'canvas-game'
    @background = new Background @background_lease.canvas, @viewport
    @background.width = @width
    @background.height = @height
    @background.world_center = @world_center
    @background.init()
    @field_layer = new Layer @field_lease.canvas, @viewport
    @field_layer.name = 'game'
    @field_layer.hide()
    @field_layer.variable_timestep = yes
    @field_layer.use_raf = yes
    @field_layer.step = (dt) => @step dt
    @field_layer.draw = => @draw()
    @layers = [@background, this]

    @canvas = @field_layer.canvas
    @ctx = @field_layer.ctx
    @field_layer.width = @width
    @field_layer.height = @height
    @field_layer.world_center = @world_center
    @pointer = @world_center.Copy()
    @center = => @world_center.Copy()
    @fps = @field_layer.fps
    @step_rate = @field_layer.step_rate
    @name = 'game'
    @events = new GameEvents
    @timeouts = new Set
    @rules = []
    @started_rules = []
    @activated = no
    @rules_running = no
    @abort_controller = new AbortController
    @disposed = no
    @frame = {time: 0, dt: 0}
    @drawables = []
    @stage =
      add: (drawable, order, abort_signal) =>
        return if @disposed or abort_signal?.aborted
        entry = {drawable, order}
        @drawables.push entry
        @drawables.sort (first, second) -> first.order - second.order
        abort_signal?.addEventListener 'abort', (=>
          @drawables = @drawables.filter (candidate) -> candidate isnt entry
          return
        ), {once: yes, signal: @abort_controller.signal}
        return
    @resize @width, @height

    @world = new World(@width, @height, @config.physics, @events)
    @expose_world()

    @drag = new DragSystem(this)
    @space.defaultHandler = new CollisionHandler this


    # display stuff
    @focused_naub = null # points to the naub you click on


    @joining_allowed = yes

    @joining_naubs = []
    @replacing_naubs = []
    @active_tree = []
    field =
      center: @center
      view_bounds: => @view_bounds
    context = {
      config: @config
      world: @world
      events: @events
      input: @app_events.input
      field

      stage: @stage
    }
    @assembled = mode.assemble context
    @rules = @assembled.rules
    @join_policy = @assembled.join_policy ? new JoinPolicy @config.game
    @results = @assembled.results
    @connections = @assembled.connections

    StateMachine.create {
      target: this
      initial: 'ready'
      events: [
        {name: 'play', from: ['ready', 'paused'], to: 'playing'}
        {name: 'pause', from: 'playing', to: 'paused'}
        {name: 'toggle', from: ['ready', 'paused'], to: 'playing'}
        {name: 'toggle', from: 'playing', to: 'paused'}
        {name: 'stop', from: ['ready', 'playing', 'paused', 'lost'], to: 'finished'}
        {name: 'loose', from: 'playing', to: 'lost'}
      ]
      error: (event, from, to, args, code, message) =>
        console.error "#{@name}.#{event}: #{from} -> #{to}\n#{code}::#{message}"
    }

    {signal} = @abort_controller

    @events.loss_requested.add ((reason) => @loose reason if not @disposed and @can 'loose'), signal
    @viewport.field_resized.add ((width, height) => @resize width, height), signal
    @app_events.commands.play.add (=> @play()), signal
    @app_events.commands.pause.add (=> @pause()), signal
    @app_events.commands.stop.add ((force) => @stop force), signal
    @app_events.commands.toggle.add (=> @toggle()), signal
    @app_events.input.two_finger_tap.add (=> @toggle()), signal



  advance: (dt) ->
    return if @disposed
    if @current is 'playing'
      play_dt = Math.min dt, MAX_FRAME_TIME
      @frame.time += play_dt
      @frame.dt += play_dt
    @background.advance dt
    @field_layer.advance dt

  start_stepping: -> @field_layer.start_stepping()
  stop_stepping: -> @field_layer.stop_stepping()
  start_drawing: -> @field_layer.start_drawing()
  stop_drawing: -> @field_layer.stop_drawing()
  fade_out: (callback) -> @field_layer.fade_out callback
  clear: -> @field_layer.clear()
  scale_to: (scale) -> @field_layer.scale_to scale
  set_fps_label_depth: (depth) -> @field_layer.fps_label_depth = depth
  draw_point: (position, color) -> @field_layer.draw_point position, color
  move_pointer: (x, y) ->
    [@pointer.x, @pointer.y] = [x, y] if @mousedown


  # plenty of code still reads these off the game directly
  # rerun whenever the world swaps one out
  expose_world: ->
    @objects           = @world.objects
    @physics           = @world.physics
    @space             = @physics.space
    @mouseBody         = @physics.mouseBody
    @GRABABLE_MASK_BIT = @physics.GRABABLE_MASK_BIT
    @NOT_GRABABLE_MASK = @physics.NOT_GRABABLE_MASK

  onbeforeplay: -> not @disposed

  onbeforepause: -> not @disposed

  onbeforetoggle: -> not @disposed

  onbeforeloose: -> not @disposed

  onplaying: (event, from, to) ->
    return if @disposed or @rules_running
    unless @activated
      return unless from is 'ready'
      @activated = yes
      for rule in @rules
        return if @disposed or @current isnt 'playing'
        rule.activate?()
    return if @disposed or @current isnt 'playing'
    @field_layer.show()
    @start_drawing()
    @start_stepping()
    @rules_running = yes
    for rule in @rules
      return if @disposed or @current isnt 'playing'
      @started_rules.push rule
      rule.start?()
    return if @disposed or @current isnt 'playing'
    @checking = setInterval @check, 300 unless @checking
    return

  stop_rules: ->
    @rules_running = no
    started_rules = @started_rules
    @started_rules = []
    rule.stop?() for rule in started_rules
    return

  onleaveplaying: ->
    @stop_rules()
    clearInterval @checking
    @checking = null
    return

  onpaused: ->
    @stop_stepping()
    @stop_drawing()

  # recurring check (@checking)
  check: =>
    for rule in @rules
      return if @disposed or @current isnt 'playing'
      rule.check?()
    return


  resize: (width, height) ->
    return if @disposed
    @view_bounds =
      left: @world_center.x - width / 2
      top: @world_center.y - height / 2
      right: @world_center.x + width / 2
      bottom: @world_center.y + height / 2

  publish_scoreboard: ->
    return unless @results?
    {points, level} = @results.scoreboard()
    @events.score_changed.dispatch points
    @events.level_changed.dispatch level




  onchangestate: (event, from, to) ->
    @events.state_changed.dispatch to
    if to is 'finished'
      result = @completed_result
      @completed_result = null
      @events.finished.dispatch result

  confirm_stop: -> confirm "Do you really want to stop the game?"

  onbeforestop: (event, from, to, force = no) ->
    return false if @disposed
    @completed_result = null
    return false unless force or @confirm_stop()
    @completed_result = @results?.final() ? null
    true

  onstop: ->
    @stop_stepping()
    @stop_drawing()
    @clear_objects()
    @clear()

  onloose: (event, from, to, reason = 'Game Over') ->
    @stop_stepping()
    @events.lost.dispatch reason
    @run_loss_sequence()

  run_loss_sequence: ->
    naub_ids = Object.keys @objects
    grey_next = =>
      return if @disposed
      naub_id = naub_ids.shift()
      if naub_id?
        naub = @get_object naub_id
        naub.grey_out() if naub?
        @schedule_timeout grey_next, 150
      else
        @fade_out =>
          @schedule_timeout (=> @stop yes if @can 'stop'), 2000
    grey_next()


  dispose: ->
    return if @disposed
    @disposed = yes
    @stop_rules()
    rule.dispose?() for rule in @rules
    @stop_stepping()
    @stop_drawing()
    clearInterval @checking if @checking?
    @checking = null
    clearInterval @field_layer.fadeloop if @field_layer.fadeloop?
    @field_layer.fadeloop = null
    clearTimeout timeout_id for timeout_id from @timeouts
    @timeouts.clear()
    @clear_objects()
    @clear()
    @background.stop() if @background.can 'stop'
    @background.clear()
    @drawables = []
    @background_lease.release()
    @field_lease.release()
    signal.active = no for signal in Object.values(@events)
    @abort_controller.abort()


  focus: (naub) ->
    @clear_focus()
    return unless naub?
    @focused_naub = naub
    @active_tree = @connections?.tree(naub.number) ? [naub.number]
    @get_object(number).highlighted = true for number in @active_tree when @get_object(number)?
    naub.focus()
    return

  clear_focus: ->
    @get_object(number).highlighted = false for number in @active_tree when @get_object(number)?
    @focused_naub?.unfocus()
    @focused_naub = null
    @active_tree = []
    return

  pointer_start: (position) ->
    @click position.x, position.y
    yes

  pointer_end: -> @unfocus()

  # callback for mousedown signal
  click: (x, y) =>
    @mousedown = true
    @pointer = new cp.v x,y
    @drag.start(@pointer)

  # callback for mouseup signal
  unfocus: =>
    if @mousedown
      @mousedown = false
      @drag.stop()



  point_in_field: (pos) ->
    @view_bounds.left < pos.x < @view_bounds.right and @view_bounds.top < pos.y < @view_bounds.bottom

  schedule_timeout: (callback, delay) ->
    return if @disposed
    timeout_id = setTimeout((=>
      @timeouts.delete timeout_id
      callback() unless @disposed
    ), delay)
    @timeouts.add timeout_id
    timeout_id




  # is one naub allowed to join with another
  check_joining: (first, second, arbiter) ->
    return false unless @joining_allowed
    action = @join_policy.check_joining first, second, arbiter
    return false unless action?
    return false if action.action is 'join' and action.pair[0].number is @just_joined
    if action.action is 'replace'
      @replacing_naubs.push action.pair
    else
      @just_joined = action.pair[0].number
      @schedule_timeout (=> @just_joined = -1), 300
      @joining_naubs.push action.pair
    return true

  # draws everything that happens inside the field
  draw:  ->
    # clears the canvas before drawing
    @clear()
    # draws joins and naubs seperately
    @ctx.save()

    if Naubino.settings.graphics.draw_constraints
      @draw_constraints()
    if Naubino.settings.graphics.draw_pointer
      @draw_point @pointer
      # @draw_point @mouseBody.p, "blue"

    entry.drawable.draw @ctx, @frame for entry in @drawables when entry.order < 0
    naub.draw_joins @ctx for naub in @world.naubs()
    naub.draw @ctx for naub in @world.naubs()
    entry.drawable.draw @ctx, @frame for entry in @drawables when entry.order >= 0

    @ctx.restore()
    @frame.dt = 0
    return



  draw_constraints: ->
    for con, id in @space.constraints
      p1 = con.a.p
      p1 = con.anchr1 if p1.IsZero()
      p2 = con.b.p
      p2 = con.anchr2 if p2.IsZero()

      con_color = (con) ->
        switch con.name
          when "DampedSpring" then "red"
          when "SlideJoint"   then "blue"
          else "grey"

      if p1? and p2?
        @ctx.save()
        @ctx.strokeStyle = con_color con
        @ctx.moveTo p1.x, p1.y
        @ctx.lineTo p2.x, p2.y
        @ctx.stroke()
        @ctx.restore()
      if id?
        diff = p2.Copy()
        diff.sub(p1)
        # join_string = id.toString()
        join_string = Math.ceil(diff.Length())
        mid = cp.v.lerp(p1, p2, 0.5)
        @ctx.save()
        @ctx.translate mid.x,mid.y
        @ctx.rotate diff.Angle()
        @ctx.translate 0,-10
        @ctx.rotate 2*Math.PI - diff.Angle()
        @ctx.fillStyle = 'black'
        if con.a.isRogue() or con.b.isRogue()
          @ctx.fillStyle = 'red'
        @ctx.textAlign = 'center'
        @ctx.font= "10px Courier"
        @ctx.fillText(join_string, 0, 6)
        @ctx.restore()




  add_object: (obj) -> @world.add_object obj

  get_object: (id) -> @world.get_object id

  for_each: (callback) ->
    callback naub for naub_id, naub of @objects
    return

  remove_obj: (id) -> @world.remove_object id

  get_obj_in_pos: (pos) -> @world.naub_at pos

  clear_objects: ->
    @clear_focus()
    @world.clear @width, @height
    @expose_world()

  # run naub_forces, check for joinings and clean up
  step: (dt) ->
    @physics.step(dt, @pointer)

    for pair in @replacing_naubs
      @unfocus()
      @world.replace pair[0], pair[1]

    for pair in @joining_naubs
      @world.join pair[0], pair[1]

    @joining_naubs = []
    @replacing_naubs = []

    # delete objects
    for id, obj of @objects
      if obj.removed
        @remove_obj id
        @clean_up()

  clean_up: ->
    #console.log "clean up run"
    for con, id in @space.constraints
      if con? and con.IsRogue()
        @space.removeConstraint con
