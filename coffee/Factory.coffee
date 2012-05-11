define ["Naub", "Shapes"], (Naub,{ Ball, Box, Frame, FrameCircle, Clock, NumberShape, StringShape, PlayButton, PauseButton })-> class Factory
  constructor: (@layer) ->

  add_button: (callback, shapes) =>
    pos = @layer.center
    naub = @add_ball pos, null

    naub.kind = "button"
    naub.add_shapes shapes
    naub.focus = callback
    naub.disabled = true
    naub.isClickable = no
    naub.update()

    #@layer.graph.remove_join naub.join_with( @objects.main, name ) # add the object without managing the join
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

    @layer.add_object naub
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

    @layer.add_object naub
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
  create_naub_pair: (pos = null, color_a = null, color_b = null, mixed = off) =>
    pos = @random_outside() unless pos?
    dir = Math.random() * Math.PI
    pos_a = pos.Copy()
    pos_b = pos.Copy()

    #TODO auskommentiert
    #pos_a.AddPolar(dir,  15)
    #pos_b.AddPolar(dir, -15)

    if mixed
      factory1 = @random_factory()
      factory2 = @random_factory()
    else
      factory1 = factory2 = @add_ball

    naub_a = factory1 pos_a, color_a
    naub_b = factory2 pos_b, color_b

    naub_a.join_with naub_b
    [naub_a.color_id, naub_b.color_id]

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

    # TODO auskommentiert
    #pos_a.AddPolar(dir,  30)
    #pos_c.AddPolar(dir, -30)

    naub_a = @add_ball pos_a, color_a
    naub_b = @add_ball pos_b, color_b
    naub_c = @add_ball pos_c, color_c

    naub_a.join_with naub_b
    naub_b.join_with naub_c

  #create n sets of matching pairs and some leftovers
  #
  # @param n [int] number of matching pairs
  # @param extras [int] number of leftovers
  create_matching_naubs: (n=1,extras=0) ->
    for [1..n]
      colors = Util.shuffle [0..5]
      colors[5] = colors[0]
      i = 0
      while i < (colors.length )-1
        pos  = @random_outside()
        #Naubino.background.draw_marker(x,y)
        [a,b] = @create_naub_pair(pos, colors[i],colors[i+1], off)
        #console.log "pairing " + [a,b]
        i++
    #create some extras
    if extras > 0
      for [1..extras]
        pos  = @random_outside()
        #Naubino.background.draw_marker(x,y)
        @create_naub_pair(pos)


  # produces a random set of coordinates outside the field
  random_outside: ->
    offset = Naubino.settings.game.creation_offset
    seed = Math.round (Math.random() * 3)+1
    switch seed
      when 1
        x = @layer.width + offset
        y = @layer.height * Math.random()
      when 2
        x = @layer.width  * Math.random()
        y = @layer.height + offset
      when 3
        x = 0 - offset
        y = @layer.height * Math.random()
      when 4
        x = @layer.width * Math.random()
        y = 0 - offset
    new cp.v x,y

  #returns a random 
  random_factory: ->
    factories = [
      @add_ball
      @add_box
    ]
    console.log 'i', i = Math.floor(Math.random() * (factories.length))
    factories[i]

