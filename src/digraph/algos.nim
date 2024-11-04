
import
  std / [sugar, tables, importutils, deques, sequtils],
  ../digraph,
  ./private/[debugtools, unsafetables]

{.hint[Performance]:on.}
{.experimental: "strictFuncs".}
when defined(nimHasStrictDefs):
  {.experimental: "strictDefs".}

func unsafeChildrenOf[T](
    dig: DiGraph[T]; parent: T
  ): lent HashSet[T] {.inline, raises: [].} =
  ## Returns the children of the given node, with no checks performed that
  ## `parent` is in the graph.
  ##
  ## Checks are still performed in debug builds. This is for optimization
  ## and effects tracking purposes.
  privateAccess DiGraph
  result = dig.valuesToChildren.unsafeGet(parent)

type
  WalkAlgorithm* {.pure.} = enum
    DepthFirst, BreadthFirst

iterator unsafeWalkFrom*[T](
    dig: DiGraph[T]; start: T; shouldGiveUpOn: (T) -> bool;
    algo: static[WalkAlgorithm] = DepthFirst
): T {.effectsOf: shouldGiveUpOn, noSideEffect, raises: [].} =
  ## Same as `walkFrom` but no check is done that `start in dig`,
  ## except in debug builds.
  debugAssert start in dig,
    "Please only use this proc if ur certain that `start` is ur graph!"
  debugAssert not shouldGiveUpOn.isNil(),
    "Cannot pass nil procs to this iterator!"

  when algo == DepthFirst:
    # We'll avoid recursion via a closure iterator for compatibility and
    # performance.
    var stack: seq[T] = dig.unsafeChildrenOf(start).toSeq

    while stack.len > 0:
      let current = stack.pop()
      if not shouldGiveUpOn(current):
        yield current
        stack.add dig.unsafeChildrenOf(current).toSeq

    # for child in dig.unsafeChildrenOf(start):
    #   for n in dig.dfs(child, shouldGiveUpOn):
    #     yield n

  elif algo == BreadthFirst:
    var queue = Deque[T]()

    template loadQueueFrom(parent: T) =
      for child in dig.unsafeChildrenOf(parent):
        if not shouldGiveUpOn(child):
          queue.addLast child

    loadQueueFrom start

    while queue.len != 0:
      let node = queue.popFirst()
      if not shouldGiveUpOn(node): # must be called twice to prevent dbl yields
        loadQueueFrom node
        yield node

  else:
    {.fatal: "This WalkAlgorithm is not implemented.".}


iterator walkFrom*[T](
    dig: DiGraph[T]; start: T; shouldGiveUpOn: (T) -> bool;
    algo: static[WalkAlgorithm] = DepthFirst
): T {.effectsOf: shouldGiveUpOn, noSideEffect,
       raises: [NodeNotinGraphError].} =
  ##[Starts at node `start`, then walks along the graph
     according to the algorithm specified. It yields each node it comes to.
     Whether or not it should consider a node 'valid' and yield it is determined
     by the proc `shouldGiveUpOn`.
     If `shouldGiveUpOn(node) == true`, the node will not be yielded and
     the iteration will backtrack to the next valid node.
     Yields nothing if `start notin dig`.]##
  runnableExamples:
    import std / [sugar, sequtils]

    var myDiGraph = DiGraph[int]() # 1 -> 2 -> 3 -> 4 -> 5
    myDiGraph.incl 1, 2, 3, 4, 5
    myDiGraph.inclEdge 1, 2
    myDiGraph.inclEdge 2, 3
    myDiGraph.inclEdge 3, 4
    myDiGraph.inclEdge 4, 5

    assert myDiGraph.walkFrom(1, (n) => n == 4).toSeq == @[2, 3] # stops at 4
    assert myDiGraph.walkFrom(2, (n) => true).toSeq == @[] # always stops
    assert myDiGraph.walkFrom(2, (n) => false).toSeq == @[3, 4, 5] # never stops

  if unlikely(start notin dig):
    raiseNodeNotinGraphError(start)
  else:
    for node in dig.unsafeWalkFrom(start, shouldGiveUpOn, algo):
      yield node


iterator walkFrom*[T](
    dig: DiGraph[T]; start: T; algo: static[WalkAlgorithm] = DepthFirst
): T {.noSideEffect, raises: [NodeNotinGraphError].} =
  ##[Same as the main `walkFrom` iterator but never gives up on a node.]##
  for node in dig.walkFrom(start, (_) => false, algo):
    yield node

iterator descendentsOf*[T](
    dig: DiGraph[T]; ancestor: T; algo: static[WalkAlgorithm] = DepthFirst
): T {.noSideEffect, raises: [NodeNotinGraphError].} =
  ##[Yields each descendent of `ancestor`, never repeating.

     This is your classical Depth First and Breadth First Search algorithm.]##
  var visited = [ancestor].toHashSet()
  for descendent in dig.walkFrom(ancestor, (n) => n in visited, algo):
    visited.incl descendent
    yield descendent


func isDescendentOf*[T](
    possibleDescendant, possibleAncestor: T; dig: DiGraph[T]
): bool {.raises: [NodeNotinGraphError].} =
  result = false

  # the `walkFrom` iterator checks whether possible ancestor is in the graph,
  # but we want to be consistent about raising that error when one of the values
  # is not in the graph, so we'll raise for both:
  if possibleDescendant notin dig:
    raiseNodeNotinGraphError possibleDescendant
  else:
    for descendent in dig.descendentsOf(possibleAncestor):
      if descendent == possibleDescendant:
        return true


func isAncestorOf*[T](
    possibleAncestor, possibleDescendant: T; dig: DiGraph[T]
): bool {.inline, raises: [NodeNotinGraphError].} =
  possibleDescendant.isDescendentOf possibleAncestor, dig


iterator cycles*[T](dig: DiGraph[T]): seq[T] {.noSideEffect, raises: [].} =
  ##[Yields each cycle found in the dig.
     This includes loops.

     Uses the Path-based strong component algorithm.]##
  let maxCycleSize = dig.card
  var visited = HashSet[T]()

  for start in dig:
    if start in visited: continue

    var myResult = newSeqOfCap[T](maxCycleSize)
    myResult.add start

    for descendent in dig.unsafeWalkFrom(start,
        (n) => (n in visited) and (n != myResult[^1])):
      # Handle back-tracking:
      while descendent notin dig.unsafeChildrenOf(myResult[^1]):
        myResult.del myResult.high

      const NotFound = -1
      let descendentIndex = myResult.find(descendent)
      if descendentIndex == NotFound:
        myResult.add descendent
        visited.incl descendent
      else:
        yield myResult[descendentIndex..^1]
        visited.incl start
        break


func hasCycle*[T](dig: DiGraph[T]): bool {.raises: [].} =
  result = false
  for _ in dig.cycles:
    return true

type
  CycleDetectionAlgorithm* {.pure.} = enum
    Kahns, PathBasedStrongComponent
  CDA* = CycleDetectionAlgorithm


func hasTwoCycle*[T](
    dig: DiGraph[T];
    algo: static[CycleDetectionAlgorithm] = PathBasedStrongComponent
): bool {.raises: [].} =
  ##[Returns `true` if a cycle of length two or greater is detected.
     **Kahns algorithm**
       * Best case: `O(V + E)`
       * Worst case: `O(V + E)`

     **Path-based strong component algorithm**
       * Best case: `O(1)`
       * Worst case: `O(V + E)`
    ]##

  when algo == PathBasedStrongComponent:
    result = false
    for cycle in dig.cycles:
      if cycle.len != 1: return true

  elif algo == Kahns:
    # We are using a modified Kahns algorithm where we dont actually keep track
    # of each node that we would be adding to a topological sort, but instead
    # we keep track of how many we would have added to the sorted list.
    # If the graph is acyclic, we should be returning exactly `dig.card`.
    # If there is a cycle in it, we should be returning less than `dig.card`.

    # A count of how many nodes we would be adding to the sorted list.
    var yieldCounter = 1

    var inDegree = dig.inDegrees

    # A queue made up of nodes with zero edges pointing at them.
    var zeroInDegreeQueue: seq[T] = @[]
    for node in dig:
      if inDegree.unsafeGet(node) == 0:
        zeroInDegreeQueue.add node

    while zeroInDegreeQueue.len != 0:
      let current = zeroInDegreeQueue.pop()
      inc yieldCounter

      for child in dig.unsafeChildrenOf(current):
        dec inDegree.unsafeGet(child)
        if inDegree.unsafeGet(child) == 0: zeroInDegreeQueue.add child

    result = yieldCounter < dig.card

  else:
    {.fatal: "Cycle algorithm not implemented.".}


iterator loops*[T](dig: DiGraph[T]): T {.noSideEffect, raises: [].} =
  for node, children in dig:
    if node in children:
      yield node

func hasLoop*[T](dig: DiGraph[T]): bool {.raises: [].} =
  result = false
  for _ in dig.loops:
    return true

func inDegrees*[T](dig: DiGraph[T]): Table[T, int] {.raises: [].} =
  result = Table[T, int]()

  template initialize(value: T) =
    discard result.hasKeyOrPut(value, 0)

  for parent, children in dig:
    initialize parent
    for child in children:
      initialize child
      inc result.unsafeGet(child)

func degrees*[T](
    dig: DiGraph[T]
): tuple[inDegrees, outDegrees: Table[T, int]] {.raises: [].} =
  runnableExamples:
    var myDag = DiGraph[int]()
    myDag.inclEdge 1, 2
    myDag.inclEdge 1, 3
    myDag.inclEdge 3, 4
    myDag.incl 5

    let (degreesIn, degreesOut) = myDag.degrees()
    assert degreesIn[1] == 0
    assert degreesIn[2] == 1
    assert degreesIn[5] == 0

    assert degreesOut[1] == 2
    assert degreesOut[2] == 0
    assert degreesOut[5] == 0

  result.inDegrees = Table[T, int]()
  result.outDegrees = Table[T, int]()

  template initialize(value: T) =
    discard result.inDegrees.hasKeyOrPut(value, 0)
    discard result.outDegrees.hasKeyOrPut(value, 0)

  for parent, children in dig:
    initialize parent
    for child in children:
      initialize child

      inc result.inDegrees.unsafeGet(child)
      inc result.outDegrees.unsafeGet(parent)

export tables

func isBalanced*[T](dig: DiGraph[T]): bool =
  result = true
  let r = dig.degrees
  for node, degree in r.inDegrees:
    if r.outDegrees[node] == degree:
      return false
