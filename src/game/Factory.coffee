import {Naub} from "./Naub"
import {Util} from '../core/Util'
import {Ball, Box, Frame, FrameCircle} from "./Shapes"
import {Clock, StringShape} from "./Shapes"
import {PlayButton, PauseButton} from "./Shapes"

export class Factory
  constructor: (@layer, @world) ->

  add_button: (pos, callback, shapes) =>
    ball = new Ball
    naub = new Naub @layer, null
    naub.pos = naub.fixed_pos = pos

    naub.add_shape ball
    naub.add_shapes shapes
    naub.focus = callback
    naub.disabled = true
    naub.isClickable = yes
    naub.update()

    naub


  # factory for a naub ball
  #
  # @param pos [cp.v] position
  # @param color [int]  color_id
  add_ball: (pos = @random_outside(), color = null) =>
    naub = new Naub @layer, color
    ball = new Ball

    naub.add_shape ball
    naub.setup_physics()
    naub.physical_body.setPos( pos.Copy() ) # remember to set position
    naub.kind = 'ball'

    @world.add_object naub
    #naub.add_shape new NumberShape
    #naub.update() # again just to get the numbers
    naub


  # factory for a naub box
  #
  # @param pos [cp.v] position
  # @param color [int]  color_id
  add_box: (pos = @random_outside(), color = null) =>
    naub = new Naub @layer, color
    box = new Box

    naub.add_shape box
    naub.setup_physics()
    # turn a circle into a box
    box.adjust_physics()

    naub.physical_body.setPos( pos.Copy() ) # remember to set position
    naub.kind = 'box'
    naub.life_rendering = on

    @world.add_object naub
    #naub.add_shape new NumberShape
    #naub.update() # again just to get the numbers
    naub

  # create a pair of joined naubs
  #
  # @default
  # @param x [int] x-ordinate
  # @param y [int] y-ordinate
  # @param color [int] color id of naub 1
  # @param color [int] color id of naub 2
  # IMPLICIT if game has a @max_colors int random colors will only be picked out range [1..@max_colors]
  create_naub_pair: (pos = null, color_a = null, color_b = null, boxes = 0) =>
    pos = @random_outside() unless pos?
    dir = Math.random() * Math.PI
    pos_a = pos.Copy()
    pos_b = pos.Copy()

    pos_a.AddPolar(dir,  15)
    pos_b.AddPolar(dir, -15)

    if boxes == 0
      factory1 = factory2 = @add_ball
    else if boxes == 1
      factory1 = @add_ball
      factory2 = @add_box
    else
      factory1 = factory2 = @add_box

    naub_a = factory1 pos_a, color_a
    naub_b = factory2 pos_b, color_b

    @world.join naub_a, naub_b, true
    [naub_a, naub_b]

  # create a triple of joined naubs
  #
  # works almost like create_naub_pair
  # @param x [int] x-ordinate
  # @param y [int] y-ordinate
  create_naub_triple: (pos = null, color_a = null, color_b = null, color_c = null) =>
    pos = @random_outside() unless pos?
    dir = Math.random() * Math.PI
    pos_a = pos.Copy()
    pos_b = pos.Copy()
    pos_c = pos.Copy()

    pos_a.AddPolar(dir,  30)
    pos_c.AddPolar(dir, -30)

    naub_a = @add_ball pos_a, color_a
    naub_b = @add_ball pos_b, color_b
    naub_c = @add_ball pos_c, color_c

    @world.join naub_a, naub_b
    @world.join naub_b, naub_c
    [naub_a, naub_b, naub_c]

  #create n sets of matching pairs and some leftovers
  #
  # @param count [int] number of matching pairs
  # @param extras [int] number of leftovers
  create_matching_naubs: (count = 1, extras = 0) ->
    for [1..count]
      colors = Util.shuffle [0..5]
      colors[5] = colors[0]
      index = 0
      while index < colors.length - 1
        pos = @random_outside()
        @create_naub_pair pos, colors[index], colors[index + 1]
        index++
    #create some extras
    if extras > 0
      for [1..extras]
        pos  = @random_outside()
        #Naubino.background.draw_marker(x,y)
        @create_naub_pair(pos)


  # produces a random set of coordinates outside the field
  random_outside: ->
    offset = @layer.config?.game?.creation_offset ? Naubino.settings.game.creation_offset
    bounds = @layer.view_bounds ? {left: 0, top: 0, right: @layer.width, bottom: @layer.height}
    width = bounds.right - bounds.left
    height = bounds.bottom - bounds.top
    seed = Math.round (Math.random() * 3)+1
    switch seed
      when 1
        x = bounds.right + offset
        y = bounds.top + height * Math.random()
      when 2
        x = bounds.left + width * Math.random()
        y = bounds.bottom + offset
      when 3
        x = bounds.left - offset
        y = bounds.top + height * Math.random()
      when 4
        x = bounds.left + width * Math.random()
        y = bounds.top - offset
    new cp.v x,y

  #returns a random
  random_factory: ->
    factories = [
      @add_ball
      @add_box
    ]
    #console.log 'i',
    i = Math.floor(Math.random() * (factories.length))
    factories[i]
