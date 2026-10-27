import { describe, it, expect } from 'vitest'
import { Naub } from '../src/Naub'

interface NaubLike {
  joins: Record<string, { number: number }>
  joined_naubs(): number[]
}

// real prototype, so the real method runs
const makeNaub = (joins: Record<string, { number: number }> = {}): NaubLike =>
  Object.assign(Object.create(Naub.prototype), { joins })

describe('Naub', () => {
  describe('joined_naubs', () => {
    it('returns the numbers of every joined naub', () => {
      const naub = makeNaub({ a: { number: 2 }, b: { number: 3 } })
      expect(naub.joined_naubs()).toEqual([2, 3])
    })

    it('returns an empty list when there are no joins', () => {
      const naub = makeNaub()
      expect(naub.joined_naubs()).toEqual([])
    })
  })
})
