# join, replace or nothing, asked on every collision
export class JoinPolicy
  constructor: (options = {}) ->

    @min_joining_force = options.min_joining_force ? 1000


  # checks whether naub wants to join with other
  # OVERWRITE ME
  agrees_with: (naub, other) ->
    naub.color_id? and naub.kind? and
    naub.color_id == other.color_id and
    naub.kind     == other.kind

  allows_collision: (first, second) -> first.focused or second.focused

  moving_pair: (first, second) ->
    [naub, other] = [first, second]
    [naub, other] = [second, first] unless first.focused
    return [naub, other]

  # is one naub allowed to join with another
  check_joining: (first, second, arbiter) ->

    return null unless @allows_collision first, second
    return null if first.disabled or second.disabled
    return null if first.number is second.number
    return null unless arbiter.totalImpulse().Length() >= @min_joining_force

    [naub, other] = @moving_pair first, second

    to_close = naub.close_related other # prohibits folding of pairs
    joined   = naub.is_joined_with other # can't join what's already joined
    agree    = @agrees_with(naub, other) and @agrees_with(other, naub)
    alone    = naub.is_alone() or other.is_alone()

    if not joined && agree && not to_close && not alone
      return {action: 'replace', pair: [other, naub]}

    if naub.is_alone()
      return {action: 'join', pair: [naub, other]}
    return null

export class AutoJoinPolicy extends JoinPolicy
  constructor: (options = {}) ->
    super Object.assign {}, options, {min_joining_force: 0}

  allows_collision: -> yes

  moving_pair: (first, second) ->
    [naub, other] = super first, second
    if not naub.focused and other.is_alone() and not naub.is_alone()
      [naub, other] = [other, naub]
    return [naub, other]
