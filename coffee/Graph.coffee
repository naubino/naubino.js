Naubino.Graph = class Graph
  # TODO make more use of _
  constructor: () ->
    @join_id_sequence = 0 # sequential join id
    @naubs = []
    @joins = {}

  update_naub_list: () ->
    @naubs = []
    for id, join of @joins
      for i in [0..1]
        unless join[i] in @naubs
          @naubs.push join[i]

  add_join: (a,b) ->
    @join_id_sequence++
    join = [ a.number, b.number ]
    @joins[@join_id_sequence] = join
    @update_naub_list()
    @join_id_sequence

  remove_join: (id)->
    delete @joins[id]
    @update_naub_list()

  join_list: ->
    console.log "joinList"
    for id, join of @joins
      console.log id + " " + join

  dotty: -> # :D
    dot =  "graph G {\n"
    joins = for id, join of @joins
      join[0] + " -- " + join[1]
    dot += joins.join("\n") + "}"
    console.log dot
  
  # returns list of joined naubs expect a certain predecessor
  partners: (naub, pre = null) ->
    partners = []
    for id, join of @joins
      if naub in join
        unless pre in join
          partners.push join[(join.indexOf(naub))^1]
    partners



  cycle_test: (first) =>
    cycles = []

    @dfs_map = []
    @dfs_map[inaub] = {naub: inaub, dfs_num: 0, color: 0} for inaub in @naubs
    @seq_num = 1

    for inaub, {naub, dfs_num, color} of @dfs_map
      if dfs_num == 0
        dfs_cycle = @dfs(naub)
        cycles = _.union(cycles, dfs_cycle)
    return

  dfs: (naub, pre = null) ->
    cycles = []

    @dfs_map[naub].dfs_num = @seq_num
    @seq_num++
    @dfs_map[naub].color = 1

    for partner in @partners(naub,pre)
      if @dfs_map[partner].dfs_num == 0
        cycles = _.union(cycles, @dfs(partner,naub))

      if @dfs_map[partner].color == 1
        list =  @cycle_list(naub,partner)
        if list.length > 0
          Naubino.mode.cycle_found.dispatch(list)
    @dfs_map[naub].color = 2
    return cycles

  cycle_list: (v,w) ->
    cycle = _.select(@dfs_map, ({dfs_num, color})=> (dfs_num >= @dfs_map[w].dfs_num  && color == 1) )
    cycle.sort( (a,b) -> a.dfs_num - b.dfs_num)
    cycle_naubs = _.pluck(cycle, 'naub')
    return cycle_naubs



