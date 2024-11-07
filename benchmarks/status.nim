
import
  std/[terminal, strutils, with, math]

proc initializeStatus*(caption: string) =
  with stdout:
    styledWriteLine fgYellow, caption
    styledWriteLine fgRed, "0% ", fgDefault, fgYellow, ' '.repeat 100, "0%"

proc updateStatus*[T: SomeNumber](current, total: T) =
  # we'll follow an exponential curve since linear progress bars are bad ui
  let progress = int((current / total)^2 * 100)
  with stdout:
    cursorUp 1
    eraseLine()
    styledWriteLine fgRed, "0% ", fgDefault, '#'.repeat progress,
      if progress > 50: fgGreen else: fgYellow, ' '.repeat 100 - progress,
      $progress , "%"

proc finishStatus*(permanentCaption: string) =
  with stdout:
    cursorUp 1
    eraseLine()
    cursorUp 1
    eraseLine()
    styledWriteLine fgGreen, permanentCaption


proc initializeSimpleStatus*(caption: string) =
  with stdout:
    styledWriteLine fgYellow, caption

proc finishSimpleStatus*(permanentCaption: string) =
  with stdout:
    cursorUp 1
    eraseLine()
    styledWriteLine fgGreen, permanentCaption
