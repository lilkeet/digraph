 
discard """
  action: "run"
  batchable: true
  joinable: true
  timeout: 2.0
  targets: "c cpp js objc"
  matrix: "-d:release; -d:danger"
"""

import
  ../../src/digraph/private/[debugtools {.all.}]


assert not IsDebugBuild

# no checks when in release
debugAssert false, "one"

debugAssert 1 == 2, "one"

debugAssert true
debugAssert (2 + 2) == 4, "12345"
