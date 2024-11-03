 
##[
  This module implements a directed graph.

  The type uses value semantics paired with set usage/interface.
  So, a `DirectedGraph[int]` cannot have two nodes of value `2`.
  Also, the assignment operator `=` performs a copy of the graph.
  ]##

runnableExamples:
  # Tnitialize like any other type
  var myGraph = DiGraph[int]()

  # use `incl` to add nodes
  myGraph.incl 5
  myGraph.incl 6
  assert 5 in myGraph

  # use `inclEdge` to add edges
  myGraph.inclEdge 6, 7
  assert 7 in myGraph.childrenOf(6)

  # use `excl` to remove nodes and any edges that reference them.
  myGraph.excl 6
  assert 6 notin myGraph


import
  std / [tables, sets, strutils],
  ./digraph / private / [unsafetables]

{.hint[Performance]:on.}
{.experimental: "strictFuncs".}
when defined(nimHasStrictDefs):
  {.experimental: "strictDefs".}

type
  DirectedGraph*[T] = object
    ## A graph of nodes with pointed edges from a node to another.
    valuesToChildren: Table[T, HashSet[T]]

  DiGraph* = DirectedGraph

  NodeNotinGraphError* = object of KeyError


iterator items*[T](dig: DiGraph[T]): lent T {.noSideEffect, raises: [].} =
  ## Returns each value (node) stored in the DiGraph.
  for node in dig.valuesToChildren.keys:
    yield node

iterator pairs*[T](dig: DiGraph[T]
): lent (T, HashSet[T]) {.noSideEffect, raises: [].} =
  ## Returns each value (node) and its children in the DiGraph.
  for valueChildrenPair in dig.valuesToChildren.pairs:
    yield valueChildrenPair

iterator nodes*[T](dig: DiGraph[T]): lent T {.noSideEffect, raises: [].} =
  for n in dig.items:
    yield n

type Edge*[T] = tuple
  parent, child: T

iterator edges*[T](dig: DiGraph[T]): Edge[T] {.noSideEffect, raises: [].} =
  for parent, children in dig:
    for child in children:
      yield (parent, child)


func contains*[T](dig: DiGraph[T]; value: T): bool {.raises: [], inline.} =
  dig.valuesToChildren.haskey value

func card*[T](dig: DiGraph[T]): Natural {.raises: [], inline.} =
  ## Returns the number of nodes in the DiGraph.
  dig.valuesToChildren.len

type Printable = concept x
  ($x) is string

proc raiseNodeNotinGraphError*[T](
    node: sink T
) {.noReturn, raises: [NodeNotinGraphError].} =
  when node is Printable:
    raise newException(NodeNotinGraphError,
      "'" & $node & "' not found in graph.")
  else:
    raise newException(NodeNotinGraphError, "Node not found in graph.")

func childrenOf*[T](
    dig: DiGraph[T]; parent: T
): lent HashSet[T] {.raises: [NodeNotinGraphError], inline.} =
  ##[Returns the immediate descendants of the given node.

     * Best case: `O(1)`

     ]##
  if dig.valuesToChildren.hasKey(parent):
    result = dig.valuesToChildren.unsafeGet(parent)
  else:
    raiseNodeNotinGraphError(parent)

func incl*[T](
    dig: var DiGraph[T]; value: sink T ) {.inline, raises: [].} =
  ## Adds a new node to the graph if its not already added.
  if not dig.valuesToChildren.hasKey(value):
    dig.valuesToChildren[value] = initHashSet[T](8)

func incl*[T](
    dig: var DiGraph[T]; toAdd: varargs[T] ) {.inline, raises: [].} =
  ## Adds new nodes to the graph if they're not already added.
  for value in toAdd:
    dig.incl value

func inclEdge*[T](
    dig: var DiGraph[T]; parent, child: sink T) {.inline, raises: [].} =
  ## Adds an edge starting at parent and ending at child.
  ## If the nodes do not exist in the graph, they are added.
  dig.incl parent, child
  dig.valuesToChildren.unsafeGet(parent).incl child

func incl*[T](
  dig: var DiGraph[T]; edge: sink Edge[T]) {.inline, raises: [].} =
  ## Adds an edge starting at parent and ending at child.
  ## If the nodes do not exist in the graph, they are added.
  dig.inclEdge edge.parent, edge.child

func excl*[T](
    dig: var DiGraph[T]; toExclude: sink T) {.inline, raises: [].} =
  ## Removes a value from the graph, including all edges that it is in.
  ##
  ## This is an expensive operation, done in an average of `O(V)` where V is
  ## the number of nodes in the graph.
  dig.valuesToChildren.del toExclude
  for nodeChildren in dig.valuesToChildren.mvalues:
    nodeChildren.excl toExclude

func excl*[T](
    dig: var DiGraph[T]; toExclude: varargs[T]) {.inline, raises: [].} =
  ## Removes a value from the graph, including all edges that it is in.
  ##
  ## This is an expensive operation, done in an average of `O(V)` where V is
  ## the number of nodes in the graph.
  for excluding in toExclude:
    dig.valuesToChildren.del excluding
  for nodeChildren in dig.valuesToChildren.mvalues:
    for excluding in toExclude:
      nodeChildren.excl excluding

func exclEdge*[T](
    dig: var DiGraph[T]; parent, child: sink T) {.inline, raises: [].} =
  ## Removes an edge from the graph if it is present.
  if parent in dig:
    dig.valuesToChildren.unsafeGet(parent).excl child


func clear*[T](dig: var DiGraph[T]) {.inline, raises: [].} =
  ## Removes all nodes and edges from the graph.
  clear dig.valuesToChildren


export sets
