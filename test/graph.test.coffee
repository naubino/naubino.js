import {describe, it, expect, vi} from 'vitest'
import {Graph} from '../src/Graph'

naub = (number) -> {number}

make_layer = -> {cycle_found: {dispatch: vi.fn()}}

make_graph = (layer = make_layer()) -> new Graph(layer)

build = (graph, pairs) ->
  pairs.map (pair) -> graph.add_join(naub(pair[0]), naub(pair[1]))

dispatched_lists = (layer) ->
  layer.cycle_found.dispatch.mock.calls.map (call) -> call[0]

describe 'Graph', ->
  describe 'joins', ->
    it 'hands out sequential join ids starting at 1', ->
      graph = make_graph()
      expect(build(graph, [[1, 2], [2, 3]])).toEqual [1, 2]

    it 'lists every naub once in naubs', ->
      graph = make_graph()
      build(graph, [[1, 2], [2, 3], [3, 1]])
      expect(graph.naubs).toEqual [1, 2, 3]

    it 'remove_join drops the join and the naubs left without joins', ->
      graph = make_graph()
      build(graph, [[1, 2], [2, 3]])
      graph.remove_join 2
      expect(graph.joins).toEqual {1: [1, 2]}
      expect(graph.naubs).toEqual [1, 2]

    it 'remove_join keeps a naub that still has another join', ->
      graph = make_graph()
      build(graph, [[1, 2], [1, 3]])
      graph.remove_join 1
      expect(graph.naubs).toEqual [1, 3]

    it 'remove_join does not reuse the removed id', ->
      graph = make_graph()
      build(graph, [[1, 2], [2, 3]])
      graph.remove_join 1
      expect(graph.add_join(naub(3), naub(4))).toBe 3

    it 'remove_join with an unknown id changes nothing', ->
      graph = make_graph()
      build(graph, [[1, 2]])
      graph.remove_join 99
      expect(graph.joins).toEqual {1: [1, 2]}
      expect(graph.naubs).toEqual [1, 2]

    it 'clear resets joins, naubs and the id sequence', ->
      graph = make_graph()
      build(graph, [[1, 2], [2, 3]])
      graph.clear()
      expect(graph.joins).toEqual {}
      expect(graph.naubs).toEqual []
      expect(graph.add_join(naub(5), naub(6))).toBe 1

  describe 'partners', ->
    it 'returns the naubs joined to the given naub', ->
      graph = make_graph()
      build(graph, [[1, 2], [1, 3], [2, 3]])
      expect(graph.partners(1)).toEqual [2, 3]

    it 'excludes joins that contain pre', ->
      graph = make_graph()
      build(graph, [[1, 2], [1, 3], [2, 3]])
      expect(graph.partners(1, 2)).toEqual [3]
      expect(graph.partners(2, 3)).toEqual [1]

    it 'returns an empty list for a naub without joins', ->
      graph = make_graph()
      build(graph, [[1, 2]])
      expect(graph.partners(42)).toEqual []

    # quirk: a self-join [n, n] makes n its own partner (Graph.coffee partners)
    it 'lists a self-join as its own partner', ->
      graph = make_graph()
      build(graph, [[1, 1]])
      expect(graph.partners(1)).toEqual [1]

  describe 'tree', ->
    # quirk: the start naub appears in its own tree result whenever it has
    # a partner, because the walk comes back to it (Graph.coffee tree)
    it 'returns every naub reachable from the start, including the start', ->
      graph = make_graph()
      build(graph, [[1, 2], [2, 3]])
      expect(graph.tree(1)).toEqual [2, 1, 3]

    it 'returns every naub of a cycle from a middle naub', ->
      graph = make_graph()
      build(graph, [[1, 2], [2, 3], [3, 1]])
      expect(graph.tree(2)).toEqual [1, 2, 3]

    it 'leaves out naubs of other components', ->
      graph = make_graph()
      build(graph, [[1, 2], [3, 4]])
      expect(graph.tree(1)).toEqual [2, 1]

    it 'returns an empty list for a naub without joins', ->
      graph = make_graph()
      build(graph, [[1, 2]])
      expect(graph.tree(42)).toEqual []

  describe 'cycle_test', ->
    it 'returns undefined', ->
      graph = make_graph()
      build(graph, [[1, 2], [2, 3], [3, 1]])
      expect(graph.cycle_test(1)).toBeUndefined()

    it 'does not dispatch for a chain', ->
      layer = make_layer()
      graph = make_graph(layer)
      build(graph, [[1, 2], [2, 3]])
      graph.cycle_test 1
      expect(dispatched_lists(layer)).toEqual []

    it 'dispatches a triangle rotated to start at first', ->
      layer = make_layer()
      graph = make_graph(layer)
      build(graph, [[1, 2], [2, 3], [3, 1]])
      graph.cycle_test 2
      expect(dispatched_lists(layer)).toEqual [[2, 3, 1]]

    it 'dispatches a square with all four naubs when no first is given', ->
      layer = make_layer()
      graph = make_graph(layer)
      build(graph, [[1, 2], [2, 3], [3, 4], [4, 1]])
      graph.cycle_test()
      expect(dispatched_lists(layer)).toEqual [[1, 2, 3, 4]]

    it 'leaves a dangling tail out of the dispatched cycle', ->
      layer = make_layer()
      graph = make_graph(layer)
      build(graph, [[1, 2], [2, 3], [3, 1], [3, 4]])
      graph.cycle_test 2
      expect(dispatched_lists(layer)).toEqual [[2, 3, 1]]

    it 'dispatches the cycle unrotated when first is not in it', ->
      layer = make_layer()
      graph = make_graph(layer)
      build(graph, [[1, 2], [2, 3], [3, 1], [3, 4]])
      graph.cycle_test 4
      expect(dispatched_lists(layer)).toEqual [[1, 2, 3]]

    it 'dispatches each of two separate triangles once', ->
      layer = make_layer()
      graph = make_graph(layer)
      build(graph, [[1, 2], [2, 3], [3, 1], [4, 5], [5, 6], [6, 4]])
      graph.cycle_test()
      expect(dispatched_lists(layer)).toEqual [[1, 2, 3], [4, 5, 6]]

    # quirk: two joins between the same pair are not reported as a cycle,
    # because partners(naub, pre) drops every join containing pre
    # (Graph.coffee partners)
    it 'does not report parallel joins as a cycle', ->
      layer = make_layer()
      graph = make_graph(layer)
      build(graph, [[1, 2], [1, 2]])
      graph.cycle_test()
      expect(dispatched_lists(layer)).toEqual []
