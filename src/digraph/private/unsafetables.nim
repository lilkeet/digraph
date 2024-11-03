
##[ This module contains *unsafe* table utilities for optimization
    purposes.
    ]##


import
  std / [tables {.all.}, hashes, importutils],
  ./debugtools

{.hint[Performance]:on.}
{.experimental: "strictFuncs".}
when defined(nimHasStrictDefs):
  {.experimental: "strictDefs".}

template getBody =
  debugAssert key in table, "Key defect."
  privateAccess Table
  var hc: Hash
  let index = rawGet(table, key, hc)
  result = table.data[index].val

func unsafeGet*[A; B](
    table: Table[A, B]; key: sink A
  ): lent B {.raises: [].} =
  ## Equivalent to `table[key]` but no check is made that `key in table`
  ## in release or danger builds.
  ## Undefined behavior when `key notin table`.
  getBody()



proc unsafeGet*[A; B](
    table: var Table[A, B]; key: sink A
  ): var B {.noSideEffect, raises: [].} =
  ## Equivalent to `table[key]` but no check is made that `key in table`
  ## in release or danger builds.
  ## Undefined behavior when `key notin table`.
  getBody()
