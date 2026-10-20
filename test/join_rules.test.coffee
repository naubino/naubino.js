import {describe, it, expect, vi, beforeEach, afterEach} from 'vitest'
import {Game} from '../src/Game'
import {Naub} from '../src/Naub'

# builds a naub with the real prototype so the real rule methods run
make_naub = (number, color_id, fields = {}) ->
  Object.assign Object.create(Naub::), {number, color_id, kind: 'ball', joins: {}, focused: no, disabled: no}, fields

focused_naub = (number, color_id, fields = {}) ->
  make_naub number, color_id, Object.assign({focused: yes}, fields)

# simulates an existing join between two naubs
link = (naub_a, naub_b, join_id) ->
  naub_a.joins[join_id] = naub_b
  naub_b.joins[join_id] = naub_a

make_arbiter = (impulse) ->
  totalImpulse: -> new cp.Vect(impulse, 0)

make_game = (overrides = {}) ->
  Object.assign {joining_allowed: yes, replacing_naubs: [], joining_naubs: [], just_joined: -1}, overrides

decide = (game, naub_a, naub_b, impulse = 5000) ->
  Game::check_joining.call game, naub_a, naub_b, make_arbiter(impulse)

# focused naub 1 is alone, other naub 2 already has a partner
join_pair = ->
  focused = focused_naub 1, 0
  other = make_naub 2, 0
  link other, make_naub(3, 1), 'partner_of_other'
  {focused, other}

# both naubs have partners, do not share one, same color
replace_pair = ->
  focused = focused_naub 1, 0
  other = make_naub 2, 0
  link focused, make_naub(3, 1), 'partner_of_focused'
  link other, make_naub(4, 1), 'partner_of_other'
  {focused, other}

describe 'Naub join predicates', ->
  describe 'agrees_with', ->
    it 'agrees with a naub of the same color and kind', ->
      expect(make_naub(1, 2).agrees_with(make_naub(2, 2))).toBe yes

    it 'does not agree with a naub of a different color', ->
      expect(make_naub(1, 2).agrees_with(make_naub(2, 3))).toBe no

    it 'does not agree with a naub of a different kind', ->
      expect(make_naub(1, 2).agrees_with(make_naub(2, 2, {kind: 'star'}))).toBe no

    it 'is falsy when its own kind is missing', ->
      expect(make_naub(1, 2, {kind: undefined}).agrees_with(make_naub(2, 2))).toBeFalsy()

    it 'agrees with color 0 when the other naub is also color 0', ->
      # the @color_id? check must not treat 0 as missing
      expect(make_naub(1, 0).agrees_with(make_naub(2, 0))).toBe yes

    it 'does not agree color 0 with color 1', ->
      expect(make_naub(1, 0).agrees_with(make_naub(2, 1))).toBe no

    it 'is falsy when its own color is missing', ->
      expect(make_naub(1, undefined).agrees_with(make_naub(2, undefined))).toBeFalsy()

  describe 'is_alone', ->
    it 'is alone when it has no joins', ->
      expect(make_naub(1, 0).is_alone()).toBe yes

    it 'is not alone once it has a join', ->
      naub_a = make_naub 1, 0
      link naub_a, make_naub(2, 0), 'a'
      expect(naub_a.is_alone()).toBe no

  describe 'is_joined_with', ->
    it 'reports no join before the naubs are linked', ->
      expect(make_naub(1, 0).is_joined_with(make_naub(2, 0))).toBe no

    it 'reports a join from both sides once linked', ->
      naub_a = make_naub 1, 0
      naub_b = make_naub 2, 0
      link naub_a, naub_b, 'a'
      expect(naub_a.is_joined_with(naub_b)).toBe yes
      expect(naub_b.is_joined_with(naub_a)).toBe yes

    it 'is not joined with a naub it was never linked to', ->
      naub_a = make_naub 1, 0
      naub_b = make_naub 2, 0
      link naub_a, naub_b, 'a'
      other = make_naub 3, 0
      expect(naub_a.is_joined_with(other)).toBe no

  describe 'close_related', ->
    it 'is related when both naubs share a common partner', ->
      naub_a = make_naub 1, 0
      naub_b = make_naub 2, 0
      shared = make_naub 3, 1
      link naub_a, shared, 'a'
      link naub_b, shared, 'b'
      expect(naub_a.close_related(naub_b)).toBe yes
      expect(naub_b.close_related(naub_a)).toBe yes

    it 'is not related when the partners are different', ->
      naub_a = make_naub 1, 0
      naub_b = make_naub 2, 0
      link naub_a, make_naub(3, 1), 'a'
      link naub_b, make_naub(4, 1), 'b'
      expect(naub_a.close_related(naub_b)).toBe no

    it 'is not related when both naubs are alone', ->
      expect(make_naub(1, 0).close_related(make_naub(2, 0))).toBe no

describe 'check_joining guards', ->
  beforeEach ->
    vi.useFakeTimers()

  afterEach ->
    vi.useRealTimers()

  it 'refuses every join while joining is not allowed', ->
    game = make_game {joining_allowed: no}
    {focused, other} = join_pair()
    expect(decide(game, focused, other)).toBe no
    expect(game.joining_naubs).toEqual []
    expect(game.replacing_naubs).toEqual []

  it 'refuses when neither naub is focused', ->
    game = make_game()
    {focused, other} = join_pair()
    focused.focused = no
    expect(decide(game, focused, other)).toBe no
    expect(game.joining_naubs).toEqual []
    expect(game.replacing_naubs).toEqual []

  it 'refuses when the first naub is disabled', ->
    game = make_game()
    {focused, other} = join_pair()
    focused.disabled = yes
    expect(decide(game, focused, other)).toBe no
    expect(game.joining_naubs).toEqual []
    expect(game.just_joined).toBe -1

  it 'refuses when the other naub is disabled', ->
    game = make_game()
    {focused, other} = join_pair()
    other.disabled = yes
    expect(decide(game, focused, other)).toBe no
    expect(game.joining_naubs).toEqual []
    expect(game.just_joined).toBe -1

  it 'refuses two naubs with the same number', ->
    game = make_game()
    focused = focused_naub 1, 0
    twin = make_naub 1, 0
    link twin, make_naub(3, 1), 'partner'
    expect(decide(game, focused, twin)).toBe no
    expect(game.joining_naubs).toEqual []
    expect(game.replacing_naubs).toEqual []

  it 'refuses an impulse below min_joining_force', ->
    game = make_game()
    {focused, other} = join_pair()
    impulse = Naubino.settings.game.min_joining_force - 1
    expect(decide(game, focused, other, impulse)).toBe no
    expect(game.joining_naubs).toEqual []
    expect(game.replacing_naubs).toEqual []

  it 'accepts an impulse exactly equal to min_joining_force', ->
    game = make_game()
    {focused, other} = join_pair()
    impulse = Naubino.settings.game.min_joining_force
    expect(decide(game, focused, other, impulse)).toBe yes
    expect(game.joining_naubs.length).toBe 1

describe 'check_joining replace', ->
  beforeEach ->
    vi.useFakeTimers()

  afterEach ->
    vi.useRealTimers()

  it 'replaces when both naubs have partners, share a color, and are not related', ->
    game = make_game()
    {focused, other} = replace_pair()
    expect(decide(game, focused, other)).toBe yes
    expect(game.replacing_naubs.length).toBe 1
    expect(game.replacing_naubs[0][0]).toBe focused
    expect(game.replacing_naubs[0][1]).toBe other

  it 'puts the focused naub first even when it is the second argument', ->
    game = make_game()
    {focused, other} = replace_pair()
    expect(decide(game, other, focused)).toBe yes
    expect(game.replacing_naubs[0][0]).toBe focused
    expect(game.replacing_naubs[0][1]).toBe other

  it 'does not touch joining_naubs or just_joined on a replace', ->
    game = make_game()
    {focused, other} = replace_pair()
    decide game, focused, other
    expect(game.joining_naubs).toEqual []
    expect(game.just_joined).toBe -1

  it 'does not replace when the naubs are already joined', ->
    game = make_game()
    {focused, other} = replace_pair()
    link focused, other, 'direct'
    expect(decide(game, focused, other)).toBe no
    expect(game.replacing_naubs).toEqual []
    expect(game.joining_naubs).toEqual []

  it 'does not replace when the colors differ', ->
    game = make_game()
    {focused, other} = replace_pair()
    other.color_id = 5
    expect(decide(game, focused, other)).toBe no
    expect(game.replacing_naubs).toEqual []
    expect(game.joining_naubs).toEqual []

  it 'does not replace when the naubs are close related', ->
    game = make_game()
    focused = focused_naub 1, 0
    other = make_naub 2, 0
    shared = make_naub 3, 1
    link focused, shared, 'a'
    link other, shared, 'b'
    expect(decide(game, focused, other)).toBe no
    expect(game.replacing_naubs).toEqual []
    expect(game.joining_naubs).toEqual []

describe 'check_joining join', ->
  beforeEach ->
    vi.useFakeTimers()

  afterEach ->
    vi.useRealTimers()

  it 'joins when the focused naub is alone and the other has partners', ->
    game = make_game()
    {focused, other} = join_pair()
    expect(decide(game, focused, other)).toBe yes
    expect(game.joining_naubs.length).toBe 1
    expect(game.joining_naubs[0][0]).toBe focused
    expect(game.joining_naubs[0][1]).toBe other
    expect(game.replacing_naubs).toEqual []

  it 'joins when both naubs are alone', ->
    # the replace branch is skipped because `alone` is true, so the join branch wins
    game = make_game()
    focused = focused_naub 1, 0
    other = make_naub 2, 0
    expect(decide(game, focused, other)).toBe yes
    expect(game.joining_naubs[0][0]).toBe focused
    expect(game.joining_naubs[0][1]).toBe other
    expect(game.replacing_naubs).toEqual []

  it 'puts the focused naub first when joining from the second argument', ->
    game = make_game()
    {focused, other} = join_pair()
    expect(decide(game, other, focused)).toBe yes
    expect(game.joining_naubs[0][0]).toBe focused
    expect(game.joining_naubs[0][1]).toBe other

  it 'sets just_joined to the focused naub number', ->
    game = make_game()
    {focused, other} = join_pair()
    decide game, focused, other
    expect(game.just_joined).toBe focused.number

  it 'refuses a second join by the same focused naub while cooling down', ->
    game = make_game()
    {focused, other} = join_pair()
    decide game, focused, other
    expect(decide(game, focused, other)).toBe no
    expect(game.joining_naubs.length).toBe 1

  it 'resets just_joined to -1 after 300ms and allows joining again', ->
    game = make_game()
    {focused, other} = join_pair()
    decide game, focused, other
    vi.advanceTimersByTime 300
    expect(game.just_joined).toBe -1
    expect(decide(game, focused, other)).toBe yes
    expect(game.joining_naubs.length).toBe 2

  it 'still blocks the same focused naub at 299ms', ->
    game = make_game()
    {focused, other} = join_pair()
    decide game, focused, other
    vi.advanceTimersByTime 299
    expect(decide(game, focused, other)).toBe no
    expect(game.joining_naubs.length).toBe 1

  it 'lets a different focused naub join while the previous join cools down', ->
    game = make_game()
    {focused, other} = join_pair()
    decide game, focused, other
    other_focused = focused_naub 5, 0
    other_partnered = make_naub 7, 0
    link other_partnered, make_naub(6, 1), 'partner'
    expect(decide(game, other_focused, other_partnered)).toBe yes
    expect(game.just_joined).toBe 5
    expect(game.joining_naubs.length).toBe 2

  # quirk: check_joining (Game.coffee ~179-183) keeps no timer handle, so each join
  # schedules its own reset. A later join's 300ms window is cut short by an earlier
  # timer, so just_joined goes back to -1 at 300ms, not 400ms.
  it 'lets the next join through early because an earlier timer already reset just_joined', ->
    game = make_game()
    {focused, other} = join_pair()
    decide game, focused, other
    vi.advanceTimersByTime 100
    second_focused = focused_naub 5, 0
    second_partnered = make_naub 7, 0
    link second_partnered, make_naub(6, 1), 'partner'
    decide game, second_focused, second_partnered
    expect(game.just_joined).toBe 5
    vi.advanceTimersByTime 200
    expect(game.just_joined).toBe -1
    expect(decide(game, second_focused, second_partnered)).toBe yes
    expect(game.joining_naubs.length).toBe 3

  # quirk: the join branch (Game.coffee ~179) only checks naub.is_alone(), not other.
  # A focused naub with partners never joins, even when the other naub is alone.
  it 'does not join when the focused naub has partners but the other is alone', ->
    game = make_game()
    focused = focused_naub 1, 0
    link focused, make_naub(3, 1), 'partner'
    other = make_naub 2, 0
    expect(decide(game, focused, other)).toBe no
    expect(game.joining_naubs).toEqual []
    expect(game.replacing_naubs).toEqual []
    expect(game.just_joined).toBe -1
