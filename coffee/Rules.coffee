Naubino.RuleSet = class RuleSet
  constructor: ->
    @inner_clock = 0 # to avoid resetting timer after pause
    Naubino.game.points = 0
    @configure()

  configure: ->
    Naubino.state_machine.naub_replaced.add =>
      Naubino.state_machine.graph.cycle_test()

    Naubino.state_machine.naub_destroyed.add =>
      Naubino.state_machine.game.points++

    Naubino.state_machine.cycle_found.add (list) =>
      Naubino.state_machine.game.destroy_naubs(list)
      console.log list



  # starts the game
  run: ->
    @loop = setInterval(@event, 300 )
    Naubino.background.draw()

  halt: ->
    clearInterval(@loop)

  # does whatever
  event: =>
    if @inner_clock == 0
      {x,y} = Naubino.game.random_outside()
      Naubino.game.create_naub_pair(x,y)
      console.log "new naubs!"
    @inner_clock = (@inner_clock + 1) % 10


  # called when exiting playing state
  clear: ->
    Naubino.game.clear()
    Naubino.graph.clear()
    Naubino.game.points = 0

Naubino.TestCase = class TestCase extends RuleSet
  constructor: ->
    super()
    Naubino.Settings.show_numbers = on
    Naubino.game.create_some_naubs 4
    weightless = ->
      Naubino.game.gravity = off
    setTimeout(weightless, 4000)
  run: ->
