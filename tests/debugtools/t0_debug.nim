 
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 2.0
  targets: "c cpp js objc"
  matrix: ""
"""

import
  ../../src/digraph/private/[debugtools {.all.}]


doAssert IsDebugBuild

doAssertRaises AssertionDefect:
  debugAssert false, "one"

doAssertRaises AssertionDefect:
  debugAssert 1 == 2, "one"

debugAssert true
debugAssert (2 + 2) == 4, "12345"

doAssertRaises AssertionDefect:
  debugAssert false, "test123 can u hear me?"

debugBlock:
  doAssert true

doAssertRaises AssertionDefect:
  debugBlock:
    doAssert false
