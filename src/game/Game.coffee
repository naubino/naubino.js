# controlls everything that has to do with logic and gameplay or menus
# @extends Layer
import {Layer} from "../core/Layer"
import {World} from "./World"
import {Naub} from "./Naub"
import {Graph} from "./Graph"
import {CollisionHandler} from "./CollisionHandler"
import {Factory} from "./Factory"
import {DragSystem} from "./DragSystem"
import {Mode} from "../modes/Mode"
import {GameEvents} from "../Events"

export class Game extends Layer

  # get this started
  constructor: (canvas, @mode = new Mode, @app_events = Naubino.events) ->
    super(canvas)
    @events = new GameEvents
    @timeouts = new Set
    @disposed = no
    @config = @build_config()
    @world = new World(@width, @height, @config.physics)
    @expose_world()
    @version = @mode.version
    @mode_id = @mode.id
    @name = "game"
    @variable_timestep = yes
    @use_raf = yes
    @graph = new Graph(this)
    @factory = new Factory(this)
    @join_policy = @mode.join_policy this
    @drag = new DragSystem(this)
    @space.defaultHandler = new CollisionHandler this


    # display stuff
    @focused_naub = null # points to the naub you click on

    #@points = -1
    @joining_allowed = yes

    @joining_naubs = []
    @replacing_naubs = []
    @active_tree = []

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

    @subscriptions = [
      @app_events.commands.play.add => @play()
      @app_events.commands.pause.add => @pause()
      @app_events.commands.stop.add (force) => @stop force
      @app_events.commands.toggle.add => @toggle()
      @app_events.input.two_finger_tap.add => @toggle()
    ]

    # last, rules may want everything above
    @rules = @mode.rules this
    @mode_unsubscribe = @mode.bind this, @app_events


  build_config: ->
    game = Object.assign {}, Naubino.settings.game, @mode.game_config ? {}
    physics_overrides = @mode.physics_config ? {}
    physics = Object.assign {}, Naubino.settings.physics, physics_overrides
    physics.center_join = Object.assign {}, Naubino.settings.physics.center_join, physics_overrides.center_join ? {}
    {game, physics}

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

  onplaying: (e,f,t) ->
    rule.start() for rule in @rules
    @checking = setInterval @check, 300 unless @checking
    @mode.playing this, f
    return

  onleaveplaying: ->
    rule.stop() for rule in @rules
    @mode.stop? this
    clearInterval @checking
    @checking = null
    return

  # recurring check (@checking)
  check: =>
    rule.check() for rule in @rules
    return


  resize: (@width, @height) ->
    # Springs must follow the field's new center.
    center = @center()
    @for_each (naub) ->
      naub.center = center.Copy()
      naub.constraints?.center?.anchr2 = center.Copy()

  score_snapshot: -> @mode.result this

  publish_snapshot: ->
    @events.score_changed.dispatch @points ? 0
    @events.level_changed.dispatch @levels?.level ? 0
    @events.basket_changed.dispatch @basket?.basket_size()




  onchangestate: (event, from, to) ->
    @events.state_changed.dispatch to
    if to is 'finished'
      snapshot = @completed_snapshot
      @completed_snapshot = null
      @events.finished.dispatch snapshot

  # Forced stops skip the mode's confirmation.
  onbeforestop: (event, from, to, force = no) ->
    return false if @disposed
    @completed_snapshot = null
    return false unless force or @mode.confirm_stop()
    @completed_snapshot = @score_snapshot()
    true

  onstop: ->
    @stop_stepping()
    @stop_drawing()
    @cancel_destroy_batches()
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

  clear_timeout: (timeout_id) ->
    return unless timeout_id?
    clearTimeout timeout_id
    @timeouts.delete timeout_id

  dispose: ->
    return if @disposed
    @disposed = yes
    rule.stop() for rule in @rules
    @mode.stop? this
    @mode_unsubscribe?()
    @mode_unsubscribe = null
    @mode.dispose? this
    @stop_stepping()
    @stop_drawing()
    clearInterval @checking if @checking?
    @checking = null
    clearInterval @fadeloop if @fadeloop?
    @fadeloop = null
    clearTimeout timeout_id for timeout_id from @timeouts
    @timeouts.clear()
    @cancel_destroy_batches()
    @clear_objects()
    @clear()
    signal.active = no for signal in Object.values(@events)
    unsubscribe() for unsubscribe in @subscriptions
    @subscriptions = []


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
    0 < pos.x < @width and 0 < pos.y < @height

  schedule_timeout: (callback, delay) ->
    return if @disposed
    timeout_id = setTimeout((=>
      @timeouts.delete timeout_id
      callback() unless @disposed
    ), delay)
    @timeouts.add timeout_id
    timeout_id

  cancel_destroy_batches: ->
    @clear_timeout batch.timer for batch in (@destroy_batches ? []) when batch.timer?
    @destroy_batches = []
    @destroying_naubs = {}

  # destroys every naub in a list of IDs by calling its own destroy function
  destroy_naubs: (list) ->
    @destroy_batches ?= []
    @destroying_naubs ?= {}
    ids = []
    for id in list
      naub = @get_object id
      continue unless naub? and not naub.removed and not naub.destroying and not @destroying_naubs[id]
      naub.disable()
      @destroying_naubs[id] = yes
      ids.push id
    return unless ids.length

    batch = {ids, index: 0, timer: null}
    @destroy_batches.push batch
    destroy_next = =>
      return unless batch in @destroy_batches
      id = batch.ids[batch.index]
      naub = @get_object id
      if naub? and not naub.removed and not naub.destroying
        naub.destroy(batch.index == batch.ids.length - 1)
      else unless naub?
        delete @destroying_naubs[id]
      batch.index++
      if batch.index < batch.ids.length
        batch.timer = @schedule_timeout destroy_next, 120
      else
        @destroy_batches.splice @destroy_batches.indexOf(batch), 1
    destroy_next()


  # is one naub allowed to join with another
  check_joining: (a, b, arbiter) ->
    @join_policy.check_joining(a, b, arbiter)

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

    for id, obj of @objects
      obj.draw_joins @ctx
      obj.draw @ctx

    @ctx.restore()



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
        join_string = id.toString()
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




  add_object:(obj) ->
    obj.center = @center()
    number = @world.add_object obj
    obj.physical_body.naub_number = number if obj.physical_body?
    obj.physical_shape.naub_number = number if obj.physical_shape?
    obj.attracted_to @center()

  get_object: (id) -> @world.get_object id

  remove_obj: (id) ->
    delete @destroying_naubs[id] if @destroying_naubs?
    @world.remove_object id

  get_obj_in_pos: (pos) -> @world.naub_at pos

  clear_objects: ->
    naub.dispose?() for id, naub of @objects
    @world.clear @width, @height
    @expose_world()

  # run naub_forces, check for joinings and clean up
  step: (dt) ->
    @physics.step(dt, @pointer)

    for pair in @replacing_naubs
      pair[0].replace_with pair[1]
      #console.log "replacing #{pair[0].number} with #{pair[1].number}"

    for pair in @joining_naubs
      pair[0].join_with pair[1]
      #console.log "joinging #{pair[0].number} with #{pair[1].number}"

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
