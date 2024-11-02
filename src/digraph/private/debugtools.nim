
##[This module implements tools used only in debug builds to check for
   defects.]##

const
  IsDebugBuild = (not defined(release)) and (not defined(danger))

template debugBlock*(body: untyped) =
  ## The code block passed to this template is only executed during
  ## debug builds.
  when IsDebugBuild:
    body

template debugAssert*(cond: untyped; msg="") =
  ## An assertion that only is checked in a debug or test build.
  debugBlock:
    assert cond, msg
