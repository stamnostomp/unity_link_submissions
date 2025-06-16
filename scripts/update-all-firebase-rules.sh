#!/usr/bin/env sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Update Firebase Rules - All Deployment Branches${NC}"
echo "=================================================="

# Save current branch
ORIGINAL_BRANCH=$(git branch --show-current)
echo -e "${YELLOW}Current branch: $ORIGINAL_BRANCH${NC}"

# Find all deployment branches
DEPLOYMENT_BRANCHES=()
echo ""
echo -e "${BLUE}Finding deployment branches...${NC}"

for branch in $(git branch | sed 's/^[* ]*//'); do
    if [[ "$branch" != "main" ]] && git show $branch:.deployment-config.json >/dev/null 2>&1; then
        PROJECT_NAME=$(git show $branch:.deployment-config.json | jq -r '.projectName' 2>/dev/null || echo "Unknown")
        PROJECT_ID=$(git show $branch:.deployment-config.json | jq -r '.firebaseProjectId' 2>/dev/null || echo "Unknown")
        DEPLOYMENT_BRANCHES+=("$branch")
        echo "📍 $branch -> $PROJECT_NAME ($PROJECT_ID)"
    fi
done

if [[ ${#DEPLOYMENT_BRANCHES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No deployment branches found.${NC}"
    echo "Create deployment branches with: nix run .#create-branch"
    exit 0
fi

echo ""
echo -e "${YELLOW}Found ${#DEPLOYMENT_BRANCHES[@]} deployment branches${NC}"
echo ""

# Prompt for confirmation
read -p "Update Firebase rules for all deployment branches? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 0
fi

# Update each deployment branch
SUCCESSFUL_UPDATES=()
FAILED_UPDATES=()

for branch in "${DEPLOYMENT_BRANCHES[@]}"; do
    echo ""
    echo -e "${BLUE}Updating rules for branch: $branch${NC}"
    echo "----------------------------------------"

    # Switch to the branch
    if git checkout "$branch" 2>/dev/null; then
        # Get project info
        PROJECT_NAME=$(jq -r '.projectName' .deployment-config.json)
        PROJECT_ID=$(jq -r '.firebaseProjectId' .deployment-config.json)

        echo -e "${YELLOW}Project: $PROJECT_NAME${NC}"
        echo -e "${YELLOW}Firebase Project ID: $PROJECT_ID${NC}"

        # Create rules file
        RULES_FILE="database-rules-temp.json"

        cat > "$RULES_FILE" << 'EOF'
{
  "rules": {
    "belts": {
      ".read": "auth != null",
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()"
    },
    "students": {
      ".read": "auth != null && root.child('admins').child(auth.uid).exists()",
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()",
      "$studentId": {
        ".read": "auth != null && (root.child('admins').child(auth.uid).exists() || auth.uid == $studentId || $studentId == auth.token.email.replace('.', '_').replace('@', '_'))"
      }
    },
    "submissions": {
      ".read": "auth != null && root.child('admins').child(auth.uid).exists()",
      "$submissionId": {
        ".read": "auth != null && (root.child('admins').child(auth.uid).exists() || data.child('studentId').val() == auth.token.email.replace('.', '_').replace('@', '_') || data.child('studentId').val() == auth.uid)",
        ".write": "auth != null && (root.child('admins').child(auth.uid).exists() || (!data.exists() && newData.child('studentId').val() == auth.token.email.replace('.', '_').replace('@', '_')) || (!data.exists() && newData.child('studentId').val() == auth.uid))",
        ".validate": "newData.hasChildren(['studentId', 'beltLevel', 'gameName', 'githubLink', 'submissionDate'])",
        "grade": {
          ".write": "auth != null && root.child('admins').child(auth.uid).exists()"
        }
      }
    },
    "studentPoints": {
      ".read": "auth != null && root.child('admins').child(auth.uid).exists()",
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()",
      "$studentId": {
        ".read": "auth != null && (root.child('admins').child(auth.uid).exists() || $studentId == auth.token.email.replace('.', '_').replace('@', '_') || $studentId == auth.uid)"
      }
    },
    "pointTransactions": {
      ".read": "auth != null && root.child('admins').child(auth.uid).exists()",
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()",
      "$transactionId": {
        ".read": "auth != null && (root.child('admins').child(auth.uid).exists() || data.child('studentId').val() == auth.token.email.replace('.', '_').replace('@', '_') || data.child('studentId').val() == auth.uid)"
      }
    },
    "pointRedemptions": {
      ".read": "auth != null && root.child('admins').child(auth.uid).exists()",
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()",
      "$redemptionId": {
        ".read": "auth != null && (root.child('admins').child(auth.uid).exists() || data.child('studentId').val() == auth.token.email.replace('.', '_').replace('@', '_') || data.child('studentId').val() == auth.uid)",
        ".write": "auth != null && (root.child('admins').child(auth.uid).exists() || (!data.exists() && newData.child('studentId').val() == auth.token.email.replace('.', '_').replace('@', '_')) || (!data.exists() && newData.child('studentId').val() == auth.uid))",
        ".validate": "newData.hasChildren(['studentId', 'studentName', 'rewardId', 'rewardName', 'pointsRedeemed', 'redemptionDate'])"
      }
    },
    "pointRewards": {
      ".read": "auth != null",
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()"
    },
    "admins": {
      ".read": "auth != null && root.child('admins').child(auth.uid).exists()",
      ".write": "auth != null && root.child('admins').child(auth.uid).exists()",
      "$adminId": {
        ".validate": "newData.hasChildren(['email', 'displayName', 'role'])"
      }
    },
    ".read": false,
    ".write": false
  }
}
EOF

        # Deploy rules
        echo "Deploying rules to $PROJECT_ID..."
        if firebase database:update /rules "$RULES_FILE" --project "$PROJECT_ID" 2>/dev/null; then
            echo -e "${GREEN}✅ Rules updated successfully for $branch${NC}"
            SUCCESSFUL_UPDATES+=("$branch ($PROJECT_NAME)")
        else
            echo -e "${RED}❌ Failed to update rules for $branch${NC}"
            FAILED_UPDATES+=("$branch ($PROJECT_NAME)")
        fi

        # Clean up
        rm "$RULES_FILE"
    else
        echo -e "${RED}❌ Failed to switch to branch $branch${NC}"
        FAILED_UPDATES+=("$branch (checkout failed)")
    fi
done

# Switch back to original branch
git checkout "$ORIGINAL_BRANCH" 2>/dev/null

# Summary
echo ""
echo "========================================"
echo -e "${BLUE}Firebase Rules Update Summary${NC}"
echo "========================================"

if [[ ${#SUCCESSFUL_UPDATES[@]} -gt 0 ]]; then
    echo -e "${GREEN}✅ Successfully updated (${#SUCCESSFUL_UPDATES[@]} projects):${NC}"
    for update in "${SUCCESSFUL_UPDATES[@]}"; do
        echo "   $update"
    done
fi

if [[ ${#FAILED_UPDATES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}❌ Failed updates (${#FAILED_UPDATES[@]} projects):${NC}"
    for failure in "${FAILED_UPDATES[@]}"; do
        echo "   $failure"
    done
fi

echo ""
echo -e "${BLUE}Key improvements in updated rules:${NC}"
echo "🔒 Enhanced security with granular access control"
echo "👥 Students can only access their own data"
echo "🎯 Point system now works for students"
echo "📝 Students can create submissions and redemptions"
echo "🛡️ Grades protected from student modification"

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test each deployment to ensure functionality works"
echo "2. Verify student portal can access points and rewards"
echo "3. Confirm admin panel still has full access"

echo ""
echo -e "${GREEN}Update completed!${NC}"
