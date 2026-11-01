import {Mode} from '../Mode'
import {Naub} from '../../Naub'
import {StringShape, Ball} from '../../Shapes'

# debug playground: numbered balls, no spawning, no losing
export class TestMode extends Mode

  init: (game) ->
    Naubino.settings.graphics.updating = off
    Naubino.settings.game.creation_offset = -200

    game.naub_replaced.add (number) -> game.graph.cycle_test(number)
    game.cycle_found.add (list) -> game.destroy_naubs(list)
    setTimeout (-> Naubino.play()), 300

  playing: (game, from) ->
    game.factory.create_matching_naubs() if from == "stopped"

    for [0..5]
      @add_ball game
    #Naubino.background.animation.play()
    #Naubino.background.start_stepper()

  add_ball: (game, pos = game.factory.random_outside(), color = null) ->
    naub = new Naub game, color
    ball = new Ball

    naub.add_shape ball
    naub.setup_physics()
    naub.physical_body.setPos( pos.Copy() ) # remember to set position
    naub.kind = 'ball'

    game.add_object naub
    #naub.add_shape new StringShape (-> naub.physical_body.m), 'white'
    naub.add_shape new StringShape naub.number, 'white'
    naub.update() # again just to get the numbers
    naub
