import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { JoinPolicy } from "../src/game/JoinPolicy";
import { Naub } from "../src/game/Naub";

interface NaubLike {
  number: number;
  color_id: number | undefined;
  kind: string | undefined;
  joins: Record<string, NaubLike>;
  focused: boolean;
  disabled: boolean;
  is_alone(): boolean;
  is_joined_with(other: NaubLike): boolean;
  close_related(other: NaubLike): boolean;
}

interface GameLike {
  joining_allowed: boolean;
  replacing_naubs: [NaubLike, NaubLike][];
  joining_naubs: [NaubLike, NaubLike][];
  just_joined: number;
}

// real prototype, so the real predicates run
const makeNaub = (
  number: number,
  color_id: number | undefined,
  fields: Partial<NaubLike> = {},
): NaubLike =>
  Object.assign(Object.create(Naub.prototype), {
    number,
    color_id,
    kind: "ball",
    joins: {},
    focused: false,
    disabled: false,
  }, fields);

const focusedNaub = (
  number: number,
  color_id: number | undefined,
  fields: Partial<NaubLike> = {},
): NaubLike =>
  makeNaub(number, color_id, Object.assign({ focused: true }, fields));

// fake join, both sides
const link = (naub_a: NaubLike, naub_b: NaubLike, joinId: string): void => {
  naub_a.joins[joinId] = naub_b;
  naub_b.joins[joinId] = naub_a;
};

const makeArbiter = (impulse: number) => ({
  totalImpulse: () => new cp.Vect(impulse, 0),
});

const makeGame = (overrides: Partial<GameLike> = {}): GameLike =>
  Object.assign({
    joining_allowed: true,
    replacing_naubs: [],
    joining_naubs: [],
    just_joined: -1,
  }, overrides);

const decide = (
  game: GameLike,
  naub_a: NaubLike,
  naub_b: NaubLike,
  impulse = 5000,
): boolean =>
  new JoinPolicy(game).check_joining(naub_a, naub_b, makeArbiter(impulse));

// focused naub 1 is alone, other naub 2 already has a partner
const joinPair = () => {
  const focused = focusedNaub(1, 0);
  const other = makeNaub(2, 0);
  link(other, makeNaub(3, 1), "partner_of_other");
  return { focused, other };
};

// both naubs have partners, do not share one, same color
const replacePair = () => {
  const focused = focusedNaub(1, 0);
  const other = makeNaub(2, 0);
  link(focused, makeNaub(3, 1), "partner_of_focused");
  link(other, makeNaub(4, 1), "partner_of_other");
  return { focused, other };
};

describe("Naub join predicates", () => {
  describe("JoinPolicy.agrees_with", () => {
    const policy = new JoinPolicy({} as GameLike);

    it("agrees with a naub of the same color and kind", () => {
      expect(policy.agrees_with(makeNaub(1, 2), makeNaub(2, 2))).toBe(true);
    });

    it("does not agree with a naub of a different color", () => {
      expect(policy.agrees_with(makeNaub(1, 2), makeNaub(2, 3))).toBe(false);
    });

    it("does not agree with a naub of a different kind", () => {
      expect(
        policy.agrees_with(makeNaub(1, 2), makeNaub(2, 2, { kind: "star" })),
      ).toBe(false);
    });

    it("is falsy when its own kind is missing", () =>
      expect(
        policy.agrees_with(makeNaub(1, 2, { kind: undefined }), makeNaub(2, 2)),
      ).toBeFalsy());

    it("agrees with color 0 when the other naub is also color 0", () => {
      // color_id? must not treat 0 as missing
      expect(policy.agrees_with(makeNaub(1, 0), makeNaub(2, 0))).toBe(true);
    });

    it("does not agree color 0 with color 1", () => {
      expect(policy.agrees_with(makeNaub(1, 0), makeNaub(2, 1))).toBe(false);
    });

    it("is falsy when its own color is missing", () => {
      expect(
        policy.agrees_with(makeNaub(1, undefined), makeNaub(2, undefined)),
      ).toBeFalsy();
    });
  });

  describe("is_alone", () => {
    it("is alone when it has no joins", () => {
      expect(makeNaub(1, 0).is_alone()).toBe(true);
    });

    it("is not alone once it has a join", () => {
      const naub_a = makeNaub(1, 0);
      link(naub_a, makeNaub(2, 0), "a");
      expect(naub_a.is_alone()).toBe(false);
    });
  });

  describe("is_joined_with", () => {
    it("reports no join before the naubs are linked", () => {
      expect(makeNaub(1, 0).is_joined_with(makeNaub(2, 0))).toBe(false);
    });

    it("reports a join from both sides once linked", () => {
      const naub_a = makeNaub(1, 0);
      const naub_b = makeNaub(2, 0);
      link(naub_a, naub_b, "a");
      expect(naub_a.is_joined_with(naub_b)).toBe(true);
      expect(naub_b.is_joined_with(naub_a)).toBe(true);
    });

    it("is not joined with a naub it was never linked to", () => {
      const naub_a = makeNaub(1, 0);
      const naub_b = makeNaub(2, 0);
      link(naub_a, naub_b, "a");
      const other = makeNaub(3, 0);
      expect(naub_a.is_joined_with(other)).toBe(false);
    });
  });

  describe("close_related", () => {
    it("is related when both naubs share a common partner", () => {
      const naub_a = makeNaub(1, 0);
      const naub_b = makeNaub(2, 0);
      const shared = makeNaub(3, 1);
      link(naub_a, shared, "a");
      link(naub_b, shared, "b");
      expect(naub_a.close_related(naub_b)).toBe(true);
      expect(naub_b.close_related(naub_a)).toBe(true);
    });

    it("is not related when the partners are different", () => {
      const naub_a = makeNaub(1, 0);
      const naub_b = makeNaub(2, 0);
      link(naub_a, makeNaub(3, 1), "a");
      link(naub_b, makeNaub(4, 1), "b");
      expect(naub_a.close_related(naub_b)).toBe(false);
    });

    it("is not related when both naubs are alone", () => {
      expect(makeNaub(1, 0).close_related(makeNaub(2, 0))).toBe(false);
    });
  });
});

describe("check_joining guards", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it("refuses every join while joining is not allowed", () => {
    const game = makeGame({ joining_allowed: false });
    const { focused, other } = joinPair();
    expect(decide(game, focused, other)).toBe(false);
    expect(game.joining_naubs).toEqual([]);
    expect(game.replacing_naubs).toEqual([]);
  });

  it("refuses when neither naub is focused", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    focused.focused = false;
    expect(decide(game, focused, other)).toBe(false);
    expect(game.joining_naubs).toEqual([]);
    expect(game.replacing_naubs).toEqual([]);
  });

  it("refuses when the first naub is disabled", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    focused.disabled = true;
    expect(decide(game, focused, other)).toBe(false);
    expect(game.joining_naubs).toEqual([]);
    expect(game.just_joined).toBe(-1);
  });

  it("refuses when the other naub is disabled", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    other.disabled = true;
    expect(decide(game, focused, other)).toBe(false);
    expect(game.joining_naubs).toEqual([]);
    expect(game.just_joined).toBe(-1);
  });

  it("refuses two naubs with the same number", () => {
    const game = makeGame();
    const focused = focusedNaub(1, 0);
    const twin = makeNaub(1, 0);
    link(twin, makeNaub(3, 1), "partner");
    expect(decide(game, focused, twin)).toBe(false);
    expect(game.joining_naubs).toEqual([]);
    expect(game.replacing_naubs).toEqual([]);
  });

  it("refuses an impulse below min_joining_force", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    const impulse = Naubino.settings.game.min_joining_force - 1;
    expect(decide(game, focused, other, impulse)).toBe(false);
    expect(game.joining_naubs).toEqual([]);
    expect(game.replacing_naubs).toEqual([]);
  });

  it("accepts an impulse exactly equal to min_joining_force", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    const impulse = Naubino.settings.game.min_joining_force;
    expect(decide(game, focused, other, impulse)).toBe(true);
    expect(game.joining_naubs.length).toBe(1);
  });
});

describe("check_joining replace", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it("replaces when both naubs have partners, share a color, and are not related", () => {
    const game = makeGame();
    const { focused, other } = replacePair();
    expect(decide(game, focused, other)).toBe(true);
    expect(game.replacing_naubs.length).toBe(1);
    expect(game.replacing_naubs[0][0]).toBe(focused);
    expect(game.replacing_naubs[0][1]).toBe(other);
  });

  it("puts the focused naub first even when it is the second argument", () => {
    const game = makeGame();
    const { focused, other } = replacePair();
    expect(decide(game, other, focused)).toBe(true);
    expect(game.replacing_naubs[0][0]).toBe(focused);
    expect(game.replacing_naubs[0][1]).toBe(other);
  });

  it("does not touch joining_naubs or just_joined on a replace", () => {
    const game = makeGame();
    const { focused, other } = replacePair();
    decide(game, focused, other);
    expect(game.joining_naubs).toEqual([]);
    expect(game.just_joined).toBe(-1);
  });

  it("does not replace when the naubs are already joined", () => {
    const game = makeGame();
    const { focused, other } = replacePair();
    link(focused, other, "direct");
    expect(decide(game, focused, other)).toBe(false);
    expect(game.replacing_naubs).toEqual([]);
    expect(game.joining_naubs).toEqual([]);
  });

  it("does not replace when the colors differ", () => {
    const game = makeGame();
    const { focused, other } = replacePair();
    other.color_id = 5;
    expect(decide(game, focused, other)).toBe(false);
    expect(game.replacing_naubs).toEqual([]);
    expect(game.joining_naubs).toEqual([]);
  });

  it("does not replace when the naubs are close related", () => {
    const game = makeGame();
    const focused = focusedNaub(1, 0);
    const other = makeNaub(2, 0);
    const shared = makeNaub(3, 1);
    link(focused, shared, "a");
    link(other, shared, "b");
    expect(decide(game, focused, other)).toBe(false);
    expect(game.replacing_naubs).toEqual([]);
    expect(game.joining_naubs).toEqual([]);
  });
});

describe("check_joining join", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  it("joins when the focused naub is alone and the other has partners", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    expect(decide(game, focused, other)).toBe(true);
    expect(game.joining_naubs.length).toBe(1);
    expect(game.joining_naubs[0][0]).toBe(focused);
    expect(game.joining_naubs[0][1]).toBe(other);
    expect(game.replacing_naubs).toEqual([]);
  });

  it("joins when both naubs are alone", () => {
    // alone skips the replace branch, so join wins
    const game = makeGame();
    const focused = focusedNaub(1, 0);
    const other = makeNaub(2, 0);
    expect(decide(game, focused, other)).toBe(true);
    expect(game.joining_naubs[0][0]).toBe(focused);
    expect(game.joining_naubs[0][1]).toBe(other);
    expect(game.replacing_naubs).toEqual([]);
  });

  it("puts the focused naub first when joining from the second argument", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    expect(decide(game, other, focused)).toBe(true);
    expect(game.joining_naubs[0][0]).toBe(focused);
    expect(game.joining_naubs[0][1]).toBe(other);
  });

  it("sets just_joined to the focused naub number", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    decide(game, focused, other);
    expect(game.just_joined).toBe(focused.number);
  });

  it("refuses a second join by the same focused naub while cooling down", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    decide(game, focused, other);
    expect(decide(game, focused, other)).toBe(false);
    expect(game.joining_naubs.length).toBe(1);
  });

  it("resets just_joined to -1 after 300ms and allows joining again", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    decide(game, focused, other);
    vi.advanceTimersByTime(300);
    expect(game.just_joined).toBe(-1);
    expect(decide(game, focused, other)).toBe(true);
    expect(game.joining_naubs.length).toBe(2);
  });

  it("still blocks the same focused naub at 299ms", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    decide(game, focused, other);
    vi.advanceTimersByTime(299);
    expect(decide(game, focused, other)).toBe(false);
    expect(game.joining_naubs.length).toBe(1);
  });

  it("lets a different focused naub join while the previous join cools down", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    decide(game, focused, other);
    const otherFocused = focusedNaub(5, 0);
    const otherPartnered = makeNaub(7, 0);
    link(otherPartnered, makeNaub(6, 1), "partner");
    expect(decide(game, otherFocused, otherPartnered)).toBe(true);
    expect(game.just_joined).toBe(5);
    expect(game.joining_naubs.length).toBe(2);
  });

  // quirk: no timer handle is kept, every join schedules its own reset
  // so an earlier timer cuts the later join's 300ms short
  it("lets the next join through early because an earlier timer already reset just_joined", () => {
    const game = makeGame();
    const { focused, other } = joinPair();
    decide(game, focused, other);
    vi.advanceTimersByTime(100);
    const secondFocused = focusedNaub(5, 0);
    const secondPartnered = makeNaub(7, 0);
    link(secondPartnered, makeNaub(6, 1), "partner");
    decide(game, secondFocused, secondPartnered);
    expect(game.just_joined).toBe(5);
    vi.advanceTimersByTime(200);
    expect(game.just_joined).toBe(-1);
    expect(decide(game, secondFocused, secondPartnered)).toBe(true);
    expect(game.joining_naubs.length).toBe(3);
  });

  // quirk: the join branch only checks the focused naub's is_alone(), not other's
  // a focused naub with partners never joins, even onto a lone naub
  it("does not join when the focused naub has partners but the other is alone", () => {
    const game = makeGame();
    const focused = focusedNaub(1, 0);
    link(focused, makeNaub(3, 1), "partner");
    const other = makeNaub(2, 0);
    expect(decide(game, focused, other)).toBe(false);
    expect(game.joining_naubs).toEqual([]);
    expect(game.replacing_naubs).toEqual([]);
    expect(game.just_joined).toBe(-1);
  });
});
