
window.onload = ->
  window.naubino = Naubino.constructor()

@Naubino = {
  constructor: () ->

    @graph = new @Graph()
    @colors = @Settings.colors.output

    @init_dom()

    @setup_keybindings()
    @setup_cursorbindings()

    @state_machine = new @NaubMachine()
    #@rules = new @RuleSet()
    @rules = new @TestCase()
    @state_machine.menu_play.dispatch() #TODO remove this line


  init_dom: () ->
    @overlay_canvas = document.getElementById("overlay_canvas")
    @menu_canvas = document.getElementById("menu_canvas")
    @world_canvas = document.getElementById("world_canvas")
    @background_canvas = document.getElementById("background_canvas")


    @background = new @Background(@background_canvas)
    @game       = new @Game(@world_canvas, @graph)
    @menu       = new @Menu(@menu_canvas)
    @overlay    = new @Overlay(@overlay_canvas)


  setup_keybindings: () ->
    @keybindings = new @KeyBindings()
    window.onkeydown = (key) => @keybindings.keydown(key)
    window.onkeyup = (key) => @keybindings.keyup(key)
    @keybindings.enable 32, => @state_machine.menu_pause.dispatch()


  setup_cursorbindings: () ->
    # TODO mouse events must go solely through mode
    onmousemove = (e) =>
      #@state.mousemove.dispatch(e)
      @menu.move_pointer e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop
      @game.move_pointer e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    onmouseup = (e) =>
      #@state.mouseup.dispatch(e)
      @game.unfocus e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    onmousedown = (e) =>
      #@state.mousedown.dispatch(e)
      @menu.click e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop
      @game.click e.pageX - @overlay_canvas.offsetLeft, e.pageY - @overlay_canvas.offsetTop

    @overlay_canvas.addEventListener("mousedown", onmousedown, false)
    @overlay_canvas.addEventListener("mouseup", onmouseup, false)
    @overlay_canvas.addEventListener("mousemove", onmousemove, false)
    @overlay_canvas.addEventListener("mouseout", onmouseup, false)

    @overlay_canvas.addEventListener("touchstart", onmousedown, false)
    @overlay_canvas.addEventListener("touchend", onmouseup, false)
    @overlay_canvas.addEventListener("touchmove", onmousemove, false)
}
