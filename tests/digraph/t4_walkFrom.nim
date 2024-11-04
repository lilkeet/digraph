 
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
  std / [with, sequtils, sugar, math],
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

doAssert not myDig.hasTwoCycle(PathBasedStrongComponent)
doAssert not myDig.hasTwoCycle(Kahns)
doAssert not myDig.hasLoop
doAssert not myDig.hasCycle

block simpleAlgos:
  block depth:
    var count = 0
    for node in myDig.walkFrom(3, DepthFirst):
      let expected = case count
        of 0: {4}
        of 1: {7}
        of 2: {8}
        of 3: {9, 10}
        of 4: {19, 11}
        of 5: {9, 10}
        of 6: {19, 11}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count

  block breadth:
    var count = 0
    for node in myDig.walkFrom(3, BreadthFirst):
      let expected = case count
        of 0: {4}
        of 1: {7}
        of 2: {8}
        of 3: {9, 10}
        of 4: {9, 10}
        of 5: {19, 11}
        of 6: {19, 11}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count


block simpleAlgosFromDiffStart:
  block depth:
    var count = 0
    for node in myDig.walkFrom(8, DepthFirst):
      let expected = case count
        of 0: {9, 10}
        of 1: {11, 19}
        of 2: {9, 10}
        of 3: {11, 19}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count

  block breadth:
    var count = 0
    for node in myDig.walkFrom(8, BreadthFirst):
      let expected = case count
        of 0: {9, 10}
        of 1: {9, 10}
        of 2: {11, 19}
        of 3: {11, 19}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count


block nvrYield:
  for node in myDig.walkFrom(3, (_) => true, BreadthFirst):
    doAssert false

  for node in myDig.walkFrom(3, (_) => true, BreadthFirst):
    doAssert false


block alwaysYield:
  # These should be the same as the simpleAlgos block.
  block depth:
    var count = 0
    for node in myDig.walkFrom(3, (_) => false, DepthFirst):
      let expected = case count
        of 0: {4}
        of 1: {7}
        of 2: {8}
        of 3: {9, 10}
        of 4: {19, 11}
        of 5: {9, 10}
        of 6: {19, 11}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count

  block breadth:
    var count = 0
    for node in myDig.walkFrom(3, (_) => false, BreadthFirst):
      let expected = case count
        of 0: {4}
        of 1: {7}
        of 2: {8}
        of 3: {9, 10}
        of 4: {9, 10}
        of 5: {19, 11}
        of 6: {19, 11}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count

block easyTest:
  block depth:
    var count = 0
    for node in myDig.walkFrom(3, (n) => n == 9, DepthFirst):
      let expected = case count
        of 0: {4}
        of 1: {7}
        of 2: {8}
        of 3: {10}
        of 4: {11}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count

  block breadth:
    var count = 0
    for node in myDig.walkFrom(3, (n) => n == 9, BreadthFirst):
      let expected = case count
        of 0: {4}
        of 1: {7}
        of 2: {8}
        of 3: {10}
        of 4: {11}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count

block closures:
  proc myClosureTest() {.noinline.} =
    var mySet = {2}
    mySet.incl 10

    proc tester(n: int): bool {.closure.} =
      n in mySet

    mySet.incl 200

    block depth:
      var count = 0
      for node in myDig.walkFrom(3, tester, DepthFirst):
        let expected = case count
          of 0: {4}
          of 1: {7}
          of 2: {8}
          of 3: {9}
          of 4: {19}
          else:
            doAssert false, "Defect in graph construction."
            {}
        doAssert node in expected
        inc count

    block breadth:
      var count = 0
      for node in myDig.walkFrom(3, tester, BreadthFirst):
        let expected = case count
          of 0: {4}
          of 1: {7}
          of 2: {8}
          of 3: {9}
          of 4: {19}
          else:
            doAssert false, "Defect in graph construction."
            {}
        doAssert node in expected
        inc count

  myClosureTest()


block nimcall:
  func myFunc(n: int): bool {.nimcall.} =
    result = n == 9

  block depth:
    var count = 0
    for node in myDig.walkFrom(3, myFunc, DepthFirst):
      let expected = case count
        of 0: {4}
        of 1: {7}
        of 2: {8}
        of 3: {10}
        of 4: {11}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count

  block breadth:
    var count = 0
    for node in myDig.walkFrom(3, myFunc, BreadthFirst):
      let expected = case count
        of 0: {4}
        of 1: {7}
        of 2: {8}
        of 3: {10}
        of 4: {11}
        else:
          doAssert false, "Defect in graph construction."
          {}
      doAssert node in expected
      inc count


func isPrime(n: int): bool =
  # Check if the number is 2 or 3 (both prime)
  if n == 2 or n == 3:
    return true
  # Exclude even numbers and multiples of 3
  if n mod 2 == 0 or n mod 3 == 0:
    return false
  # Check possible divisors up to the square root of n
  var i = 5
  while i * i <= n:
    if n mod i == 0 or n mod (i + 2) == 0:
      return false
    i += 6
  # If no divisors were found, n is prime
  result = true

let myRing = block:
  # made up of prime numbers
  var r = DiGraph[int]()

  const First = 2
  var prev = First
  for current in 3..1_000:
    if current.isPrime:
      r.inclEdge prev, current
      prev = current

  let last = prev
  r.inclEdge last, First
  r

doAssert myRing.hasTwoCycle(PathBasedStrongComponent)
doAssert myRing.hasTwoCycle(Kahns)
doAssert not myRing.hasLoop
doAssert myRing.hasCycle

block testCycle:
  block depth:
    var cycleCount = 1
    var seen: seq[int] = @[]

    proc isFirstTripAround(): bool =
      cycleCount == 1

    proc startingNode(): int =
      seen[0]

    for node in myRing.walkFrom(2, DepthFirst):
      doAssert node.isPrime
      if isFirstTripAround():
        seen.add node
        if node == startingNode():
          inc cycleCount
      else:
        if node == startingNode():
          inc cycleCount

      if cycleCount > 10:
        break

  block breadth:
    var cycleCount = 1
    var seen: seq[int] = @[]

    proc isFirstTripAround(): bool =
      cycleCount == 1

    proc startingNode(): int =
      seen[0]

    for node in myRing.walkFrom(2, BreadthFirst):
      doAssert node.isPrime
      if isFirstTripAround():
        seen.add node
        if node == startingNode():
          inc cycleCount
      else:
        if node == startingNode():
          inc cycleCount

      if cycleCount > 10:
        break


block nodeNotInGraph:
  block depth:
    doAssertRaises NodeNotinGraphError:
      for n in myRing.walkFrom(1, DepthFirst):
        discard

  block breadth:
    doAssertRaises NodeNotinGraphError:
      for n in myRing.walkFrom(1, BreadthFirst):
        discard




doAssert not myDig.hasDeadReferences
doAssert not myRing.hasDeadReferences
