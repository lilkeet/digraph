 
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 10.0
  targets: "c cpp js objc"
  matrix: ""
"""

import
  std / [with, sets, algorithm, sugar, importutils],
  ../../src/digraph/[acyclic, algos],
  ../utils

block test1:
  var myDag = Dag[int]()
  with myDag:
    inclEdge(1, 2)
    inclEdge(1, 3)
    inclEdge(3, 4)
    incl(5)

  block priv:
    privateAccess Dag
    doAssert not myDag.graph.hasCycle()

  const CorrectOrderings = [[5, 1, 2, 3, 4],
    [1, 5, 2, 3, 4],
    [1, 2, 5, 3, 4],
    [1, 2, 3, 5, 4],
    [1, 2, 3, 4, 5],
    [5, 1, 3, 4, 2],
    [1, 5, 3, 4, 2],
    [1, 3, 5, 4, 2],
    [1, 3, 4, 5, 2],
    [1, 3, 4, 2, 5],
    [1, 3, 2, 4, 5],
    [1, 5, 3, 2, 4],
    [5, 1, 3, 2, 4],
    [1, 3, 5, 2, 4],
    [1, 3, 2, 5, 4]].toHashSet

  for correct in CorrectOrderings:
    doAssert correct.isValidTopologicalSortOf(myDag)

  var current = [1, 2, 3, 4, 5]

  var AllPossibleOrderings = collect:
    while nextPermutation(current):
      {current}

  AllPossibleOrderings.incl [1, 2, 3, 4, 5]

  let IncorrectOrderings = AllPossibleOrderings - CorrectOrderings

  for incorrect in IncorrectOrderings:
    doAssert not incorrect.isValidTopologicalSortOf(myDag)

  let khan = myDag.topologicalSort(Kahns)
  doAssert khan.isValidTopologicalSortOf(myDag)

  let df = myDag.topologicalSort(DepthFirstSearch)
  doAssert df.isValidTopologicalSortOf(myDag)


block test2:
  # from 'The Algorithm Design Manual' by Steven S Skiena page 179 figure 5.15
  var myDag2 = Dag[char]()
  with myDag2:
    incl('A')
    incl('B')
    incl('C')
    incl('D')
    incl('E')
    incl('F')
    incl('G')

    inclEdge 'A', 'B'
    inclEdge 'A', 'C'

    inclEdge 'B', 'D'
    inclEdge 'B', 'C'

    inclEdge 'C', 'F'
    inclEdge 'C', 'E'

    inclEdge 'E', 'D'

    inclEdge 'F', 'E'

    inclEdge 'G', 'A'
    inclEdge 'G', 'F'

  block priv:
    privateAccess Dag
    doAssert not myDag2.graph.hasCycle()
    doAssert not myDag2.graph.hasDeadReferences()

  let kahnsSorted = myDag2.topologicalSort(Kahns)
  doAssert kahnsSorted == @['G', 'A', 'B', 'C', 'F', 'E', 'D']
  doAssert kahnsSorted.isValidTopologicalSortOf(myDag2)

  let dfsSorted = myDag2.topologicalSort(DepthFirstSearch)
  doAssert dfsSorted == @['G', 'A', 'B', 'C', 'F', 'E', 'D']
  doAssert dfsSorted.isValidTopologicalSortOf(myDag2)
