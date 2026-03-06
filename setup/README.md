# Setup

Scripts and configuration for bootstrapping a claudework session.

## claudework

Entry point script to create or attach to the `claude-work` tmux session. Run this as your personal user (e.g. `lakopite`), not as the `claude` user directly. It uses `sudo` to launch and manage the session under a dedicated `claude` OS user, which allows sandboxing (e.g. preventing automount access).

Install to your personal user's `~/.local/bin/claudework`.

## PATH setup (claude user)

Add the repo's `bash/` directory to the claude user's PATH in `~/.bashrc`:

```bash
export PATH="/path/to/claudework-utils/bash:$PATH"
```

This makes all bash utilities available without symlinks, and any scripts added to or removed from `bash/` are immediately available.
