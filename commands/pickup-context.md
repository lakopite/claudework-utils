---
allowed-tools: Bash(*), Read, Glob
---
Load a context snapshot from ~/projects/shared/exports/.

**If no arguments are provided ($ARGUMENTS is empty):**
- List all `.md` files in ~/projects/shared/exports/, sorted by modification time (newest first)
- Display them in a numbered list with filename and the first line of the "## About" section as a preview
- Ask the user which one to load

**If arguments are provided ($ARGUMENTS):**
- Search ~/projects/shared/exports/ for files whose names contain the argument text (case-insensitive fuzzy match — the argument just needs to be a substring of the filename or match parts of the slug)
- If exactly one match, load it
- If multiple matches, show them and ask the user to pick
- If no matches, list all available exports and let the user choose

**When loading a context file:**
- Read the full file contents
- Present it clearly to the user
- Say: "Context loaded. What would you like to do?"
- Do NOT take any actions or make suggestions — wait for the user to direct next steps
