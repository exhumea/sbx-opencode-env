#!/bin/bash
# Usage: [PORT=<existing-sandbox-port>] [HOST=<custom-hostname>] $0

set -euo pipefail

PORT=${PORT:-$1}
HOST=${HOST:-$(hostname -f)}

ssh_auth_sock=$(find "/tmp/sbx-oc-$PORT-ssh/" -name 'agent.*' -type s)
SSH_AUTH_SOCK="$ssh_auth_sock" exec sbx exec -it "oc-$PORT" /bin/bash -c "opencode pair --url 'http://$HOST:$PORT'"
