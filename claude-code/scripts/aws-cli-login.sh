# Configuration
AWS_PROFILE=""
AWS_REGION=us-east-1

# Safety buffer in seconds before SSO token expiry to trigger re-login.
# Override by setting AWS_SSO_REFRESH_BUFFER_SECONDS before sourcing this script.
_aws_sso_check() {
    local profile="$1"
    local buffer

    # Validate / default the safety buffer
    if [ -n "${AWS_SSO_REFRESH_BUFFER_SECONDS:-}" ] && \
       printf '%s' "$AWS_SSO_REFRESH_BUFFER_SECONDS" | grep -qE '^[0-9]+$'; then
        buffer="$AWS_SSO_REFRESH_BUFFER_SECONDS"
    else
        buffer=300
    fi

    # ── Step 1: SSO access-token cache check ─────────────────────────────────
    local sso_key sso_cache_file
    sso_key=$(aws configure get sso_session --profile "$profile" 2>/dev/null)
    if [ -z "$sso_key" ]; then
        sso_key=$(aws configure get sso_start_url --profile "$profile" 2>/dev/null)
    fi

    if [ -n "$sso_key" ]; then
        local sso_hash
        if command -v sha1sum >/dev/null 2>&1; then
            sso_hash=$(printf '%s' "$sso_key" | sha1sum | awk '{print $1}')
        else
            sso_hash=$(printf '%s' "$sso_key" | shasum -a 1 | awk '{print $1}')
        fi
        sso_cache_file="${HOME}/.aws/sso/cache/${sso_hash}.json"

        if [ ! -f "$sso_cache_file" ]; then
            echo "SSO cache file not found — logging in..."
            if ! aws sso login --profile "$profile"; then
                echo "WARNING: aws sso login failed; credentials may be invalid" >&2
            fi
            return
        fi

        local expires_epoch
        expires_epoch=$(SSO_CACHE_FILE="$sso_cache_file" python3 -c '
import os, json, datetime, calendar
try:
    with open(os.environ["SSO_CACHE_FILE"]) as f:
        data = json.load(f)
    ts = data.get("expiresAt", "")
    # fromisoformat handles Z, +00:00, and microseconds uniformly (Python 3.7+)
    ts = ts.replace("Z", "+00:00")
    dt = datetime.datetime.fromisoformat(ts)
    print(calendar.timegm(dt.utctimetuple()))
except Exception:
    print("ERROR")
' 2>/dev/null)

        if [ "$expires_epoch" = "ERROR" ] || [ -z "$expires_epoch" ]; then
            echo "SSO cache file unreadable — logging in..."
            if ! aws sso login --profile "$profile"; then
                echo "WARNING: aws sso login failed; credentials may be invalid" >&2
            fi
            return
        fi

        local now_epoch
        now_epoch=$(date -u +%s)
        if [ "$((now_epoch + buffer))" -ge "$expires_epoch" ]; then
            echo "SSO token expired or within safety buffer — logging in..."
            if ! aws sso login --profile "$profile"; then
                echo "WARNING: aws sso login failed; credentials may be invalid" >&2
            fi
            return
        fi
    fi

    # ── Step 2: STS belt-and-braces fallback ─────────────────────────────────
    local sts_stderr sts_exit
    sts_stderr=$(aws sts get-caller-identity --profile "$profile" 2>&1 >/dev/null)
    sts_exit=$?

    if [ "$sts_exit" -ne 0 ] || \
       printf '%s' "$sts_stderr" | grep -qiE 'ExpiredToken|SSOTokenLoadError|expired|InvalidGrant'; then
        echo "STS check failed or token error detected — logging in..."
        if ! aws sso login --profile "$profile"; then
            echo "WARNING: aws sso login failed; credentials may be invalid" >&2
        fi
    fi
}

# Check if profile exists, if not configure it
if ! aws configure list-profiles | grep -q "^$AWS_PROFILE$"; then
    echo "Configuring SSO for profile '$AWS_PROFILE'..."
    aws configure sso --profile "$AWS_PROFILE"
fi

# Run two-step SSO session validation
_aws_sso_check "$AWS_PROFILE"
unset -f _aws_sso_check

export AWS_PROFILE=$AWS_PROFILE
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=$AWS_REGION
