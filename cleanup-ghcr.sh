#!/bin/bash
set -e

REGISTRY="ghcr.io/lucchmielowski"
IMAGE_NAME="kyverno-cosign-testbed"
PACKAGE_NAME="kyverno-cosign-testbed"  # Package name in GHCR

echo "=== GHCR Image Cleanup ==="
echo ""
echo "This will DELETE ALL versions of:"
echo "  📦 $REGISTRY/$IMAGE_NAME"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Please install it first:"
    echo ""
    echo "  macOS: brew install gh"
    echo "  Linux: https://github.com/cli/cli#installation"
    echo ""
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo ""
    echo "Run: gh auth login"
    echo ""
    exit 1
fi

echo "✅ GitHub CLI authenticated"
echo ""

# Confirmation prompt
read -p "⚠️  Type 'DELETE' to confirm deletion: " CONFIRM
echo ""

if [ "$CONFIRM" != "DELETE" ]; then
    echo "❌ Cleanup cancelled."
    exit 0
fi

echo "🗑️  Fetching image versions..."

# Get all versions using GitHub API
VERSIONS=$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/user/packages/container/$PACKAGE_NAME/versions" \
    --jq '.[].id' 2>/dev/null || echo "")

if [ -z "$VERSIONS" ]; then
    echo "✅ No versions found. Nothing to delete."
    echo ""
    echo "💡 If you expect images to exist, they might be under your organization."
    echo "   To delete org packages, use:"
    echo "   gh api --method DELETE /orgs/YOUR_ORG/packages/container/$PACKAGE_NAME/versions/VERSION_ID"
    exit 0
fi

VERSION_COUNT=$(echo "$VERSIONS" | wc -l | tr -d ' ')
echo "Found $VERSION_COUNT version(s) to delete"
echo ""

# Delete each version
DELETED=0
FAILED=0

for VERSION_ID in $VERSIONS; do
    echo -n "Deleting version ID $VERSION_ID... "
    
    if gh api \
        --method DELETE \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/user/packages/container/$PACKAGE_NAME/versions/$VERSION_ID" &> /dev/null; then
        echo "✅"
        ((DELETED++))
    else
        echo "❌"
        ((FAILED++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Deleted: $DELETED"
if [ $FAILED -gt 0 ]; then
    echo "  ❌ Failed:  $FAILED"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ Cleanup complete!"
else
    echo "⚠️  Cleanup completed with errors."
    echo "   Some versions may still exist."
fi
