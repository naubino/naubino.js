export class DragSystem
  constructor: (@game) ->

  start: (pos) ->
    return unless @game.space?
    shape = @game.space.pointQueryFirst(pos, @game.GRABABLE_MASK_BIT, cp.NO_GROUP)
    naub = @game.get_object shape.naub_number if shape?
    return unless naub and naub.isClickable

    @game.focus naub

    @game.mouseBody.p = pos
    @joint = new cp.PivotJoint(@game.mouseBody, naub.physical_body, cp.vzero, cp.vzero)
    @joint.errorBias = Math.pow(1 - 0.5, 60)
    @game.space.addConstraint(@joint)

  stop: ->
    @game.clear_focus()

    if @game.space? and @joint?
      @game.space.removeConstraint(@joint)
      @joint = null
