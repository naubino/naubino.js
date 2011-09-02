class Graph
  constructor: () ->
    @joins_count = 0
    @joins = {}

  addJoin: (a,b) ->
    @joins_count++
    join = [ a.number, b.number ]
    @joins[@joins_count] = join
    @joins_count

# obsolete
#  getPartner: (id, naub) ->
#    if @joins[id][0] is naub.number
#      @joins[id][1]
#    else
#      @joins[id][0]

  joinList: ->
    console.log "joinList"
    console.log join for id, join of @joins
