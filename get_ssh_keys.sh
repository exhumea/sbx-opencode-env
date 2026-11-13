#!/bin/sh

# Usage:
# - GH_TOKEN=XXX $0 github
# - GITLAB_HOST=XXX $0 gitlab

set -eu

fail() {
  printf '[keys-config] %s\n' "$*" >&2
  exit 1
}

sock=${SSH_AUTH_SOCK:-}
if [ -z "$sock" ]; then
  fail "SSH_AUTH_SOCK is not set."
fi
if [ ! -S "$sock" ]; then
  fail "the SSH agent socket $sock does not exist."
fi

if agent_keys=$(ssh-add -L 2>&1); then
  rc=0
else
  rc=$?
fi

# ssh-add exit 2 is "could not connect at all"; exit 1 is "connected, but
# the exchange failed or the agent is empty". Forwarding being switched off
# can land in either one depending on how far the connection gets, so only
# the genuinely-empty agent gets a recovery of its own -- every other state
# runs the same host-side checks, the forwarding setting first.
case $rc in
  0) ;;
  1)
    case "$agent_keys" in
      *"no identities"*) ;;
      *) fail "the agent did not answer usably (ssh-add: $agent_keys)." ;;
    esac
    ;;
  *) fail "unexpected error for $sock (ssh-add: $agent_keys, exit $rc)." ;;
esac

get_matching_keys() {
  # Get the unique matching key (type + key data, but not the optional comment)
  # Tolerate no matching key
  matches=$(
    while IFS= read -r a_key; do
      [ -z "$a_key" ] && continue
      read -r a_type a_data _ <<EOF
$a_key
EOF
      while IFS= read -r g_key; do
        [ -z "$g_key" ] && continue
        read -r g_type g_data g_comment <<EOF
$g_key
EOF
        if [ "$a_type" = "$g_type" ] && [ "$a_data" = "$g_data" ]; then
          if [ "$3" = "keep-comment" ]; then
            echo "$g_type $g_data $g_comment"
          else
            echo "$g_type $g_data"
          fi
          break
        fi
      done <<EOF
$1
EOF
    done <<EOF
$agent_keys
EOF
  )

  matches=$(echo "$matches" | sort -u)
  match_count=$(echo "$matches" | grep -c . || true)

  case "$match_count" in
    0) ;; # no match but NOT an error
    1) echo "$matches" ;;
    *) fail "N=$match_count matching keys found in ssh-agent for $2." ;;
  esac
}

case "${1:-}" in
  "gitlab")
    gitlab_user=$(glab auth status -F json --jq '.hosts[0] | "\(.user)@\(.host)"')
    gitlab_keys_jq_expr="map(\"\(.key | [splits(\"\\\s+\") | .][:2] | join(\" \")) \(.usage_type)+$gitlab_user\") | join(\"\n\")"
    gitlab_keys=$(glab ssh-key list -F json --jq "$gitlab_keys_jq_expr")

    get_matching_keys "$gitlab_keys" "authentication and/or signing" "keep-comment"
    ;;

  "github")
    github_user=$(gh api user --jq .login)
    github_auth_keys=$(curl -fsSL "https://github.com/$github_user.keys") ||
      fail "unable to fetch GitHub SSH authentication keys for $github_user."
    github_sign_keys=$(gh api "users/$github_user/ssh_signing_keys" --jq '.[].key' 2>/dev/null) ||
      fail "unable to fetch GitHub SSH signing keys for $github_user."

    matching_auth_key=$(get_matching_keys "$github_auth_keys" "authentication" "no-comment")
    matching_sign_key=$(get_matching_keys "$github_sign_keys" "signing" "no-comment")
    user="$github_user@github.com"

    if [ -n "$matching_auth_key" ]; then
      if [ "$matching_auth_key" = "$matching_sign_key" ]; then
        echo "$matching_auth_key" "auth_and_signing+$user"
        exit 0
      else
        echo "$matching_auth_key" "auth+$user"
      fi
    fi
    if [ -n "$matching_sign_key" ]; then
      echo "$matching_sign_key" "signing+$user"
    fi
    ;;

  *) fail "unknown provider '$1'" ;;
esac
