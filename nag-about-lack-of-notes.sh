#!/bin/bash
/usr/bin/osascript <<END
  tell app "Finder" to display dialog "What have you been doing since $1? Please press Ctrl-Shift-A to record a new action."
END
