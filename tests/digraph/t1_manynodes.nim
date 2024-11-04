
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 40.0
  targets: "c cpp js objc"
  valgrind: off
  matrix: ""
"""

import
  std / [sets, with],
  ../../src/digraph,
  ../utils


var myDag = DiGraph[int]()

# Initialize a set to keep track of all nodes added.
var nodesSeen = HashSet[int]()

for i in 0..1_000:
  let
    nodeA = i
    nodeB = i*50
    nodeC = i div 20

  with myDag:
    incl nodeA, nodeB, nodeC

    inclEdge nodeA, nodeB
    inclEdge nodeA, nodeC
    inclEdge nodeB, nodeC

  # Record the nodes in the nodesSeen set.
  with nodesSeen:
    incl nodeA
    incl nodeB
    incl nodeC

# Ensure there are no invalid references in the graph.
doAssert not myDag.hasDeadReferences()

# Verify the graph does actually contain all the nodes we should've added.
doAssert myDag.card == nodesSeen.card

# Create a copy of the graph.
var copied = myDag

# Remove all nodes from the original graph.
for node in nodesSeen:
  myDag.excl node

# Check that the original graph is now empty.
doAssert myDag.card == 0

# Ensure there are no dead references after node removal.
doAssert not myDag.hasDeadReferences()

# Clear all nodes and edges from the copied graph.
clear copied

# Verify the copied graph is now empty.
doAssert copied.card == 0

# Ensure no dead references exist in the copied graph.
doAssert not copied.hasDeadReferences()
