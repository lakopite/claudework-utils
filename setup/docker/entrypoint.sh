#!/bin/bash
set -e

# entrypoint.sh: Idempotent first-run init + tmux session management
# Safe to run on every container start — checks before acting.

HOME_DIR="/home/claude"
UTILS_DIR="$HOME_DIR/utilities/claudework-utils"
SESSION="claude-work"

# --- SSH Key Setup ---
# Keys are mounted read-only at /run/secrets/; copy to ~/.ssh/ with correct perms.

if [ -f /run/secrets/ssh_key ]; then
  mkdir -p "$HOME_DIR/.ssh"
  cp /run/secrets/ssh_key "$HOME_DIR/.ssh/id_ed25519"
  chmod 600 "$HOME_DIR/.ssh/id_ed25519"

  if [ -f /run/secrets/ssh_pub ]; then
    cp /run/secrets/ssh_pub "$HOME_DIR/.ssh/id_ed25519.pub"
    chmod 644 "$HOME_DIR/.ssh/id_ed25519.pub"
  fi

  # Accept new host keys for GitHub (avoid interactive prompt)
  if ! grep -q 'github.com' "$HOME_DIR/.ssh/config" 2>/dev/null; then
    cat >> "$HOME_DIR/.ssh/config" <<'EOF'
Host github.com
  StrictHostKeyChecking accept-new
  IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 "$HOME_DIR/.ssh/config"
  fi
fi

# --- .bashrc PATH Setup ---
# Add claudework-utils/bash to PATH if the repo is cloned and PATH line is missing.

if [ -d "$UTILS_DIR/bash" ]; then
  marker='# claudework-utils'
  if ! grep -qF "$marker" "$HOME_DIR/.bashrc" 2>/dev/null; then
    cat >> "$HOME_DIR/.bashrc" <<EOF

$marker
export PATH="\$HOME/utilities/claudework-utils/bash:\$PATH"
EOF
    echo "[entrypoint] Added claudework-utils/bash to PATH in .bashrc"
  fi
fi

# --- Symlinks: Agents ---

if [ -d "$UTILS_DIR/agents" ]; then
  mkdir -p "$HOME_DIR/.claude"
  if [ ! -e "$HOME_DIR/.claude/agents" ]; then
    ln -s "$UTILS_DIR/agents" "$HOME_DIR/.claude/agents"
    echo "[entrypoint] Symlinked ~/.claude/agents -> $UTILS_DIR/agents"
  fi
fi

# --- Symlinks: Commands ---

if [ -d "$UTILS_DIR/commands" ]; then
  mkdir -p "$HOME_DIR/.claude"
  if [ ! -e "$HOME_DIR/.claude/commands" ]; then
    ln -s "$UTILS_DIR/commands" "$HOME_DIR/.claude/commands"
    echo "[entrypoint] Symlinked ~/.claude/commands -> $UTILS_DIR/commands"
  fi
fi

# --- Symlinks: Templates ---

if [ -d "$UTILS_DIR/templates" ]; then
  if [ ! -e "$HOME_DIR/templates" ]; then
    ln -s "$UTILS_DIR/templates" "$HOME_DIR/templates"
    echo "[entrypoint] Symlinked ~/templates -> $UTILS_DIR/templates"
  fi
fi

# --- Projects Directory ---

mkdir -p "$HOME_DIR/projects"

# --- Run ID ---
# Generate a run ID for this container start, stored as a tmux env var.

RUN_ID=$(xxd -l 4 -p /dev/urandom)

# --- tmux Session ---
# Create or attach to the claude-work session.

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "[entrypoint] Session $SESSION already exists, attaching..."
else
  echo "[entrypoint] Creating $SESSION session (run: $RUN_ID)..."
  tmux new-session -d -s "$SESSION" -n home-base
  tmux set-environment -t "$SESSION" CLAUDE_RUN_ID "$RUN_ID"

  # Source .bashrc in the home-base window
  tmux send-keys -t "$SESSION:home-base" "source ~/.bashrc" Enter
fi

# Keep the container alive — if someone attaches via `docker exec ... tmux attach`,
# the session is ready. If this is the foreground process, just wait.
exec tmux attach -t "$SESSION"
