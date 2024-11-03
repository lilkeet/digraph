

import
  std / [tables, sets, sugar, importutils],
  ../[digraph],
  ./algos,
  ./private/unsafetables

{.hint[Performance]:on.}
{.experimental: "strictFuncs".}
when defined(nimHasStrictDefs):
  {.experimental: "strictDefs".}

type
  DirectedAcyclicGraph*[T] = object
    graph: DiGraph[T]
  Dag*[T] = DirectedAcyclicGraph[T]

iterator items*[T](dag: Dag[T]): T =
  for item in dag.graph:
    yield item

iterator pairs*[T](dag: Dag[T]
): (T, HashSet[T]) {.noSideEffect, raises: [].} =
  ## Returns each value (node) and its children in the Dag.
  for valueChildrenPair in dag.graph.pairs:
    yield valueChildrenPair

iterator nodes*[T](dag: Dag[T]): T {.noSideEffect, raises: [].} =
  for n in dag.graph.nodes:
    yield n


iterator edges*[T](dag: Dag[T]): Edge[T] {.noSideEffect, raises: [].} =
  for edge in dag.graph.edges:
    yield edge


func contains*[T](dag: Dag[T]; value: T): bool {.raises: [], inline.} =
  dag.graph.contains value

func card*[T](dag: Dag[T]): Natural {.raises: [], inline.} =
  ## Returns the number of nodes in the Dag.
  dag.graph.card

func childrenOf*[T](
    dag: Dag[T]; parent: T
): lent HashSet[T] {.raises: [NodeNotinGraphError], inline.} =
  ## Returns the immediate descendants of the given node.
  dag.graph.childrenOf parent


iterator unsafeWalkFrom*[T](
    dag: Dag[T]; start: T; shouldGiveUpOn: (T) -> bool;
    algo: static[WalkAlgorithm] = DepthFirst
): T {.effectsOf: shouldGiveUpOn, noSideEffect, raises: [].} =
  ## Same as `walkFrom` but no check is done that `start in dig`,
  ## except in debug builds.
  for node in dag.graph.unsafeWalkFrom(start, shouldGiveUpOn, algo):
    yield node

iterator walkFrom*[T](
    dag: Dag[T]; start: T; shouldGiveUpOn: (T) -> bool;
    algo: static[WalkAlgorithm] = DepthFirst
): T {.effectsOf: shouldGiveUpOn, noSideEffect,
       raises: [NodeNotinGraphError].} =
  ##[This iterator starts at node `start`, then walks along the graph
     according to the algorithm specified. It yields each node it comes to.
     Whether or not it should consider a node 'valid' and yield it is determined
     by the proc `shouldGiveUpOn`.
     If `shouldGiveUpOn(node) == true`, the node will not be yielded and
     the iteration will backtrack to the next valid node.
     Yields nothing if `start notin dig`.]##
  runnableExamples:
    import std / [sugar]

    var myDag = Dag[int]() # 1 -> 2 -> 3 -> 4 -> 5
    myDag.incl 1, 2, 3, 4, 5
    myDag.inclEdge 1, 2
    myDag.inclEdge 2, 3
    myDag.inclEdge 3, 4
    myDag.inclEdge 4, 5

    assert myDag.walkFrom(1, (n) => n == 4).toSeq == @[2, 3] # stops at 4
    assert myDag.walkFrom(2, (n) => true).toSeq == @[] # always stops
    assert myDag.walkFrom(2, (n) => false).toSeq == @[3, 4, 5] # never stops
  for node in dag.graph.walkFrom(start, shouldGiveUpOn, algo):
    yield node

iterator walkFrom*[T](
    dag: Dag[T]; start: T; algo: static[WalkAlgorithm] = DepthFirst
): T {.noSideEffect, raises: [NodeNotinGraphError].} =
  ##[Same as the main `walkFrom` iterator but never gives up on a node.]##
  for node in dag.graph.walkFrom(start, algo):
    yield node


iterator descendentsOf*[T](
    dag: Dag[T]; ancestor: T; algo: static[WalkAlgorithm] = DepthFirst
): T {.noSideEffect, raises: [NodeNotinGraphError].} =
  ##[Yields each descendent of `ancestor`, never repeating.]##
  for d in dag.graph.descendentsOf(ancestor, algo):
    yield d


func isDescendentOf*[T](
    possibleDescendant, possibleAncestor: T; dag: Dag[T]
): bool {.inline, raises: [NodeNotinGraphError].} =
  possibleDescendant.isDescendentOf(possibleAncestor, dag.graph)


func isAncestorOf*[T](
    possibleAncestor, possibleDescendant: T; dag: Dag[T]
): bool {.inline, raises: [NodeNotinGraphError].} =
  possibleAncestor.isAncestorOf(possibleDescendant, dag.graph)


func degrees*[T](
    dag: Dag[T]
): tuple[inDegrees, outDegrees: Table[T, int]] {.inline, raises: [].} =
  runnableExamples:
    var myDag = Dag[int]()
    myDag.inclEdge 1, 2
    myDag.inclEdge 1, 3
    myDag.inclEdge 3, 4
    myDag.incl 5

    let (degreesIn, degreesOut) = myDag.degrees()
    assert degreesIn[1] == 0
    assert degreesIn[2] == 1
    assert degreesIn[5] == 0

    assert degreesOut[1] == 2
    assert degreesOut[2] == 1
    assert degreesOut[5] == 0
  result = dag.graph.degrees

export tables


func isBalanced*[T](dag: Dag[T]): bool {.inline.} =
  result = dag.graph.isBalanced


func incl*[T](
    dag: var Dag[T]; value: T ) {.inline, raises: [].} =
  ## Adds a new node to the graph if its not already added.
  dag.graph.incl value

func incl*[T](
    dag: var Dag[T]; toAdd: varargs[T] ) {.inline, raises: [].} =
  ## Adds new nodes to the graph if they're not already added.
  dag.graph.incl toAdd

type
  CycleError* = object of ValueError
    ## Raised when trying to add a directed cycle to a DAG.

func inclEdge*[T](
    dag: var Dag[T]; parent, child: T) {.inline, raises: [CycleError].} =
  ## Adds an edge starting at parent and ending at child.
  ## If the nodes do not exist in the graph, they are added.
  ##
  ## This an expensive operation, done in `O(n)` where n is the number of
  ## nodes in the graph.
  proc abort() {.noReturn.} =
    raise newException(CycleError,
      "Attempted to create a cycle in an acyclic graph.")

  if parent == child: abort()

  dag.incl parent, child

  # Check for cycles
  var visited = HashSet[T]()
  for descendentOfChild in dag.unsafeWalkFrom(child, (n) => n in visited):
    visited.incl descendentOfChild
    if descendentOfChild == parent: abort()

  dag.graph.inclEdge parent, child

func excl*[T](
    dag: var Dag[T]; value: T ) {.inline, raises: [].} =
  ## Removes a value from the graph, including all edges that it is in.
  ##
  ## This is an expensive operation, done in an average of `O(V)` where V is
  ## the number of nodes in the graph.
  dag.graph.excl value

func excl*[T](
    dag: var Dag[T]; toAdd: varargs[T] ) {.inline, raises: [].} =
  ## Removes a value from the graph, including all edges that it is in.
  ##
  ## This is an expensive operation, done in an average of `O(V)` where V is
  ## the number of nodes in the graph.
  dag.graph.excl toAdd

func exclEdge*[T](
    dag: var Dag[T]; parent, child: T) {.inline, raises: [].} =
  ## Removes an edge from the graph if it is present.
  dag.graph.exclEdge parent, child

func clear*[T](dag: var Dag[T]) {.inline, raises: [].} =
  ## Removes all nodes and edges from the graph.
  clear dag.graph


when defined(testing):
  iterator deadReferences[T](
      dag: Dag[T]): tuple[extant, dead: T] {.noSideEffect, raises: [].} =
    {.push warning[ProveInit]: off.}
    ## This is here for testing and anyone doing unsafe stuff like accessing
    ## private symbols.
    for deadRef in dag.graph.deadReferences:
      yield deadRef

  func hasDeadReferences*[T](dag: Dag[T]): bool {.inline, raises: [].} =
    ## This is here for testing.
    dag.graph.hasDeadReferences


func toDag*[T](dig: DiGraph[T]): Dag[T] {.inline, raises: [CycleError].} =
  ## Converts a `DirectedGraph` into a `DirectedAcyclicGraph`.
  ##
  ## This an expensive operation, done in `O(V)` where V is the number of
  ## nodes in the graph.
  if dig.hasCycle:
    raise newException(CycleError,
      "Cannot make a cyclical graph into an acyclic.")
  else:
    result = Dag[T](graph: dig)



type
  TopologicalSortAlgorithm* = enum
    Kahns, DepthFirstSearch

func topologicalSort*[T](
  dag: Dag[T]; algo: static[TopologicalSortAlgorithm] = Kahns
): seq[T] {.raises: [].}=
  ##[Returns one possible topological sorting of the given Dag.
     ]##
  runnableExamples:
    var myDag = Dag[int]()
    myDag.inclEdge 1, 2
    myDag.inclEdge 1, 3
    myDag.inclEdge 3, 4
    myDag.incl 5

    assert myDag.topologicalSort(DepthFirstSearch) == @[5, 1, 3, 2, 4]
    assert myDag.topologicalSort(Kahns) == @[5, 1, 3, 4, 2]

  result = newSeq[T](dag.card)
  var resultIndex: int # used for positioning in the `yieldToResult` template.

  when algo == Kahns:
    resultIndex = 0 # start at 0 and increase

    template yieldToResult(toYield: T) =
      result[resultIndex] = toYield
      inc resultIndex

    var inDegree = dag.degrees.inDegrees
    var zeroInDegreeQueue = collect(newSeqOfCap(dag.card)):
      # A queue made up of nodes with zero edges pointing at them.
      for node in dag:
        if inDegree.unsafeGet(node) == 0: node

    while zeroInDegreeQueue.len != 0:
      let current = zeroInDegreeQueue.pop()
      yieldToResult current

      privateAccess DiGraph
      for child in dag.graph.valuesToChildren.unsafeGet(current):
        dec inDegree.unsafeGet(child)
        if inDegree.unsafeGet(child) == 0: zeroInDegreeQueue.add child

  elif algo == DepthFirstSearch:
    resultIndex = result.high # start at highest and decrease
    var visited = HashSet[T]() # all the nodes we've yielded

    template yieldToResult(toYield: T) =
      result[resultIndex] = toYield
      dec resultIndex
      visited.incl toYield

    for start in dag:
      if start in visited: continue

      for node in dag.unsafeWalkFrom(start, (n) => n in visited, DepthFirst):
        yieldToResult node

      yieldToResult start

  else:
    {.fatal: "Sorting algorithm not implemented.".}


type RepeatValueError = object of ValueError

func valuePositions[T](
    container: openarray[T]
): Table[T, Natural] {.raises: [RepeatValueError].} =
  ## Returns a table of each value's position.
  ## That is, given a sequence of unique values, this func returns a table
  ## from a value to its location in the container.
  result = Table[T, Natural]()
  for index, value in container:
    let repeatValueFound = result.hasKey(value)
    if unlikely(repeatValueFound):
      raise newException(RepeatValueError,
        "Container has the same value at multiple locations")
    else:
      result[value] = index


proc isValidTopologicalSortOf*[T](
  order: openArray[T]; graph: Dag[T]
): bool {.raises: [].} =
  ## Returns true if `order` is a valid topological sorting of `graph`.
  ## Returns false if it is not a valid sorting, including if `order` is not a
  ## subset of `graph`.
  result = true

  # Create a position table to track the position of each element in the array
  var positions: Table[T, Natural]
  try:
    positions = valuePositions(order)
  except RepeatValueError:
    return false

  try:
    # Check all edges in the graph
    for (parent, child) in graph.edges:
      # If any child appears before its parent, the order is invalid
      if positions[parent] > positions[child]:
        return false
  except KeyError:
    # Some value in `order` is not found in the graph.
    result = false


export digraph
