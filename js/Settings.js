(function() {

  define(function() {
    var Settings;
    return Settings = {
      graphics: {
        fps: 35,
        fps_menu: 20,
        draw_shadows: false,
        updating: true
      },
      naub: {
        size: 14,
        mass: 4,
        mass_menu: 40,
        border: false,
        fondness: 12
      },
      physics: {
        fps: 60,
        calming_const: 0.5,
        gravity: {
          menu: true,
          game: true
        },
        margin: 1.2,
        join_length: 3.0,
        spring_force: 0.6,
        friction: 5.0
      },
      canvas: {
        scale: 1,
        width: 800,
        height: 480
      },
      events: [
        {
          name: 'init',
          from: 'none',
          to: 'stopped'
        }, {
          name: 'play',
          from: 'stopped',
          to: 'playing'
        }, {
          name: 'play',
          from: 'paused',
          to: 'playing'
        }, {
          name: 'pause',
          from: 'playing',
          to: 'paused'
        }, {
          name: 'stop',
          from: 'playing',
          to: 'stopped'
        }, {
          name: 'stop',
          from: 'paused',
          to: 'stopped'
        }
      ],
      layer_events: [
        {
          name: 'play',
          from: '*',
          to: 'playing'
        }, {
          name: 'pause',
          from: 'playing',
          to: 'paused'
        }, {
          name: 'stop',
          from: 'playing',
          to: 'stopped'
        }, {
          name: 'stop',
          from: 'paused',
          to: 'stopped'
        }
      ],
      colors: {
        output: [[229, 53, 23, 1, "red"], [151, 190, 13, 1, "green"], [0, 139, 208, 1, "blue"], [255, 204, 0, 1, "yellow"], [226, 0, 122, 1, "pink"], [100, 31, 128, 1, "purple"], [41, 14, 3, 1, "tell me"]],
        high_contrast: [[255, 0, 0, 1, "hcred"], [0, 224, 0, 1, "hcgreen"], [0, 128, 224, 1, "hcblue"], [255, 255, 0, 1, "hcyellow"], [0, 0, 0, 1, "hcblack"], [128, 0, 128, 1, "hcpurple"]],
        normal_colors: [[255, 0, 0, 1, "red"], [255, 153, 0, 1, "Vitamin C"], [0, 153, 204, 1, "Office Blue"], [0, 204, 0, 1, "Astroturf"], [255, 255, 0, 1, "Yellow"]],
        cuddle_bunny: [[174, 49, 45, 1, "cuddling red"], [75, 136, 95, 1, "cuddling green"], [73, 37, 13, 1, "midnight fudge"], [173, 165, 64, 1, "cuddling yellow"], [202, 202, 182, 1, "ill beige"]],
        '70': [[191, 73, 73, 1], [166, 30, 30, 1], [38, 110, 128, 1], [255, 232, 222, 1], [41, 14, 3, 1, "tell me"]],
        lip: [[125, 97, 83, 1], [147, 208, 189, 1], [82, 195, 193, 1], [246, 153, 167, 1], [198, 190, 99, 1]]
      }
    };
  });

}).call(this);
