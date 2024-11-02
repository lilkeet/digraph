 
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 2.0
  targets: "c cpp js objc"
  matrix: ""
"""

import
  std/[with],
  ../../src/digraph/[acyclic, algos]


var a = Dag[int]()
with a:
  inclEdge 1, 2
  inclEdge 3, 4
  inclEdge 5, 6
  inclEdge 2, 3

doAssertRaises CycleError:
  a.inclEdge 3, 1

doAssertRaises CycleError:
  a.inclEdge 2, 1

doAssertRaises CycleError:
  a.inclEdge 6, 5


var b = DiGraph[int]()

for n in 0..30:
  b.inclEdge n, n+1

b.inclEdge 27, 2

b.incl 88

doAssert b.hasCycle()

doAssertRaises CycleError:
  discard b.toDag()
