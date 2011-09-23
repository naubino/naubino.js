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
    @inner_clock = (@inner_clock + 1) % 10
    if @inner_clock == 0
      Naubino.game.create_naub_pair()
      console.log "new naubs!"


  # called when exiting playing state
  clear: ->
    Naubino.game.clear()
    Naubino.graph.clear()
    Naubino.game.points = 0
