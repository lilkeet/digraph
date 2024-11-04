 
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 2.0
  targets: "c cpp js objc"
  valgrind: on
  matrix: "-d:useMalloc"
"""

import
  std / [tables],
  ../../src/digraph/private/[unsafetables]


var a = Table[int, string]()
a[5] = "test123"
doAssert a.unsafeGet(5) == "test123"

a.unsafeGet(5) = "new"
doAssert a.unsafeGet(5) == "new"
doAssert a[5] == "new"
