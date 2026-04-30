#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_TOKEN="${OPENCLAW_TOKEN:-1}"
OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/workspace}"
OPENCLAW_AGENT_ID="${OPENCLAW_AGENT_ID:-main}"
OPENCLAW_MODEL_PRIMARY="${OPENCLAW_MODEL_PRIMARY:-openai-codex/gpt-5.4}"

# echo "==> [1/7] Downloading official OpenClaw installer"
# curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh -o /tmp/openclaw-install.sh
# chmod +x /tmp/openclaw-install.sh

# echo "==> [2/7] Running installer in non-interactive mode"
# bash /tmp/openclaw-install.sh --no-onboard
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

echo "==> [3/7] Fixing PATH for current session"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
hash -r

if ! command -v openclaw >/dev/null 2>&1; then
  echo "ERROR: openclaw not found after install"
  echo "PATH=$PATH"
  exit 1
fi

echo "==> [4/7] Preparing directories"
mkdir -p "$OPENCLAW_STATE_DIR"
mkdir -p "$OPENCLAW_STATE_DIR/agents/$OPENCLAW_AGENT_ID/agent"
mkdir -p "$OPENCLAW_WORKSPACE"

echo "==> [5/7] Writing openclaw.json"
cat > "$OPENCLAW_STATE_DIR/openclaw.json" <<EOF
{
  "auth": {
    "profiles": {
      "openai-codex:goodluck@zeigonfo.cc.cd": {
        "provider": "openai-codex",
        "mode": "oauth",
        "email": "goodluck@zeigonfo.cc.cd"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "$OPENCLAW_MODEL_PRIMARY"
      },
      "models": {
        "$OPENCLAW_MODEL_PRIMARY": {}
      },
      "workspace": "$OPENCLAW_WORKSPACE"
    }
  },
  "tools": {
    "profile": "coding",
    "web": {
      "search": {
        "enabled": true,
        "provider": "duckduckgo"
      }
    },
    "elevated": {
      "enabled": true,
      "allowFrom": {
        "webchat": [
          "*"
        ]
      }
    },
    "exec": {
      "host": "gateway",
      "security": "full",
      "ask": "off"
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "bash": true,
    "restart": true,
    "ownerDisplay": "raw"
  },
  "session": {
    "dmScope": "per-channel-peer"
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "controlUi": {
      "allowedOrigins": [
        "*"
      ],
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    },
    "auth": {
      "mode": "token",
      "token": "1"
    },
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    }
  },
  "plugins": {
    "entries": {
      "duckduckgo": {
        "enabled": true,
        "config": {}
      }
    }
  }
}
EOF

echo "==> [6/7] Writing auth-profiles.json inline"
cat > "$OPENCLAW_STATE_DIR/agents/$OPENCLAW_AGENT_ID/agent/auth-profiles.json" <<'EOF'
{
  "version": 1,
  "profiles": {
    "openai-codex:goodluck2031@zeigonfo.cc.cd": {
      "type": "oauth",
      "provider": "openai-codex",
      "access": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE5MzQ0ZTY1LWJiYzktNDRkMS1hOWQwLWY5NTdiMDc5YmQwZSIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsiaHR0cHM6Ly9hcGkub3BlbmFpLmNvbS92MSJdLCJjbGllbnRfaWQiOiJhcHBfRU1vYW1FRVo3M2YwQ2tYYVhwN2hyYW5uIiwiZXhwIjoxNzc4Mzk0MDU1LCJodHRwczovL2FwaS5vcGVuYWkuY29tL2F1dGgiOnsiYW1yIjpbIm90cCIsInVybjpvcGVuYWk6YW1yOm90cF9lbWFpbCJdLCJjaGF0Z3B0X2FjY291bnRfaWQiOiJiY2RlMmY5Yy0zMDM5LTRmZmUtOWE1Yy0yMTI5ZjU4MDM0MDMiLCJjaGF0Z3B0X2FjY291bnRfdXNlcl9pZCI6InVzZXItVWpYR0doU0dXaElaZzd6UmRYcjZrNzNUX19iY2RlMmY5Yy0zMDM5LTRmZmUtOWE1Yy0yMTI5ZjU4MDM0MDMiLCJjaGF0Z3B0X2NvbXB1dGVfcmVzaWRlbmN5Ijoibm9fY29uc3RyYWludCIsImNoYXRncHRfcGxhbl90eXBlIjoiZnJlZSIsImNoYXRncHRfdXNlcl9pZCI6InVzZXItVWpYR0doU0dXaElaZzd6UmRYcjZrNzNUIiwibG9jYWxob3N0Ijp0cnVlLCJ1c2VyX2lkIjoidXNlci1ValhHR2hTR1doSVpnN3pSZFhyNms3M1QifSwiaHR0cHM6Ly9hcGkub3BlbmFpLmNvbS9wcm9maWxlIjp7ImVtYWlsIjoiU2NobGl0elNocm9mZjc5M0BvdXRsb29rLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlfSwiaWF0IjoxNzc3NTMwMDU1LCJpc3MiOiJodHRwczovL2F1dGgub3BlbmFpLmNvbSIsImp0aSI6ImRkZjRiOWVmLTUwOWEtNDE3ZC04MWQ0LWViYjMxYzQ4ZTkzNyIsIm5iZiI6MTc3NzUzMDA1NSwicHdkX2F1dGhfdGltZSI6MTc3NjU4ODA3MjUxMywic2NwIjpbIm9wZW5pZCIsImVtYWlsIiwicHJvZmlsZSIsIm9mZmxpbmVfYWNjZXNzIl0sInNlc3Npb25faWQiOiJhdXRoc2Vzc19jMG1kWTRCY1NURWdyVmV4aGhUYUVpdVEiLCJzbCI6dHJ1ZSwic3ViIjoiYXV0aDB8Q0Y2YkdjSXREMDlrRzJoWUZQeVB0UDdPIn0.jK04mxEPRGZgFwMxXJVpkn5UAaFdMeqcw7eza9UsdreCG725ydblAFpu44af_0QDGXvYvrplzsgVBgE9Em8SK4dCVA1aGxcdXD2qmGreBtSBBULqqsHg5lwZwPtVsTwnOe2R7ZuUTsZ5R8vDOjsBUv5DvXNu8PX8DUskgIJfChLHBoJ-H1mfVMxYhetksJFcuyLmjQk3ODs5mk355Er2eeOocbcHBDF09TV-w4xwTIbs__-7EYXDY78FAkqQU2srajKTQi9zP4RLRmKLCVaRpM3-kcvsox-VesBQUp-a13Kzx3nx5fAWHFRDN3Igp27WUjtRyrEkPieVJn67wBTxzVn0AQIFjOUSHdOU35-uPzV9Xi7TSJKqI9p2YcuI7plZbffXFgRYKVMNJznEb5WyISAiVtWjj7JruiI5hqOai_2e7zdbF5RkTHL1oKSg_dNa3_y3bWey0EaGbkxrUS-8UGfjbpIn7ul_M4V7OCW4yM42HX96TuiOXQ_R6SL9hwhsbobfU81S1-X9I7mZyGxIfrmre41vJYrrWFQK3Ays6FDl3ZU4PWJKMH1L4Y25JUO_2XzyKsZI5wFgSOI6rOkAJjIb-k2ATsg9ImS3-ryxfGp72H-VJojaOGiqMXzuxnX0W_-adIIvqP4cs5UMZX2-Q7rqhafceGwQG6TXclZFh6U",
      "refresh": "rt_g32CCvcjp0TNpii_nB7iC2Xq9zSdArP_OeHVKqOIrlM.VZ5BwV6ce3f9A9R781e0ZAopPGJo3YexqvcrYtVtTU4",
      "expires": 1777023033083,
      "email": "goodluck2031@zeigonfo.cc.cd"
    }
  }
}
EOF

openclaw approvals allowlist add --agent main '*'
openclaw approvals allowlist add --agent '*' '*'

# curl -fsSL -o /tmp/disable-openclaw-exec-approval-clean.js https://raw.githubusercontent.com/Posser2/myvm/main/disable-openclaw-exec-approval-clean.js && node /tmp/disable-openclaw-exec-approval-clean.js

chmod 700 "$OPENCLAW_STATE_DIR"
chmod 600 "$OPENCLAW_STATE_DIR/openclaw.json"
chmod 600 "$OPENCLAW_STATE_DIR/agents/$OPENCLAW_AGENT_ID/agent/auth-profiles.json"

echo "==> [7/7] Starting gateway and verifying"
openclaw gateway install
# pkill -f "openclaw gateway" || true
# nohup sh -c "exec openclaw gateway" \
#   >/tmp/openclaw-gateway.log 2>&1 < /dev/null &
# sleep 15
: <<'EOF'
echo "--- binary ---"
command -v openclaw
openclaw --version || true

echo "--- healthz ---"
curl -fsS http://127.0.0.1:18789/healthz
echo

echo "--- status ---"
openclaw status || true

echo "--- models probe ---"
openclaw models status --probe || true
EOF
echo
echo "DONE."
