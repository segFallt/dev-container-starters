# Configuration
PROFILE=""

# Check if profile exists, if not configure it
if ! aws configure list-profiles | grep -q "^$PROFILE$"; then
    echo "Configuring SSO for profile '$PROFILE'..."
    aws configure sso --profile "$PROFILE"
fi

# Check credentials validity and login if needed
if ! aws sts get-caller-identity --profile "$PROFILE" > /dev/null 2>&1; then
    echo "Logging into AWS SSO for profile '$PROFILE'..."
    aws sso login --profile "$PROFILE"
fi

export AWS_PROFILE=$PROFILE
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1