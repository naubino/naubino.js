class Naubino.Graph
  # TODO make more use of _
  constructor: () ->
    @join_id_sequence = 0 # sequential join id
    @naubs = []
    @joins = {}

  ###
  updateing naub list from joins
  since joins are more up to date
  ###
  update_naub_list: () ->
    @naubs = []
    for id, join of @joins
      for i in [0..1]
        unless join[i] in @naubs
          @naubs.push join[i]

  ###
  adds the join between naub a and naub b
  TODO: simplify update_naub_list
  ###
  add_join: (a,b) ->
    @join_id_sequence++
    join = [ a.number, b.number ]
    @joins[@join_id_sequence] = join
    @update_naub_list()
    @join_id_sequence

  ###
  a comment explaining this function would require more bytes than the actuall function it self
  so I decided not to explain the function after all, I guess you got to figure it out by yourself
  ###
  remove_join: (id)->
    delete @joins[id]
    @update_naub_list()

  ###
  another one of those functions where documentation yould require more time than reading the actuall code
  good look
  ###
  clear: ->
    @join_id_sequence = 0
    @naubs = []
    @joins = {}

  ###
  logs a list of all joins ( for debugging )
  ###
  join_list: ->
    console.log "joinList"
    for id, join of @joins
      console.log id + " " + join

  ###
  creates a dot file from graph :D
  ###
  dotty: -> # :D
    dot =  "graph G {\n"
    joins = for id, join of @joins
      join[0] + " -- " + join[1]
    dot += joins.join("\n") + "}"
    console.log dot
  
  ###
  returns list of joined naubs expect a certain predecessor
  ###
  partners: (naub, pre = null) ->
    partners = []
    for id, join of @joins
      if naub in join
        unless pre in join
          partners.push join[(join.indexOf(naub))^1]
    partners

  ###
  this is the smartes function in the entire programm
  searches for cycles in the graph and returns a list of all naubs within a cycle
  ###
  cycle_test: (first) =>
    cycles = []

    @dfs_map = []
    @dfs_map[inaub] = {naub: inaub, dfs_num: 0, color: 0} for inaub in @naubs
    @seq_num = 1

    for inaub, {naub, dfs_num, color} of @dfs_map
      if dfs_num == 0
        dfs_cycle = @dfs(naub, null, first)
        cycles = _.union(cycles, dfs_cycle)
    return


  ###
  recursive part of cycle_test
  ###
  dfs: (naub, pre = null, first = null) ->
    cycles = []

    @dfs_map[naub].dfs_num = @seq_num
    @seq_num++
    @dfs_map[naub].color = 1

    for partner in @partners(naub,pre)
      if @dfs_map[partner].dfs_num == 0
        cycles = _.union(cycles, @dfs(partner,naub, first))

      if @dfs_map[partner].color == 1
        list =  @cycle_list(naub,partner,first)
        if list.length > 0
          Naubino.cycle_found.dispatch(list)
    @dfs_map[naub].color = 2
    return cycles

  ###
  returns the list for cycle_test
  ###
  cycle_list: (v,w,first = null) ->
    cycle = _.select(@dfs_map, ({dfs_num, color})=> (dfs_num >= @dfs_map[w].dfs_num  && color == 1) )
    cycle.sort( (a,b) -> a.dfs_num - b.dfs_num)
    cycle_naubs = _.pluck(cycle, 'naub')

    if first? and first in cycle_naubs
      cycle_naubs = cycle_naubs
      i = cycle_naubs.indexOf first
      cycle_naubs = cycle_naubs[i...cycle_naubs.length].concat(cycle_naubs[0...i])

    return cycle_naubs


