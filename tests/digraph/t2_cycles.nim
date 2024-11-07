
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 10.0
  targets: "c cpp js objc"
  valgrind: off
  matrix: ""
"""

##[This test verifies that the cycle detection algorithms correctly identify
   the absence and presence of cycles.
   ]##

import
  std / [with],
  ../../src/digraph,
  ../../src/digraph/algos


block simple:
  var myDig = DiGraph[int]()
  with myDig:
    inclEdge 1, 2
    inclEdge 2, 3
    inclEdge 3, 4
    inclEdge 4, 5

    inclEdge 3, 5

    inclEdge 10, 2

    inclEdge 55, 2

  # Verify that the graph currently has no cycles
  doAssert not myDig.hasCycle
  doAssert not myDig.hasLoop
  doAssert not myDig.hasTwoCycle(Kahns)
  doAssert not myDig.hasTwoCycle(PathBasedStrongComponent)

  myDig.inclEdge 5, 10 # Add an edge from node 5 to node 10, creating a cycle:
                       # The cycle is 2 -> 3 -> 4 -> 5 -> 10 -> 2

  # Verify that the graph now contains a cycle
  doAssert myDig.hasCycle
  doAssert myDig.hasTwoCycle(Kahns)
  doAssert myDig.hasTwoCycle(PathBasedStrongComponent)

block loop:
  var myDig = DiGraph[int]()
  with myDig:
    inclEdge 1, 2
    inclEdge 2, 3
    inclEdge 3, 4
    inclEdge 4, 5

    inclEdge 3, 5

    inclEdge 10, 2

    inclEdge 55, 2

  # Verify that the graph currently has no cycles
  doAssert not myDig.hasCycle
  doAssert not myDig.hasLoop
  doAssert not myDig.hasTwoCycle(Kahns)
  doAssert not myDig.hasTwoCycle(PathBasedStrongComponent)

  myDig.inclEdge 5, 5 # Add an edge from node 5 to node 5, creating a loop

  # Verify that the graph now contains a cycle
  doAssert myDig.hasCycle
  doAssert not myDig.hasTwoCycle(Kahns)
  doAssert not myDig.hasTwoCycle(PathBasedStrongComponent)
  doAssert myDig.hasLoop

block complex:
  var complexDigraph = DiGraph[int]()

  with complexDigraph:
    # Component 1: A simple acyclic chain
    inclEdge 1, 2
    inclEdge 2, 3
    inclEdge 3, 4

    # Component 2: A simple cycle
    inclEdge 5, 6
    inclEdge 6, 7
    inclEdge 7, 5  # This forms a cycle

    # Component 3: A disconnected node
    incl 8

    # Component 4: Complex cycles and branching
    inclEdge 9, 10
    inclEdge 10, 11
    inclEdge 11, 12
    inclEdge 12, 9   # Cycle back to 9
    inclEdge 11, 13
    inclEdge 13, 14
    inclEdge 14, 11  # Cycle back to 11
    inclEdge 13, 15

    # Cross edges connecting components
    inclEdge 3, 5    # From Component 1 to Component 2
    inclEdge 7, 9    # From Component 2 to Component 4
    inclEdge 4, 15   # From Component 1 to Component 4

  # Initially, the graph has cycles
  doAssert complexDigraph.hasCycle
  doAssert complexDigraph.hasTwoCycle(Kahns)
  doAssert complexDigraph.hasTwoCycle(PathBasedStrongComponent)
  doAssert not complexDigraph.hasLoop

  # Remove edges to break cycles
  with complexDigraph:
    exclEdge 7, 5   # Break cycle in Component 2
    exclEdge 12, 9  # Break cycle in Component 4
    exclEdge 14, 11 # Break another cycle in Component 4

  # Now, the graph should be acyclic
  doAssert not complexDigraph.hasLoop
  doAssert not complexDigraph.hasTwoCycle(Kahns)
  doAssert not complexDigraph.hasTwoCycle(PathBasedStrongComponent)
  doAssert not complexDigraph.hasCycle
