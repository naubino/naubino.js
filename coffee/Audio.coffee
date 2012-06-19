define -> class Audio

  path: "sounds/"
  blubs:[]
  pool: 10
  i: 0

  blub_paths:  [
    "8000__cfork__cf-fx-bloibb"
    "8001__cfork__cf-fx-doppp-01"
    "8003__cfork__cf-fx-doppp-03-dry"
    "8008__cfork__cf-fx-plopp-01"
    "8009__cfork__cf-fx-plopp-02"
  ]

  random_blub: =>
    #i = Math.floor Math.random() * @blubs.length
    i = @i++ % @blubs.length
    @blubs[i].play()

  constructor: ->
    for file, index in @blub_paths
      @blubs[index] = AudioFX(@path+file, { formats: ['ogg','mp3'], pool: @pool } )

  connect_to_game: (game) ->
    game.naub_replaced.add @random_blub
    game.naub_destroyed.add @random_blub
