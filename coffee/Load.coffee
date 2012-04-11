define ["Naubino"], (Naubino) ->
  console.log Naubino
  window.onload = ->
    window.Naubino = new Naubino
    window.Naubino.setup()

