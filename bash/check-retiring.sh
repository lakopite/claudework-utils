#!/bin/bash

# check-retiring: UserPromptSubmit hook that rejects prompts on retired bastions
# Used in .claude/settings.local.json to block commands sent to rotated-out bastions

window=$(tmux display-message -p -t "$TMUX_PANE" '#W' 2>/dev/null)
if [[ "$window" == *retiring* ]]; then
  echo "This bastion has been rotated out. Please disconnect and reconnect to the active bastion." >&2
  exit 2
fi
exit 0
