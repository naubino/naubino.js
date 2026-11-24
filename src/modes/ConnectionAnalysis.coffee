import {Graph} from '../game/Graph'

export class ConnectionAnalysis
  constructor: (join_added, join_removed, naub_replaced, cycle_found) ->
    graph = new Graph
    @abort_controller = new AbortController

    {signal} = @abort_controller

    join_added.add ((id, first, second) -> graph.add_join id, first, second), signal
    join_removed.add ((id) -> graph.remove_join id), signal
    naub_replaced.add(((number) ->
      cycle_found.dispatch cycle for cycle in graph.cycle_test number
      return
    ), signal)

    @tree = (number) -> graph.tree number, [number]

  dispose: -> @abort_controller.abort()
