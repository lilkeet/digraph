import
  std/[monotimes, times, sets, math, strformat, streams, strutils, algorithm],
  ../src/digraph,
  ../src/digraph/algos,
  ./[randomgraph, status]

when UseMalebolgia:
  import
    malebolgia, malebolgia/paralgos

func median[T](samples: openArray[T]): T =
  result = samples.sorted()[samples.high div 2]

const SampleSize = 11 # an odd number for easier median

proc testCycleDetectionTime[T](
    graph: DiGraph[T]; algo: static[CycleDetectionAlgorithm]
): Duration =
  ## Detects whether the input graph has a cycle, and returns the median amount
  ## of time that it took to determine this answer.
  var sampleTimes: array[SampleSize, Duration]
  for value in sampleTimes.mitems:
    let start = getMonoTime()
    discard graph.hasTwoCycle(algo)
    value = getMonoTime() - start
  result = sampleTimes.median


proc testCycleDetectionTimes*[T](
    graphs: openArray[DiGraph[T]]; algo: static[CycleDetectionAlgorithm]
  ): seq[Duration] =
  initializeStatus:
    fmt"Testing cycle detection for {algo} on {graphs.len} graphs on 1 core..."

  result = newSeqOfCap[Duration](graphs.len)

  for index, graph in graphs:
    updateStatus index, graphs.high
    result.add testCycleDetectionTime(graph, algo)

  finishStatus:
    fmt"Finished cycle detection for {algo} on {graphs.len} graphs..."

when UseMalebolgia:
  proc parTestCycleDetectionTimes*[T](
      graphs: openArray[DiGraph[T]]; algo: static[CycleDetectionAlgorithm]
    ): seq[Duration] =
    initializeSimpleStatus:
      fmt"Testing cycle detection for {algo} on {graphs.len} graphs on " &
      fmt"{ThreadPoolSize} cores..."

    const me = algo

    template helper(data: DiGraph[int32]): Duration =
      data.testCycleDetectionTime(me)
    result = graphs.parMap(50, helper)

    finishSimpleStatus:
      fmt"Finished cycle detection for {algo} on {graphs.len} graphs..."



proc main =
  let (numNodes, numEdges, testGraphs) =
    generateDenseGraphsWithInfo[int32](amountOfGraphs = 100,
      maxAmountOfNodes = 1_000)

  when UseMalebolgia:
    let
      kTimes = testGraphs.parTestCycleDetectionTimes(Kahns)
      pTimes = testGraphs.parTestCycleDetectionTimes(PathBasedStrongComponent)
  else:
    let
      kTimes = testGraphs.testCycleDetectionTimes(Kahns)
      pTimes = testGraphs.testCycleDetectionTimes(PathBasedStrongComponent)


  var strm = openFileStream("data.csv", fmWrite)

  strm.writeLine ["Nodes", "Edges", "Kahns", "Path-based"].join(",")

  for index in 0..testGraphs.high:
    let
      v = numNodes[index]
      e = numEdges[index]
      kTime = kTimes[index]
      pTime = pTimes[index]
    strm.writeLine [$v, $e, $kTime.inNanoseconds,
      $pTime.inNanoseconds].join(",")



when isMainModule:
  main()
