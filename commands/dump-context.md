---
allowed-tools: Bash(*), Read, Write, Glob
---
Create a context snapshot of this session and save it to ~/projects/shared/exports/.

Follow these steps precisely:

1. **Summarize the session context** — Review the entire conversation and produce a context snapshot. This is about preserving *understanding*, not tracking work. Focus on:
   - What we were exploring or discussing (the problem space, topic, or area)
   - Key insights, reasoning, and tradeoffs that came up (the stuff that took time to figure out)
   - Open questions or unresolved tensions (things we surfaced but didn't settle)
   - Files that were read, referenced, discussed, or changed — framed as awareness ("here's the terrain") not as a changelog. Include enough about each file's role that the next agent can orient quickly.
   - Do NOT include next steps, recommendations, or action items — the user and next agent will decide what to do. This is a context snapshot, not a task list or handoff doc.

2. **Generate a slug** — Based on the *content* of the context (not the first message), create a short descriptive kebab-case slug (2-4 words). Examples: `websocket-auth-flow`, `docker-compose-refactor`, `test-harness-setup`.

3. **Determine the filename** — The format is `YYMMDD-<slug>-vX.md` where:
   - YYMMDD is today's date
   - The slug is what you generated
   - X is auto-incremented: check ~/projects/shared/exports/ for existing files that start with the same `YYMMDD-<slug>-v` prefix, find the highest version number, and increment by 1. If none exist, start at v1.

4. **Write the file** to `~/projects/shared/exports/YYMMDD-<slug>-vX.md` with this structure:

```
# Context: <descriptive title>
> Exported: YYYY-MM-DD

## Topic
<What we were exploring or discussing>

## Insights
<Key reasoning, tradeoffs, and things we figured out>

## Relevant Files
<Files read/referenced/discussed/changed and their roles — for orientation, not as a changelog>

## Open Questions
<Unresolved tensions, things surfaced but not settled — omit this section if there are none>
```

5. **Report** the filename you wrote and a one-line summary.

If the user provided arguments, use them as a hint for what to focus on in the summary: $ARGUMENTS
