class Graph
  constructor: () ->
    @joins_count = 0
    @naubs = []
    @joins = {}

  update_naub_list: () ->
    @naubs = []
    for id, join of @joins
      for i in [0..1]
        unless join[i] in @naubs
          @naubs.push join[i]

  add_join: (a,b) ->
    @joins_count++
    join = [ a.number, b.number ]
    @joins[@joins_count] = join
    @joins_count

  remove_join: (id)->
    delete @joins[id]


  join_list: ->
    console.log "joinList"
    for id, join of @joins
      console.log id + " " + join

  dotty: ->
    dot =  "graph G {\n"
    joins = for id, join of @joins
      join[0] + " -- " + join[1]
    dot += joins.join("\n") + "}"
    console.log dot
  
  dfs: (naub) ->
    for id, join of @joins
      if naub in join
        index = join.indexOf naub
        partner = join[index^1]
        console.log naub + " -> " + partner

  cycle_test: ->


