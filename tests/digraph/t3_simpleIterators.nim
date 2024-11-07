 
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 2.0
  targets: "c cpp js objc"
  valgrind: off
  matrix: ""
"""

import
  std / [with, sugar, sets],
  ../../src/digraph {.all.}


var myDig = DiGraph[int]()
let
  node1 = 1
  node2 = 2
  node3 = 3
  node4 = 4
  node5 = 5

with myDig:
  incl node1, node2, node3, node4, node5

  inclEdge node1, node2
  inclEdge node1, node3
  inclEdge node3, node4

const
  CorrectNodes = [1, 2, 3, 4, 5].toHashSet
  CorrectEdges = [(1, 2), (1, 3), (3, 4)].toHashSet
  CorrectPairs = [(1, [2, 3].toHashSet),
    (2, toHashSet[int]([])),
    (3, [4].toHashSet),
    (4, toHashSet[int]([])),
    (5, toHashSet[int]([]))].toHashSet

let fromItems = collect:
  for n in myDig.items:
    {n}
doAssert fromItems == CorrectNodes


let fromNodes = collect:
  for n in myDig.nodes:
    {n}
doAssert fromNodes == CorrectNodes


let fromEdges = collect:
  for edge in myDig.edges:
    {edge}
doAssert fromEdges == CorrectEdges


let fromPairs = collect:
  for p in myDig.pairs:
    {p}
doAssert fromPairs == CorrectPairs
