import { describe, it, expect, vi } from 'vitest'
import { CollisionHandler } from '../src/game/CollisionHandler'

interface GameLike {
  get_object: ReturnType<typeof vi.fn>
}

const makeGame = (): GameLike => ({ get_object: vi.fn(id => ({ number: id })) })

describe('CollisionHandler', () => {
  describe('naub', () => {
    it('looks up the naub for the given shape via the game', () => {
      const game = makeGame()
      const handler = new CollisionHandler(game as any)
      const shape = { naub_number: 7 }
      expect(handler.naub(shape as any)).toEqual({ number: 7 })
      expect(game.get_object).toHaveBeenCalledWith(7)
    })
  })
})
