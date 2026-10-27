import { describe, it, expect } from 'vitest'
import { Physical_Layer } from '../src/Physical_Layer'

interface NaubLike {
  number: number
  isClickable: boolean
}

interface LayerLike {
  space: unknown
  GRABABLE_MASK_BIT: number
  get_object(id: number): NaubLike
}

const GRABABLE_MASK_BIT = 1 << 31

// adds a circle shape at pos, tagged with naub_number, to a fresh space
const addNaubShape = (space: any, number: number, pos: unknown) => {
  const body = new cp.Body(1, 1)
  body.setPos(pos)
  const shape = new cp.CircleShape(body, 10, cp.vzero)
  shape.naub_number = number
  space.addBody(body)
  space.addShape(shape)
  return shape
}

const makeLayer = (overrides: Partial<LayerLike> = {}): LayerLike =>
  Object.assign(
    {
      space: new cp.Space(),
      GRABABLE_MASK_BIT,
      get_object: (number: number): NaubLike => ({ number, isClickable: true }),
    },
    overrides,
  )

const getObjInPos = (layer: LayerLike, pos: unknown) =>
  Physical_Layer.prototype.get_obj_in_pos.call(layer, pos)

describe('Physical_Layer', () => {
  describe('get_obj_in_pos', () => {
    it('returns the naub at the given position', () => {
      const layer = makeLayer()
      addNaubShape(layer.space, 1, new cp.Vect(50, 50))
      expect(getObjInPos(layer, new cp.Vect(50, 50))).toEqual({ number: 1, isClickable: true })
    })

    it('returns undefined when nothing is at that position', () => {
      const layer = makeLayer()
      addNaubShape(layer.space, 1, new cp.Vect(50, 50))
      expect(getObjInPos(layer, new cp.Vect(500, 500))).toBeUndefined()
    })

    it('returns undefined when the hit naub is not clickable', () => {
      const layer = makeLayer({ get_object: (number) => ({ number, isClickable: false }) })
      addNaubShape(layer.space, 1, new cp.Vect(50, 50))
      expect(getObjInPos(layer, new cp.Vect(50, 50))).toBeUndefined()
    })
  })
})
