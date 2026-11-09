import {ColorScheme} from "./ColorScheme"

watchers = {}

resolve = (root, path) ->
  keys = path.split '.'
  last = keys.pop()
  obj = root
  obj = obj[key] for key in keys
  [obj, last]

export Settings = {

  audio:
    muted: no

  graphics:
    fps:           35 # mind stepper_rate
    updating:      yes
    draw_shadows:  on
    draw_borders:  no
    effects:       on
    fullscreen:    no
    show_fps:      no
    use_raf:       yes
    draw_constraints: no
    draw_pointer: no

  game:
    creation_offset: 50
    min_joining_force: 1000
    font: "Verdana"

  naub:
    size:          42
    margin:        8
    mass:          5
    friction:      0.1
    elasticity:    0.3
    min_join_len:  1.2 # times size
    max_join_len:  2 # times size

  step_rate:            60
  step_floor_rate:      30

  physics:
    center_join:
      restLength:   30
      stiffness:    7
      damping:      7
    join_length:    3.0 # margin between joined naubs (n* avg size)
    spring_force:   0.6
    damping:        0.1

  canvas:
    scale:         1 # not yet implemented
    width:         800
    height:        450

  events:

    # every state machine has these
    default:
      [
        { name: 'init',   from: ['none',  'stopped'], to: 'stopped'}
        { name: 'play',   from: ['paused','stopped'], to: 'playing'}
        { name: 'pause',  from: ['paused','playing'], to: 'paused' }
        { name: 'stop',   from: '*',                  to: 'stopped'}
        { name: 'toggle', from: ['playing'], to: 'paused'  }
        { name: 'toggle', from: ['paused'],  to: 'playing' }
        { name: 'toggle', from: ['playing'], to: 'paused'  }
        { name: 'toggle', from: ['paused'],  to: 'playing' }
        { name: 'toggle', from: ['stopped'], to: 'playing' }
      ]

    # game also has these:
    game:
      [
        { name: 'loose', from: 'playing', to: 'lost'    }
        { name: 'stop',  from: 'lost',    to: 'stopped' }
      ]

    # Backgraound also has these:
    background:
      [
        { name: 'pulse',       from: 'playing',       to: 'pulsing'      }
        { name: 'stop_pulse',  from: 'pulsing',       to: 'playing'      }
        { name: 'pause',       from: 'pulsing',       to: 'paused_pulse' }
        { name: 'play',        from: 'paused_pulse',  to: 'pulsing'      }
      ]

  menu:
    font: "Helvetica"
    color: "white"

  overlay:
    font: "Helvetica"
    color: "Black"
    fontsize:  25 # in px
    duration: 1 # in seconds
    fade_duration: 1 # in seconds

  color: "output"
  #plase sort colors by
  # red
  # green
  # blue
  # yellow
  # misc...
  # a palett must have 7 colors
  colors: {
    output: new ColorScheme({naubs:[
      # [RRR, GGG, BBB, alpha, name,    is_background,    is_joincolor ]
      [229,  53,  23, 1, "red"      ]
      [151, 190,  13, 1, "green"    ]
      [  0, 139, 208, 1, "blue"     ]
      [255, 204,   0, 1, "yellow"   ]
      [226,   0, 122, 1, "pink"     ]
      [100,  31, 128, 1, "purple"   ]
      [ 91,  42,   13, 1, "tell me"  ] # (brown)
      [ 61,  4,   3, 1, "tell me"  ] # (brown)
    ], warn: "red"})
    high_contrast: new ColorScheme({naubs: [
      [255,   0,   0, 1, "hcred"    ]
      [  0, 224,   0, 1, "hcgreen"  ]
      [  0, 128, 224, 1, "hcblue"   ]
      [255, 255,   0, 1, "hcyellow" ]
      [  0,   0,   0, 1, "hcblack"  ]
      [255, 255, 255, 1, "hcwhite"  ]
      [128,   0, 128, 1, "hcpurple" ]
    ], warn: "hcred"})
    pop_is_everything: new ColorScheme({naubs: [
     [ 255,   0, 170, 1, "Hue 320 Degrees"]
     [ 170, 255,   0, 1, "Hue 80 Degrees"]
     [   0, 170, 255, 1, "Hue 200 Degrees"]
     [ 255, 170,   0, 1, "Norad Orange"]
     [ 170,   0, 255, 1, "Hue 280 Degrees"]
    ], warn: 0})
    normal_colors: new ColorScheme({naubs: [
     [255,   0,   0, 1, "red"         ]
     [255, 153,   0, 1, "Vitamin C"   ]
     [  0, 153, 204, 1, "Office Blue" ]
     [  0, 204,   0, 1, "Astroturf"   ]
     [255, 255,   0, 1, "Yellow"      ]
     [  0,   0,   0, 1, "black" ]
    ]})
    #cuddle_bunny: new ColorScheme [ # http://www.colourlovers.com/palette/124912/Cuddle_Bunny
    #  [174,  49,  45, 1, "cuddling red"    ]
    #  [ 75, 136,  95, 1, "cuddling green"  ]
    #  [ 73,  37,  13, 1, "midnight fudge"  ]
    #  [173, 165,  64, 1, "cuddling yellow" ]
    #  [202, 202, 182, 1, "ill beige"       ]
    #  [  0,   0,   0, 0.5, "black" ]
    #]
    # http://www.colourlovers.com/palette/1712615/70 (modified & extended)
    '70': new ColorScheme({naubs: [
     [166,  30,  30, 1] # dr
     [ 38, 110, 128, 1] # lb
     [ 71,  44,  33, 1] # brown
     [188, 105, 105, 1] # lr
     [ 33,  66,  19, 1] # dg
     [ 12,  47,  56, 1] # db
     [110, 155,  88, 1] # lg
    ],
      light : { background: [237, 224, 194, 1, "70 cream"], foreground: [41, 14, 3, 1, "brown"] },
      dark: { background: [41, 14, 3, 1, "brown"], foreground: [237, 224, 194, 1, "70 cream"] }
    })
    # http://www.colourlovers.com/palette/433018 (EXTENDED)
    'Gasoline Rainbow': new ColorScheme({naubs: [
     [189,  42,  51, 1] # RED
     [147, 163,  28, 1] # GREEN
     [ 48,  55,  79, 1] # BLUE
     [214, 170,  38, 1] # YELLOW
     [ 64, 129,  86, 1] # CYAN
     [130,  65, 108, 1] # PURPLE
     [188,  86,  43, 1] # ORANGE
    ]})
    #lip: new ColorScheme [
    #  [125,  97,  83, 1]
    #  [147, 208, 189, 1]
    #  [ 82, 195, 193, 1]
    #  [246, 153, 167, 1]
    #  [198, 190,  99, 1]
    #  [240, 240, 240, 1, "black" ]
    #]
    # http://www.colourlovers.com/palette/1763674/The_Hearth#
    # http://www.colourlovers.com/palette/1763676/DeepSeaNEONS
    # http://www.colourlovers.com/palette/1763669/neon_spring
    # http://www.colourlovers.com/palette/373610/mellon_ball_surprise
    # http://www.colourlovers.com/palette/1740916/lip
    # http://www.colourlovers.com/palette/1473/Ocean_Five
    # http://www.colourlovers.com/palette/705921/Spring_Birds
    # http://www.colourlovers.com/palette/2223536/Luxury
    # http://www.colourlovers.com/palette/845564/its_raining_love
    # http://www.colourlovers.com/palette/694737/Thought_Provoking
    # http://www.colourlovers.com/palette/1930/cheer_up_emo_kid
  }
}

# Writes that should notify go through set/toggle. Plain reads stay as they are.
Settings.get = (path) ->
  [obj, key] = resolve Settings, path
  obj[key]

Settings.set = (path, value) ->
  [obj, key] = resolve Settings, path
  return value if obj[key] is value
  obj[key] = value
  cb value for cb in (watchers[path] ? []).slice()
  value

Settings.toggle = (path) -> Settings.set path, not Settings.get path

Settings.load_from_search = (search = '') ->
  params = new URLSearchParams search
  setBooleanParam = (name, path) ->
    value = params.get name
    return unless value is 'true' or value is 'false'
    Settings.set path, value is 'true'

  colorscheme = params.get 'colorscheme'
  Settings.set 'color', colorscheme if colorscheme? and Settings.colors[colorscheme]?
  switch params.get 'sounds'
    when 'on' then Settings.set 'audio.muted', no
    when 'off' then Settings.set 'audio.muted', yes
  if params.get('high_contrast') is 'true'
    Settings.set 'color', 'high_contrast'
    Settings.set 'graphics.draw_borders', yes
  setBooleanParam 'show_fps', 'graphics.show_fps'
  setBooleanParam 'draw_constraints', 'graphics.draw_constraints'

# returns an unsubscribe function
Settings.watch = (path, cb) ->
  (watchers[path] ?= []).push cb
  -> watchers[path] = watchers[path].filter (f) -> f isnt cb
