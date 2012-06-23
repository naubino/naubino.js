# all colors (except color_output) found at colorlovers.com
define -> Settings = {

  graphics:
    fps:           40 # mind physics.fps
    updating:      off
    draw_shadows:  off
    draw_borders:  off

  game:
    creation_offset: 50
    min_joining_force: 800

  naub:
    size:          36
    margin:        3
    mass:          5
    friction:         0.8
    elasticity:    0.3
    min_join_len:  1.2 # times size
    max_join_len:  2 # times size

  physics:
    fps:            50
    center_join:
      restLength:   20
      stiffness:    10
      damping:      0.1
    calming_const:  0.5
    join_length:    3.0 # margin between joined naubs (n* avg size)
    spring_force:   0.6
    damping:        0.1

  canvas:
    scale:         1 # not yet implemented
    width:         800
    height:        480

  events: [
        { name: 'init',   from: 'none',     to: 'stopped'}
        # { name: 'unset',  from: 'stopped',  to: 'none'   } # TODO REMOVE THIS 
        { name: 'play',   from: 'stopped',  to: 'playing'}
        { name: 'play',   from: 'paused',   to: 'playing'}
        { name: 'pause',  from: 'playing',  to: 'paused' }
        { name: 'stop',   from: 'playing',  to: 'stopped'}
        { name: 'stop',   from: 'paused',   to: 'stopped'}
      ]

  layer_events: [
        { name: 'play',   from: ['paused','stopped'],  to: 'playing'}
        { name: 'pause',  from: 'playing',  to: 'paused' }
        { name: 'stop',   from: 'playing',  to: 'stopped'}
        { name: 'stop',   from: 'paused',   to: 'stopped'}
      ]

  color: "output"
  colors:
    #please sort colors by
    # red
    # green
    # blue
    # yellow
    # misc...
    # a palett must have at least 5 colors
    output: [
    # [RRR, GGG, BBB, alpha, name,    is_background,    is_joincolor ]
      [229,  53,  23, 1, "red"      ]
      [151, 190,  13, 1, "green"    ]
      [  0, 139, 208, 1, "blue"     ]
      [255, 204,   0, 1, "yellow"   ]
      [226,   0, 122, 1, "pink"     ]
      [100,  31, 128, 1, "purple"   ]
      [ 41,  14,   3, 1, "tell me"  ] # (brown)
    ]
    high_contrast: [
      [255,   0,   0, 1, "hcred"    ]
      [  0, 224,   0, 1, "hcgreen"  ]
      [  0, 128, 224, 1, "hcblue"   ]
      [255, 255,   0, 1, "hcyellow" ]
      [  0,   0,   0, 1, "hcblack"  ]
      [128,   0, 128, 1, "hcpurple" ]
    ]
    pop_is_everything: [
      [ 255,   0, 170, 1, "Hue 320 Degrees"]
      [ 170, 255,   0, 1, "Hue 80 Degrees"]
      [   0, 170, 255, 1, "Hue 200 Degrees"]
      [ 255, 170,   0, 1, "Norad Orange"]
      [ 170,   0, 255, 1, "Hue 280 Degrees"]
    ]
    normal_colors: [
      [255,   0,   0, 1, "red"         ]
      [255, 153,   0, 1, "Vitamin C"   ]
      [  0, 153, 204, 1, "Office Blue" ]
      [  0, 204,   0, 1, "Astroturf"   ]
      [255, 255,   0, 1, "Yellow"      ]
      [  0,   0,   0, 1, "black" ]
    ]
    cuddle_bunny: [ # http://www.colourlovers.com/palette/124912/Cuddle_Bunny
      [174,  49,  45, 1, "cuddling red"    ]
      [ 75, 136,  95, 1, "cuddling green"  ]
      [ 73,  37,  13, 1, "midnight fudge"  ]
      [173, 165,  64, 1, "cuddling yellow" ]
      [202, 202, 182, 1, "ill beige"       ]
      [  0,   0,   0, 0.5, "black" ]
    ]
    '70': [ # http://www.colourlovers.com/palette/1712615/70
      [191,  73,  73, 1]
      [166,  30,  30, 1]
      [ 38, 110, 128, 1]
      [255, 232, 222, 1]
      [ 41,  14,   3, 1, "tell me"]
      [  0,   0,   0, 1, "black" ]
    ]
    lip: [
      [125,  97,  83, 1]
      [147, 208, 189, 1]
      [ 82, 195, 193, 1]
      [246, 153, 167, 1]
      [198, 190,  99, 1]
      [240, 240, 240, 1, "black" ]
    ]
    # http://www.colourlovers.com/palette/1763674/The_Hearth#
    # http://www.colourlovers.com/palette/1740916/lip
    # http://www.colourlovers.com/palette/1763676/DeepSeaNEONS
    # http://www.colourlovers.com/palette/1763669/neon_spring
    # http://www.colourlovers.com/palette/373610/mellon_ball_surprise
    # http://www.colourlovers.com/palette/1473/Ocean_Five
    # http://www.colourlovers.com/palette/705921/Spring_Birds
    # http://www.colourlovers.com/palette/2223536/Luxury
    # http://www.colourlovers.com/palette/845564/its_raining_love
    # http://www.colourlovers.com/palette/694737/Thought_Provoking
    # http://www.colourlovers.com/palette/1930/cheer_up_emo_kid



}
