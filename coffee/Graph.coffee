define -> class Graph
  constructor: (@layer) ->
    @join_id_sequence = 0 # sequential join id
    @naubs = []
    @joins = {}

  # updating naub list from joins since joins are more up to date
  update_naub_list: () ->
    @naubs = []
    for id, join of @joins
      for i in [0..1]
        unless join[i] in @naubs
          @naubs.push join[i]

  # adds the join between naub a and naub b
  #
  # @todo simplify update_naub_list
  # @param [Naub] a first and ...
  # @param [Naub] b ... second naub that connected
  add_join: (a,b) ->
    @join_id_sequence++
    join = [ a.number, b.number ]
    @joins[@join_id_sequence] = join
    @update_naub_list()
    @join_id_sequence

  # one of those functions where documentation could require more time than reading the actuall code
  #
  # @param [id] naub naub to be removed
  #
  remove_join: (id)->
    delete @joins[id]
    @update_naub_list()

  # another one of those functions where documentation could require more time than reading the actuall code
  clear: ->
    @join_id_sequence = 0
    @naubs = []
    @joins = {}

  # prints a list of all joins to console
  join_list: ->
    console.log "joinList"
    for id, join of @joins
      console.log id + " " + join

  # prints a dot file from graph :D to console
  dotty: -> # :D
    dot =  "graph G {\n"
    joins = for id, join of @joins
      join[0] + " -- " + join[1]
    dot += joins.join("\n") + "}"
    console.log dot

  # returns a list of naubs connected to the parameter
  #
  # @return [array] list of naubs connected to the parameter
  # @param [id] naub naub in question
  #
  # returns list of joined naubs expect a certain predecessor
  partners: (naub, pre = null) ->
    partners = []
    for id, join of @joins
      if naub in join
        unless pre in join
          partners.push join[(join.indexOf(naub))^1]
    partners

  # searches for cycles in the graph and returns a list of all naubs within a cycle
  #
  # this is the smartest in the entire programm
  # @param first [id] in order to remember which naub if the first in the cycle
  cycle_test: (first) =>
    cycles = []

    @dfs_map = []
    @dfs_map[inaub] = {naub: inaub, dfs_num: 0, color: 0} for inaub in @naubs
    @seq_num = 1

    for inaub, {naub, dfs_num, color} of @dfs_map
      if dfs_num == 0
        dfs_cycle = @dfs(naub, null, first)
        cycles = cycles.filter (x) -> x in dfs_cycle
    return



  tree: (naub, visited = null) ->
    visited = [] unless visited?
    for p in @partners naub
      unless p in visited
        visited.push p
        @tree(p, visited)

    return visited

  # recursive part of cycle_test
  #
  # @param [id] naub naub in question
  dfs: (naub, pre = null, first = null) ->
    cycles = []

    @dfs_map[naub].dfs_num = @seq_num
    @seq_num++
    @dfs_map[naub].color = 1

    for partner in @partners(naub,pre)
      if @dfs_map[partner].dfs_num == 0
        cycles = @dfs(partner,naub, first).filter (x) -> x in cycles

      if @dfs_map[partner].color == 1
        list =  @cycle_list(naub,partner,first)
        if list.length > 0
          @layer.cycle_found.dispatch(list)
    @dfs_map[naub].color = 2
    return cycles

  # returns all naubs that are part of a cycle in order of connection to the active naub
  #
  # @return [array] list of naubs
  cycle_list: (v,w,first = null) ->
    cycle = @dfs_map.filter ({dfs_num, color}) =>
      dfs_num >= @dfs_map[w].dfs_num && color == 1
    cycle.sort (a,b) -> a.dfs_num - b.dfs_num
    cycle_naubs = (x.naub for x in cycle)

    if first? and first in cycle_naubs
      cycle_naubs = cycle_naubs
      i = cycle_naubs.indexOf first
      cycle_naubs = cycle_naubs[i...cycle_naubs.length].concat(cycle_naubs[0...i])

    return cycle_naubs


