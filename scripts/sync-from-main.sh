#!/usr/bin/env sh


set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Unity Game Submissions - Sync from Main Branch${NC}"
echo "=============================================="

# Check if we're in a deployment branch
CONFIG_FILE=".deployment-config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Not in a deployment branch${NC}"
    echo "This script should be run from a deployment branch that has $CONFIG_FILE"
    exit 1
fi

# Get current branch info
CURRENT_BRANCH=$(git branch --show-current)
PROJECT_NAME=$(jq -r '.projectName' $CONFIG_FILE)
ORG_NAME=$(jq -r '.organizationName' $CONFIG_FILE)

echo -e "${YELLOW}Current branch: $CURRENT_BRANCH${NC}"
echo -e "${YELLOW}Organization: $ORG_NAME${NC}"
echo -e "${YELLOW}Project: $PROJECT_NAME${NC}"
echo ""

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    git status --short
    echo ""
    read -p "Continue with sync? This may cause conflicts. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting sync. Please commit or stash your changes first."
        exit 1
    fi
fi

# Fetch latest from origin
echo -e "${BLUE}Fetching latest changes from origin...${NC}"
git fetch origin

# Check if main branch exists locally
if ! git show-ref --verify --quiet refs/heads/main; then
    echo -e "${YELLOW}Main branch not found locally, creating from origin/main${NC}"
    git branch main origin/main
fi

# Get commit info
MAIN_COMMIT=$(git rev-parse origin/main)
CURRENT_COMMIT=$(git rev-parse HEAD)
MERGE_BASE=$(git merge-base HEAD origin/main)

if [[ "$CURRENT_COMMIT" == "$MAIN_COMMIT" ]]; then
    echo -e "${GREEN}✅ Already up to date with main branch${NC}"
    exit 0
fi

echo -e "${YELLOW}Preparing to sync changes from main branch${NC}"
echo "Main branch commit: ${MAIN_COMMIT:0:8}"
echo "Current branch commit: ${CURRENT_COMMIT:0:8}"
echo "Common ancestor: ${MERGE_BASE:0:8}"
echo ""

# Show what will be merged
echo -e "${BLUE}Changes that will be merged from main:${NC}"
git log --oneline $MERGE_BASE..origin/main | head -10
echo ""

# Prompt for confirmation
read -p "Proceed with merge? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Sync cancelled."
    exit 0
fi

# Backup current deployment config
echo -e "${BLUE}Backing up deployment configuration...${NC}"
cp $CONFIG_FILE "${CONFIG_FILE}.backup"
if [[ -f "branding/css/custom.css" ]]; then
    cp branding/css/custom.css branding/css/custom.css.backup
fi

# Perform the merge
echo -e "${BLUE}Merging changes from main branch...${NC}"
if git merge origin/main --no-edit; then
    echo -e "${GREEN}✅ Merge completed successfully${NC}"

    # Restore deployment config if it was overwritten
    if [[ -f "${CONFIG_FILE}.backup" ]]; then
        if ! cmp -s "$CONFIG_FILE" "${CONFIG_FILE}.backup"; then
            echo -e "${YELLOW}Restoring deployment configuration...${NC}"
            mv "${CONFIG_FILE}.backup" "$CONFIG_FILE"
        else
            rm "${CONFIG_FILE}.backup"
        fi
    fi

    # Restore custom CSS if it was overwritten
    if [[ -f "branding/css/custom.css.backup" ]]; then
        if [[ ! -f "branding/css/custom.css" ]] || ! cmp -s "branding/css/custom.css" "branding/css/custom.css.backup"; then
            echo -e "${YELLOW}Restoring custom CSS...${NC}"
            mv "branding/css/custom.css.backup" "branding/css/custom.css"
        else
            rm "branding/css/custom.css.backup"
        fi
    fi

    echo ""
    echo -e "${GREEN}🎉 Sync completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Test your application: nix run .#dev-admin or nix run .#dev-student"
    echo "2. Verify customizations are preserved"
    echo "3. Deploy when ready: nix run .#deploy-branch"

else
    echo -e "${RED}❌ Merge conflicts detected${NC}"
    echo ""
    echo -e "${YELLOW}Conflicted files:${NC}"
    git status --short | grep "^UU\|^AA\|^DD"
    echo ""
    echo -e "${BLUE}To resolve conflicts:${NC}"
    echo "1. Edit the conflicted files to resolve conflicts"
    echo "2. Use 'git add <file>' to mark conflicts as resolved"
    echo "3. Run 'git commit' to complete the merge"
    echo "4. Test and deploy when ready"
    echo ""
    echo -e "${YELLOW}If you need to abort the merge:${NC}"
    echo "git merge --abort"

    # Restore backups if merge failed
    if [[ -f "${CONFIG_FILE}.backup" ]]; then
        mv "${CONFIG_FILE}.backup" "$CONFIG_FILE"
    fi
    if [[ -f "branding/css/custom.css.backup" ]]; then
        mv "branding/css/custom.css.backup" "branding/css/custom.css"
