 
import
  std/[random, sequtils, sugar, strformat],
  ../src/digraph,
  ./status

const UseMalebolgia* {.booldefine.} = false

when UseMalebolgia:
  import
    malebolgia, malebolgia/paralgos
  export malebolgia


func generateTestGraph*[T: Ordinal or SomeFloat](
  numberOfNodes, numberOfEdges: int; randSeed: int64
): DiGraph[T] =
  ## Generates a graph with random values.
  var r = initRand(randSeed)

  result = DiGraph[T]()

  for _ in 0..<numberOfNodes:
    var newNode = rand[T](r, T.low..T.high)
    while newNode in result:
      newNode = rand[T](r, T.low..T.high)
    result.incl newNode

  let nodes = result.nodes.toSeq

  # we have to keep in mind that complete graphs exist and avoid running
  # into infinite loops.
  let
    maxAmountOfEdges = numberOfNodes*numberOfNodes
    amountOfEdgesToAdd = min(numberOfEdges, maxAmountOfEdges)
  for _ in 0..<amountOfEdgesToAdd:
    var
      parent = sample(r, nodes)
      child = sample(r, nodes)
    while child in result.childrenOf(parent):
      parent = sample(r, nodes)
      child = sample(r, nodes)
    result.inclEdge parent, child


proc generateTestGraphs*[T: Ordinal or SomeFloat](
    inputs: openArray[(int, int, int64)]
  ): seq[DiGraph[T]] =
  ## Generates a sequence of random graphs based on the same three parameters
  ## as `generateTestGraph`: the number of nodes, the number of edges,
  ## and a seed for random generation.
  initializeStatus fmt"Generating {inputs.len} graphs on 1 core..."

  result = newSeqOfCap[Digraph[T]](inputs.len)

  for index, (numberOfNodes, numberOfEdges, seed) in inputs:
    updateStatus index, inputs.high
    result.add generateTestGraph[T](numberOfNodes, numberOfEdges, seed)

  finishStatus fmt"Finished generating {inputs.len} graphs..."

when UseMalebolgia:
  proc parGenerateTestGraphs*[T: Ordinal or SomeFloat](
      inputs: openArray[(int, int, int64)]; bulksize: int
    ): seq[DiGraph[T]] =
    ## Generates a sequence of random graphs based on the same three parameters
    ## as `generateTestGraph`: the number of nodes, the number of edges,
    ## and a seed for random generation.
    ##
    ## Multiple cores are used.
    initializeSimpleStatus fmt"Generating {inputs.len} graphs on {ThreadPoolSize} cores..."

    template helper(input: (int, int, int64)): DiGraph[T] =
      generateTestGraph[T](input[0], input[1], input[2])

    result = inputs.parMap(bulksize, helper)

    finishSimpleStatus fmt"Finished generating {inputs.len} graphs..."


proc generateSparseGraphs*[T: Ordinal or SomeFloat](
    amountOfGraphs = 1_000; maxAmountOfNodes = 10_000
  ): seq[DiGraph[T]] =
  ## Generates random graphs with up to `maxAmountOfNodes` number of nodes and
  ## up to `2*maxAmountOfNodes` number of edges.

  let inputs = collect:
    for sampleNum in 0..<amountOfGraphs:
      # the number of edges can range from 0 to numberOfNodes^2.
      let
        numNodes = rand(10..maxAmountOfNodes)
        modifier = rand(0.0 .. 2.0)
        numEdges = int(numNodes.float * modifier)
      (numNodes, numEdges, int64(sampleNum))

  when UseMalebolgia:
    result = parGenerateTestGraphs[T](inputs, 50)
  else:
    result = generateTestGraphs[T](inputs)


proc generateDenseGraphs*[T: Ordinal or SomeFloat](
    amountOfGraphs = 100; maxAmountOfNodes = 1_000
  ): seq[DiGraph[T]] =
  ## Generates random graphs with up to `maxAmountOfNodes` number of nodes and
  ## up to `maxAmountOfNodes^2` number of edges.

  let inputs = collect:
    for sampleNum in 0..<amountOfGraphs:
      # the number of edges can range from 0 to numberOfNodes^2.
      let
        numNodes = rand(10..maxAmountOfNodes)
        modifier = rand(0.0 .. float(maxAmountOfNodes))
        numEdges = int(numNodes.float * modifier)
      (numNodes, numEdges, int64(sampleNum))

  when UseMalebolgia:
    result = parGenerateTestGraphs[T](inputs, 10)
  else:
    result = generateTestGraphs[T](inputs)
