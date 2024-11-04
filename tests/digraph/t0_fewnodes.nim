
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 10.0
  targets: "c cpp js objc"
  valgrind: on
  matrix: "-d:useMalloc"
"""

import
  std / [sequtils],
  ../../src/digraph,
  ../../src/digraph/[algos],
  ../utils


var myDig = DiGraph[int]()
let
  node1 = 1
  node2 = 2
  node3 = 3
  node4 = 4
  node5 = 5

myDig.incl node1, node2, node3, node4, node5

block integrity:
  doAssert not myDig.hasTwoCycle()
  doAssert not myDig.hasLoop()
  doAssert not myDig.hasDeadReferences()

myDig.inclEdge node1, node2
myDig.inclEdge node1, node3
myDig.inclEdge node3, node4

block integrity:
  doAssert not myDig.hasTwoCycle()
  doAssert not myDig.hasLoop()
  doAssert not myDig.hasDeadReferences()

block connections:
  doAssert node1.isAncestorOf(node2, myDig)
  doAssert node1.isAncestorOf(node3, myDig)
  doAssert node1.isAncestorOf(node4, myDig)
  doAssert node3.isAncestorOf(node4, myDig)

  doAssert not node1.isAncestorOf(node5, myDig)
  doAssert not node5.isAncestorOf(node3, myDig)
  doAssert not node4.isAncestorOf(node4, myDig)

  doAssert node4.isDescendentOf(node1, myDig)
  doAssert node4.isDescendentOf(node3, myDig)
  doAssert node3.isDescendentOf(node1, myDig)
  doAssert node2.isDescendentOf(node1, myDig)

  doAssert not node1.isDescendentOf(node5, myDig)
  doAssert not node5.isDescendentOf(node3, myDig)
  doAssert not node4.isDescendentOf(node4, myDig)

  doAssert myDig.childrenOf(node1).card == 2
  doAssert myDig.childrenOf(node5).card == 0
  doAssert myDig.childrenOf(node4).card == 0

  doAssert myDig.descendentsOf(node1).toSeq.len == 3
  doAssert myDig.descendentsOf(node5).toSeq.len == 0
  doAssert myDig.descendentsOf(node4).toSeq.len == 0

block notinDig:
  doAssert 7 notin myDig
  doAssert 8 notin myDig

  doAssertRaises NodeNotinGraphError:
    discard 10.isDescendentOf(4, myDig)
  doAssertRaises NodeNotinGraphError:
    discard 22.isDescendentOf(5, myDig)

  doAssertRaises NodeNotinGraphError:
    discard myDig.childrenOf(88)




myDig.excl node2
myDig.exclEdge node1, node3
myDig.excl node1

block integrity:
  doAssert not myDig.hasTwoCycle()
  doAssert not myDig.hasLoop()
  doAssert not myDig.hasDeadReferences()

block connections:
  doAssertRaises NodeNotinGraphError:
    discard node1.isAncestorOf(node2, myDig)
  doAssertRaises NodeNotinGraphError:
    discard not node1.isAncestorOf(node3, myDig)
  doAssertRaises NodeNotinGraphError:
    discard not node1.isAncestorOf(node4, myDig)
  doAssert node3.isAncestorOf(node4, myDig)

  doAssertRaises NodeNotinGraphError:
    discard node1.isAncestorOf(node5, myDig)
  doAssert not node5.isAncestorOf(node3, myDig)
  doAssert not node4.isAncestorOf(node4, myDig)

  doAssertRaises NodeNotinGraphError:
    discard node4.isDescendentOf(node1, myDig)
  doAssert node4.isDescendentOf(node3, myDig)
  doAssertRaises NodeNotinGraphError:
    discard node3.isDescendentOf(node1, myDig)
  doAssertRaises NodeNotinGraphError:
    discard node2.isDescendentOf(node1, myDig)

  doAssertRaises NodeNotinGraphError:
    discard node1.isDescendentOf(node5, myDig)
  doAssert not node5.isDescendentOf(node3, myDig)
  doAssert not node4.isDescendentOf(node4, myDig)

  doAssertRaises NodeNotinGraphError:
    discard myDig.childrenOf(node1)
  doAssert myDig.childrenOf(node5).card == 0
  doAssert myDig.childrenOf(node4).card == 0

  doAssertRaises NodeNotinGraphError:
    discard myDig.descendentsOf(node1).toSeq.len
  doAssert myDig.descendentsOf(node5).toSeq.len == 0
  doAssert myDig.descendentsOf(node4).toSeq.len == 0


var copied = myDig
clear copied
doAssert copied.card == 0
doAssert not copied.hasTwoCycle()
doAssert not copied.hasLoop()
doAssert not copied.hasDeadReferences()
