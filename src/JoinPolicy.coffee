# Decides whether two colliding naubs should join, or have one replace the
# other. Extracted from Game.check_joining / Naub.agrees_with.
export class JoinPolicy
  constructor: (@game) ->

  # checks whether naub wants to join with other
  # OVERWRITE ME
  agrees_with: (naub, other) ->
    naub.color_id? and naub.kind? and
    naub.color_id == other.color_id and
    naub.kind     == other.kind

  # is one naub allowed to join with another
  check_joining: (a, b, arbiter) ->
    return no unless @game.joining_allowed
    return no unless a.focused or b.focused
    return no if a.disabled or b.disabled
    return no if a.number is b.number
    return no if arbiter.totalImpulse().Length() < Naubino.settings.game.min_joining_force

    # assigning better names the a and b
    naub  = if a.focused then a else b
    other = unless a.focused then a else b

    to_close = naub.close_related other # prohibits folding of pairs
    joined   = naub.is_joined_with other # can't join what's already joined
    agree    = @agrees_with(naub, other) and @agrees_with(other, naub)
    alone    = naub.is_alone() or other.is_alone()

    if not joined && agree && not to_close && not alone
      #console.info 'replace'
      #other.replace_with naub # chipmunk does not like me deleting objects inside a step
      @game.replacing_naubs.push [naub, other]
      return yes

    else if naub.is_alone() and naub.number isnt @game.just_joined
      #console.info 'join'
      #naub.join_with other
      @game.just_joined = naub.number
      setTimeout (=> @game.just_joined = -1), 300
      @game.joining_naubs.push [naub, other]
      return yes
    no
