
##[ This module contains *unsafe* table utilities for optimization
    purposes.
    ]##


import
  std / [tables {.all.}, hashes, importutils],
  ./debugtools

# import hashcommon

# discard rawget

{.hint[Performance]:on.}
{.experimental: "strictFuncs".}
when defined(nimHasStrictDefs):
  {.experimental: "strictDefs".}


type TableIndex*[A, B] = distinct int
  ## An index to a location in a table.

func `<`(a, b: TableIndex): bool {.borrow.}

func myRawGet[A, B](t: Table[A, B]; key: A; hc: out Hash): TableIndex[A, B] {.inline.} =
  hc = hash(key)
  if hc == 0: # This almost never taken branch should be very predictable.
    when sizeof(int) < 4:
      hc = 31415 # Value doesn't matter; Any non-zero favorite is fine <= 16-bit.
    else:
      hc = 314159265 # Value doesn't matter; Any non-zero favorite is fine.

  privateAccess Table
  debugAssert t.dataLen != 0, "Table construction defect."
  # if t.dataLen == 0:
  #   return -1
  var h: Hash = hc and maxHash(t) # start with real hash value
  while isFilled(t.data[h].hcode):
    # Compare hc THEN key with boolean short circuit. This makes the common case
    # zero ==key's for missing (e.g.inserts) and exactly one ==key for present.
    # It does slow down succeeding lookups by one extra Hash cmp&and..usually
    # just a few clock cycles, generally worth it for any non-integer-like A.
    if t.data[h].hcode == hc and t.data[h].key == key:
      return TableIndex[A, B](h)
    h = nextTry(h, maxHash(t))
  result = TableIndex[A, B](-1 - h) # < 0 => MISSING; insert idx = -1 - result



func getIndex*[A; B](
    table: Table[A, B]; key: sink A
  ): TableIndex[A, B] {.raises: [].} =
  ## Returns a key to a location in the table passed to this function.
  ## Checks are only made in debug builds.
  debugAssert key in table, "Key defect."
  var hc: Hash
  result = myRawGet(table, key, hc)


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




func myRawInsert[A, B](
    t: var Table[A, B]; theKey: sink A; newVal: sink B; hc: sink Hash;
    h: sink TableIndex[A, B]
  ) {.inline.} =
  privateAccess Table
  t.data[int h].key = theKey
  t.data[int h].val = newVal
  t.data[int h].hcode = hc
  inc t.counter

func defaultOrInc*[A; B: Ordinal](t: var Table[A, B], key: sink A) =
  ## If the table does not have a value stored at `key`, the default value
  ## is put there.
  ## If it does have a value there, it is incremented.
  ##
  ## This proc assumes that your table is already at a good size!
  # privateAccess Table
  var hc: Hash
  var index = myRawGet(t, key, hc)
  if index < TableIndex[A, B](0):
    debugAssert not mustRehash(t), "Table construction defect."
    # if mustRehash(t):
    #   enlarge(t)
    #   index = rawGetKnownHC(t, key, hc)
    index = TableIndex[A, B](-1 - int(index)) # important to transform for mgetOrPutImpl
    t.myRawInsert(key, default(B), hc, index)
    # inc t.counter
  else:
    inc t.getValue(index)

