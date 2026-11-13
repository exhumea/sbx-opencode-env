#!/bin/bash
# Usage: [PORT=<custom-port>] [HOST=<custom-hostname>] $0

set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

get_free_port() {
  python3 -c '
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
'
}

PORT=${PORT:-$(get_free_port)}
HOST=${HOST:-$(hostname -f)}

# Remote config
remote=$(git remote get-url --push "${REMOTE_NAME:-origin}" || true)

if [[ "$remote" =~ ^(ssh://)?git@github.com: ]]; then
  # GitHub config
  if [ -z "${GH_AGENT+x}" ]; then
    echo "GH_AGENT undefined whereas $PWD remote is '$remote'" >&2
    exit 1
  fi
  # <!> no need of 'user:email' scope on token
  gh_token=$(gh auth token -u "$GH_AGENT")
  gh_user_info=$(GH_TOKEN="$gh_token" gh api user --jq '{id, login, name, email}')
  gh_user=$(jq -r .login <<<"$gh_user_info")
  git_name=$(jq -r '.name // .login' <<<"$gh_user_info")
  git_email=$(jq -r '.email // "\(.id)+\(.login)@users.noreply.github.com"' <<<"$gh_user_info")

  # Restricted SSH agent forwarding
  needed_keys_full=$(GH_TOKEN="$gh_token" "$SCRIPT_DIR"/get_ssh_keys.sh github)
  user="$gh_user@github.com"

elif [[ "$remote" =~ ^(ssh://)?git@([^:]+): ]]; then
  # Gitlab config
  glab_host=${BASH_REMATCH[2]}

  glab_user_info=$(GITLAB_HOST="$glab_host" glab api user | jq '{username, name, commit_email}')
  glab_user=$(jq -r .username <<<"$glab_user_info")
  git_name=$(jq -r '.name // .username' <<<"$glab_user_info")
  git_email=$(jq -r .commit_email <<<"$glab_user_info")

  glab_ssh_server_key=$(glab config get --host "$glab_host" ssh_server_key) # custom field
  glab_ssh_host=$(glab config get --host "$glab_host" ssh_host)
  glab_container_registry_domains=$(glab config get --host "$glab_host" container_registry_domains)

  # Restricted SSH agent forwarding
  needed_keys_full=$(GITLAB_HOST="$glab_host" "$SCRIPT_DIR"/get_ssh_keys.sh gitlab)
  user="$glab_user@$glab_host"

else
  echo "unsupported remote '$remote' for $PWD" >&2
  exit 1
fi

git_signing_key=$(cat <<<"$needed_keys_full" | grep -F signing+ | cut -d' ' -f-2)
if [ -z "$git_signing_key" ]; then
  echo "<!> no matching signing key found for $user" >&2
fi

mapfile -t needed_keys <<<"$(echo "$needed_keys_full" | awk '{print $2}')"
args=()
for key in "${needed_keys[@]}"; do args+=(-k "$key"); done

# no way to control output socket, so we have to change working directory
ssh_dir="/tmp/sbx-oc-${PORT}-ssh"
rm -rf "$ssh_dir" && mkdir "$ssh_dir" && pushd "$ssh_dir" >/dev/null
ssh_auth_sock=$(ssh-agent-filter "${args[@]}" | sed -nE "s/^SSH_AUTH_SOCK='([^']+)';.+/\1/p")
popd >/dev/null

echo SSH_AUTH_SOCK="$ssh_auth_sock"

# Unfortunately SSH_AUTH_SOCK is needed everywhere (even for re-pairing)
SSH_AUTH_SOCK="$ssh_auth_sock" sbx env run --force \
  --env-arg ghUser="${gh_user:-}" \
  --env-arg glabHost="${glab_host:-}" \
  --env-arg glabHostKey="${glab_ssh_server_key:-}" \
  --env-arg glabSshHost="${glab_ssh_host:-}" \
  --env-arg glabContainerRegistryDomains="${glab_container_registry_domains:-}" \
  --env-arg gitName="$git_name" \
  --env-arg gitEmail="$git_email" \
  --env-arg gitSshSigningKey="$git_signing_key" \
  --env-arg hostPort="$PORT" \
  --env-arg opencodeApiKey="${OPENCODE_API_KEY:-}" \
  --env-arg cloudflareAccountId="${CLOUDFLARE_ACCOUNT_ID:-}" \
  --name "oc-$PORT" --detach &&
  SSH_AUTH_SOCK="$ssh_auth_sock" sbx exec -it "oc-$PORT" /bin/bash -c "opencode pair --url 'http://$HOST:$PORT'"
