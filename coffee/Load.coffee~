console.time("loading")

#requirejs.config {
#  baseUrl: 'js/'
#  paths:
#      lib: '../../lib'
#}

define ["Naubino"], (Naubino) ->
  window.onload = ->
    naubino = window.Naubino = new Naubino()
    naubino.setup()

    #populate color selector
    for name, colors of naubino.settings.colors
      $('select#colors').append("<option value=\"#{name}\">#{name}</option>")

    $('select#colors option').each (index,option) ->
      if option.value == naubino.settings.color
        option.selected = true

    $('select#colors').change ->
      naubino.settings.color = this.value

      if this.value == 'high_contrast'
        naubino.settings.graphics.draw_borders_old = naubino.settings.graphics.draw_borders
        naubino.settings.graphics.draw_borders = true
      else if naubino.settings.graphics.draw_borders_old?
        naubino.settings.graphics.draw_borders = naubino.settings.graphics.draw_borders_old


      naubino.menu.for_each (naub) -> naub.recolor()
      naubino.game.for_each (naub) -> naub.recolor()
    
