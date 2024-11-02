 
import
  std / [sugar],
  ../src/digraph

iterator deadReferences[T](
    dig: DiGraph[T]): tuple[extant, dead: T] {.noSideEffect.} =
  {.push warning[ProveInit]: off.}
  let allExtant = collect:
    for node in dig:
      {node}
  {.pop.}
  for node in dig:
    for deadRef in dig.childrenOf(node) - allExtant:
      yield (node, deadRef)

func hasDeadReferences*[T](dig: DiGraph[T]): bool =
  result = false
  for _ in dig.deadReferences:
    return true
