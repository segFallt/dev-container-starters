#!/usr/bin/env bash
set -euo pipefail

REPOS=(
    "/workspace"
    # map additional repo paths here
)

sync_repos() {
    local force="${1:-0}"
    for repo in "${REPOS[@]}"; do
        echo "[sync] $repo"
        [[ -d "$repo" ]] || { echo "  [skip] path not found: $repo"; continue; }
        git -C "$repo" fetch origin
        if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
            if [[ "$force" != "1" ]]; then
                echo "  [skip] dirty working tree — pass -f to force reset and discard local changes"
                continue
            fi
            echo "  [warn] discarding local changes (forced)"
        fi
        git -C "$repo" checkout main
        git -C "$repo" reset --hard origin/main
    done
}

cleanup_repos() {
    for repo in "${REPOS[@]}"; do
        echo "[cleanup] $repo"
        [[ -d "$repo" ]] || { echo "  [skip] path not found: $repo"; continue; }

        # Remove all non-primary worktrees
        primary=$(git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2; exit}')
        while IFS= read -r wt_path; do
            if [[ "$wt_path" != "$primary" ]]; then
                echo "  removing worktree: $wt_path"
                git -C "$repo" worktree remove --force "$wt_path" \
                    || echo "  [warn] could not remove worktree: $wt_path"
            fi
        done < <(git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2}')
        git -C "$repo" worktree prune

        # Delete all local branches other than main
        while IFS= read -r branch; do
            if [[ "$branch" != "main" && -n "$branch" ]]; then
                echo "  deleting branch: $branch"
                git -C "$repo" branch -D "$branch" \
                    || echo "  [warn] could not delete branch: $branch"
            fi
        done < <(git -C "$repo" branch --list --format="%(refname:short)")
    done
}

usage() {
    echo "Usage: $0 <sync [-f]|cleanup|all [-f]>"
    echo ""
    echo "  sync [-f]    Fetch origin and reset every repo to origin/main"
    echo "               Skips dirty repos by default; -f forces reset and discards local changes"
    echo "  cleanup      Remove non-main worktrees and delete non-main local branches"
    echo "  all [-f]     Run sync then cleanup"
    exit 1
}

case "${1:-}" in
    sync)
        FORCE=0; [[ "${2:-}" == "-f" ]] && FORCE=1
        sync_repos "$FORCE"
        ;;
    cleanup)
        cleanup_repos
        ;;
    all)
        FORCE=0; [[ "${2:-}" == "-f" ]] && FORCE=1
        sync_repos "$FORCE"
        cleanup_repos
        ;;
    *)
        usage
        ;;
esac
