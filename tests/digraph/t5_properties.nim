 
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 5.0
  targets: "c cpp js objc"
  valgrind: on
  matrix: "-d:useMalloc"
"""

import
  std / [with, sequtils],
  ../../src/digraph,
  ../../src/digraph/algos,
  ../utils

let myDig = block:
  var r = DiGraph[int]()
  with r:
    incl (0..10).toSeq
    inclEdge 1, 2
    inclEdge 1, 3
    inclEdge 3, 4
    inclEdge 4, 7
    incl (parent: 7, child: 8)
    incl (parent: 8, child: 9)
    incl (parent: 8, child: 10)
    inclEdge 10, 11
    inclEdge 9, 19
  r


block lineage:
  const
    Parent = 8
    CorrectDescendents = {9, 10, 11, 19}

  block depthFirst:
    let children = myDig.descendentsOf(Parent, DepthFirst).toSeq
    doAssert children.len == CorrectDescendents.card
    for child in children:
      doAssert child in CorrectDescendents

  block depthFirst:
    let children = myDig.descendentsOf(Parent, BreadthFirst).toSeq
    doAssert children.len == CorrectDescendents.card
    for child in children:
      doAssert child in CorrectDescendents

  block funcVersion:
    for child in CorrectDescendents:
      let childAsInt = int child
      doAssert childAsInt.isDescendentOf(Parent, myDig)
      doAssert not Parent.isDescendentOf(childAsInt, myDig)
      doAssert Parent.isAncestorOf(childAsInt, myDig)
      doAssert not childAsInt.isAncestorOf(Parent, myDig)


block circles:
  for c in myDig.cycles:
    doAssert false

  doAssert not myDig.hasCycle

  for l in myDig.loops:
    doAssert false

  doAssert not myDig.hasLoop


block kelvin:
  let (myIn, myOut) = myDig.degrees

  for c in 0..1:
    doAssert myIn[c] == 0, $c
  for c in {2, 3, 4, 7, 8, 9, 10, 11, 19}:
    doAssert myIn[c] == 1, $c

  for c in {0, 2, 11, 19}:
    doAssert myOut[c] == 0, $c
  for c in {3, 4, 7, 9, 10}:
    doAssert myOut[c] == 1, $c
  for c in {1, 8}:
    doAssert myOut[c] == 2, $c




doAssert not myDig.hasDeadReferences
