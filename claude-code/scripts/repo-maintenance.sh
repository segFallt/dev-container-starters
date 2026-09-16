#!/usr/bin/env bash
set -euo pipefail

REPOS=(
    "/workspace"
    # map additional repo paths here
)

# Repos never touched by clean (untracked-file removal)
CLEAN_EXCLUDE=(
    # "/workspace"
)

# Extra local branches cleanup must never delete (the default branch is always kept)
PROTECTED_BRANCHES=(
    # "dev"
    # "staging"
)

log() { echo "$*"; }
warn() { echo "  [warn] $*" >&2; }

# Succeed if the needle exactly matches an entry in the haystack
in_array() {
    local needle="$1"; shift
    local item
    for item in "$@"; do
        if [[ "$needle" == "$item" ]]; then
            return 0
        fi
    done
    return 1
}

# Succeed if the path exactly matches an excluded repo
is_excluded() {
    in_array "$1" "${CLEAN_EXCLUDE[@]}"
}

# Succeed if the branch is the default branch or an explicitly protected branch
is_protected() {
    local branch="$1"
    [[ "$branch" == "$DEFAULT_BRANCH" ]] && return 0
    in_array "$branch" "${PROTECTED_BRANCHES[@]}"
}

# Register each repo as a git safe.directory (idempotent, global scope)
ensure_trusted() {
    local repo
    for repo in "${REPOS[@]}"; do
        git config --get-all safe.directory 2>/dev/null | grep -qxF "$repo" \
            || git config --global --add safe.directory "$repo" \
            || warn "could not register safe.directory: $repo"
    done
}

# Run an action against every repo, logging a header and skipping missing paths
for_each_repo() {
    local action="$1" tag="$2"; shift 2
    local repo
    for repo in "${REPOS[@]}"; do
        log "[$tag] $repo"
        [[ -d "$repo" ]] || { warn "skip: path not found: $repo"; continue; }
        "$action" "$repo" "$@" || true
    done
}

# Fetch and reset a repo to the remote default branch
sync_one() {
    local repo="$1"
    local force="${2:-0}"
    git -C "$repo" fetch "$REMOTE" || { warn "fetch failed — skipping $repo"; return; }
    if [[ -n "$(git -C "$repo" status --porcelain)" ]]; then
        if [[ "$force" != "1" ]]; then
            log "  [skip] dirty working tree — pass -f to force reset and discard local changes"
            return
        fi
        warn "discarding local changes (forced)"
        # Forced switch discards conflicting tracked changes
        git -C "$repo" checkout -f "$DEFAULT_BRANCH" || { warn "checkout failed — skipping $repo"; return; }
    else
        git -C "$repo" checkout "$DEFAULT_BRANCH" || { warn "checkout failed — skipping $repo"; return; }
    fi
    git -C "$repo" reset --hard "$REMOTE/$DEFAULT_BRANCH" || { warn "reset failed — skipping $repo"; return; }
}

# Remove all non-primary worktrees from a repo
worktrees_one() {
    local repo="$1"
    local primary
    local wt_path
    primary=$(git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2; exit}')
    while IFS= read -r wt_path; do
        if [[ "$wt_path" != "$primary" ]]; then
            log "  removing worktree: $wt_path"
            git -C "$repo" worktree remove --force "$wt_path" \
                || warn "could not remove worktree: $wt_path"
        fi
    done < <(git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2}')
    git -C "$repo" worktree prune || { warn "worktree prune failed — skipping $repo"; return; }
}

# Switch a repo to the default branch and delete every other unprotected local branch
branches_one() {
    local repo="$1"
    local branch
    git -C "$repo" checkout "$DEFAULT_BRANCH" \
        || { warn "could not switch to $DEFAULT_BRANCH (uncommitted changes?); leaving current branch in place"; return; }
    while IFS= read -r branch; do
        if [[ -n "$branch" ]] && ! is_protected "$branch"; then
            log "  deleting branch: $branch"
            git -C "$repo" branch -D "$branch" || warn "could not delete branch: $branch"
        fi
    done < <(git -C "$repo" branch --list --format="%(refname:short)")
}

# Preview or remove untracked files in a repo
clean_one() {
    local repo="$1"
    local force="${2:-0}"
    local include_ignored="${3:-0}"
    if is_excluded "$repo"; then
        log "  [skip] excluded from clean"
        return
    fi

    # Build git clean flags: preview unless forced, ignored files only with -x
    local flags=("-d")
    if [[ "$force" == "1" ]]; then
        flags+=("-f")
    else
        flags+=("-n")
    fi
    if [[ "$include_ignored" == "1" ]]; then
        flags+=("-x")
    fi
    git -C "$repo" clean "${flags[@]}" || { warn "clean failed for $repo — continuing"; return; }
}

usage() {
    echo "Usage: $0 <sync [-f]|cleanup|clean [-f] [-x]|all [-f] [-x]>"
    echo ""
    echo "  sync [-f]         Fetch $REMOTE and reset every repo to $REMOTE/$DEFAULT_BRANCH"
    echo "                    Skips dirty repos by default; -f forces reset and discards local changes"
    echo "  cleanup           Remove non-primary worktrees, switch each repo to the default branch,"
    echo "                    and delete other local branches (keeps DEFAULT_BRANCH + PROTECTED_BRANCHES)"
    echo "  clean [-f] [-x]   Preview untracked files by default; -f deletes them,"
    echo "                    -x also removes ignored files; skips CLEAN_EXCLUDE repos"
    echo "  all [-f] [-x]     Run sync then cleanup then clean"
    exit 1
}

subcommand="${1:-}"
if [[ -z "$subcommand" ]]; then
    usage
fi
if [[ $# -gt 0 ]]; then
    shift
fi

# Parse flags in any order
FORCE=0
INCLUDE_IGNORED=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f) FORCE=1 ;;
        -x) INCLUDE_IGNORED=1 ;;
        *) usage ;;
    esac
    shift
done

ensure_trusted

case "$subcommand" in
    sync)
        if [[ "$INCLUDE_IGNORED" == "1" ]]; then usage; fi
        for_each_repo sync_one "sync" "$FORCE"
        ;;
    cleanup)
        if [[ "$FORCE" == "1" || "$INCLUDE_IGNORED" == "1" ]]; then usage; fi
        for_each_repo worktrees_one "worktrees"
        for_each_repo branches_one "branches"
        ;;
    clean)
        for_each_repo clean_one "clean" "$FORCE" "$INCLUDE_IGNORED"
        ;;
    all)
        for_each_repo sync_one "sync" "$FORCE"
        for_each_repo worktrees_one "worktrees"
        for_each_repo branches_one "branches"
        for_each_repo clean_one "clean" "$FORCE" "$INCLUDE_IGNORED"
        ;;
    *)
        usage
        ;;
esac