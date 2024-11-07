
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


type TableIndex*[A, B] = distinct int
  ## An index to a location in a table.

func getIndex*[A; B](
    table: Table[A, B]; key: sink A
  ): TableIndex[A, B] {.raises: [].} =
  ## Returns a key to a location in the table passed to this function.
  ## Checks are only made in debug builds.
  debugAssert key in table, "Key defect."
  var hc: Hash
  result = TableIndex[A, B](rawGet(table, key, hc))


# type KeyValuePair*[A, B] = tuple[hcode: Hash, key: A, val: B]

func getKey*[A; B](
    table: Table[A, B]; index: sink TableIndex[A, B]
  ): lent A {.inline, raises: [].} =
  ## Returns the value held in the table at input location.
  privateAccess Table
  result = table.data[int index].key

func getValue*[A; B](
    table: Table[A, B]; index: sink TableIndex[A, B]
  ): lent B {.inline, raises: [].} =
  ## Returns the value held in the table at input location.
  privateAccess Table
  result = table.data[int index].val

func getValue*[A; B](
    table: var Table[A, B]; index: sink TableIndex[A, B]
  ): var B {.inline, raises: [].} =
  ## Returns the value held in the table at input location.
  privateAccess Table
  result = table.data[int index].val


func unsafeGet*[A; B](
    table: Table[A, B]; key: sink A
  ): lent B {.raises: [].} =
  ## Equivalent to `table[key]` but no check is made that `key in table`
  ## in release or danger builds.
  ## Undefined behavior when `key notin table`.
  let index = getIndex(table, key)
  result = table.getValue(index)

func unsafeGet*[A; B](
    table: var Table[A, B]; key: sink A
  ): var B {.inline, raises: [].} =
  ## Equivalent to `table[key]` but no check is made that `key in table`
  ## in release or danger builds.
  ## Undefined behavior when `key notin table`.
  let index = getIndex(table, key)
  result = table.getValue(index)
