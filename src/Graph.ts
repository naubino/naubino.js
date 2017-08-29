const indexOf = [].indexOf || function (item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

interface Naub {
  seq_num: number
  number: number
}

class DFS {
  naub: NaubId
  dfs_num: number
  color: 0 | 1 | 2
}

class Join {
  a: Naub
  b: Naub

  constructor (a: Naub, b: Naub) {
    // TODO a.number <= b.number!!
    Object.assign(this, {a,b})
  }

  public has(naub_id: NaubId): boolean {
    return (this.a.number === naub_id || this.b.number === naub_id)
  }

  // returns the counter part of naub in a join
  public versus(naub_id: NaubId): Naub | null {
    if (this.a.number === naub_id) {return this.b}
    if (this.b.number === naub_id) {return this.a}
    return null 
  }
}

type Joins = Map<number, Join>
type NaubId = number

interface Layer {
  cycle_found: any //Signal<any[]>
};

// TODO there must be a Join type {a:Naub, b:Naub} which is initiated from two Naubs and takes care of the order of its index

export
class Graph {
  layer: Layer
  naubs: NaubId[]
  joins: Joins
  dfs_map: DFS[] //Map<NaubId, DFS>
  join_id_sequence: number
  seq_num: number

  constructor(layer: Layer) {
    this.layer = layer;
    this.clear()
  }

  // another one of those functions where documentation could require more time than reading the actuall code
  clear() {
    this.join_id_sequence = 0
    this.naubs = []
    this.joins = new Map()
  };

  update_naub_list() {
    this.naubs = []
    for (let [id, join] of this.joins) {
      for (let c of [join.a.number, join.b.number]) {
        if (this.naubs.indexOf(c) < 0) {
          this.naubs.push(c)
        }
      }
    }
  }

  add_join(a:Naub, b:Naub): number {
    this.join_id_sequence++
    let join = new Join(a,b)
    this.joins.set(this.join_id_sequence, join)
    this.update_naub_list()
    return this.join_id_sequence
  }

  remove_join(id) {
    this.joins.delete(id)
    this.update_naub_list();
  }

  partners(naub_id: NaubId, pre?: NaubId): NaubId[] {
    let partners = [];
    for (let [_, join] of this.joins) {
      if (!join.has(pre) && join.has(naub_id)) {
        partners.push(join.versus(naub_id).number)
      }
    }
    return partners;
  }

  cycle_test(first: NaubId) {
    let cycles = []
    this.dfs_map = []
    for(let inaub of this.naubs ) {
      this.dfs_map[inaub] = {naub: inaub, dfs_num: 0, color: 0}
      console.log(`adding ${inaub} to ${this.dfs_map}`)
    }
    this.seq_num = 1

    console.log(this.dfs_map);
    for (let naub_id in this.dfs_map) {
      let [id, dfs] = naub_id;
      if(dfs.dfs_num === 0) {
        let dfs_cycle = this.dfs(naub_id, null, first)
        cycles = cycles.filter(x => dfs_cycle.indexOf(x) >= 0 )

      }
    }
  }

  dfs (naub: NaubId, pre?: NaubId, first?: NaubId): any[] {
    let cycles = []

    this.dfs_map[naub].dfs_num = this.seq_num
    this.seq_num++
    this.dfs_map[naub].color = 1

    this.partners(naub, pre).forEach((partner_id) => {
    console.log("dfs_map", this.dfs_map)
    console.log("getting", partner_id)
      if(this.dfs_map[partner_id].dfs_num === 0) {
        cycles = this.dfs(partner_id, naub, first).filter(x => cycles.indexOf(x) >= 0 )
      }
      if(this.dfs_map[partner_id].color === 1) {
        let list =  this.cycle_list(naub, partner_id, first)
        if(list.length > 0) {
          this.layer.cycle_found.dispatch(list)
        }
      }
    })
    this.dfs_map[naub].color = 2
    return cycles

  }
  

  cycle_list(v, w, first = null): any[]{
    //let cycle = Array.from(this.dfs_map.values())
    let cycle = this.dfs_map.filter(({dfs_num, color}) => {
           dfs_num >= this.dfs_map[w].dfs_num && color == 1
         })
         .sort((a,b) => a.dfs_num - b.dfs_num)
    
    let cycle_naubs = cycle.map(x => x.naub)

    if (!!first && cycle_naubs.indexOf(first) >= 0) {
      let i = cycle_naubs.indexOf(first);
      cycle_naubs = cycle_naubs.slice(i)
                               .concat(cycle_naubs.slice(0, i));
    }
    return cycle_naubs
  }

  tree(naub, visited = null) {
    //console.error("Graph::tree is unimplemented")
  }

}
