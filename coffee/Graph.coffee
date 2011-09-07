class Graph
  constructor: () ->
    @joins_count = 0
    @joins = {}

  add_join: (a,b) ->
    @joins_count++
    join = [ a.number, b.number ]
    @joins[@joins_count] = join
    @joins_count

  remove_join: (id)->
    delete @joins[id]


  join_list: ->
    console.log "joinList"
    console.log join for id, join of @joins

  dotty: ->
    dot =  "graph G {\n"
    joins = for id, join of @joins
      join[0] + " -- " + join[1]
    dot += joins.join("\n") + "}"
    console.log dot


