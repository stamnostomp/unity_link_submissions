#!/usr/bin/env sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Unity Game Submissions - First Admin Setup Guide${NC}"
echo "=================================================="

# Check if we're in a deployment branch
if [[ ! -f ".deployment-config.json" ]]; then
    echo -e "${RED}Error: Not in a deployment branch${NC}"
    echo "Run this from a deployment branch (created with: nix run .#create-branch)"
    exit 1
fi

PROJECT_ID=$(jq -r '.firebaseProjectId' .deployment-config.json)
PROJECT_NAME=$(jq -r '.projectName' .deployment-config.json)
ORG_NAME=$(jq -r '.organizationName' .deployment-config.json)

echo -e "${YELLOW}Project: $PROJECT_NAME${NC}"
echo -e "${YELLOW}Organization: $ORG_NAME${NC}"
echo -e "${YELLOW}Firebase Project: $PROJECT_ID${NC}"
echo ""

echo -e "${BLUE}Follow these steps to create your first admin:${NC}"
echo ""

echo -e "${YELLOW}Step 1: Create Authentication User${NC}"
echo "1. Open: https://console.firebase.google.com/project/$PROJECT_ID/authentication/users"
echo "2. Click 'Add user'"
echo "3. Enter your admin email and password"
echo "4. Click 'Add user'"
echo "5. COPY THE UID that appears (you'll need it for step 2)"
echo ""

read -p "Press Enter when you've created the user and copied the UID..."
echo ""

echo -e "${YELLOW}Step 2: Add User to Admin Database${NC}"
echo "1. Open: https://console.firebase.google.com/project/$PROJECT_ID/database/data"
echo "2. If there's no 'admins' node:"
echo "   - Click the + button at the root"
echo "   - Enter key: admins"
echo "   - Enter value: {}"
echo "   - Click Add"
echo "3. Click the + button next to 'admins'"
echo "4. Enter the UID you copied as the key"
echo "5. Enter this as the value:"
echo ""

# Get admin details for the JSON
read -p "Enter admin email: " ADMIN_EMAIL
read -p "Enter admin display name: " ADMIN_NAME

CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo -e "${GREEN}Copy this JSON (replace the UID with yours):${NC}"
echo ""
cat <<EOF
{
  "email": "$ADMIN_EMAIL",
  "displayName": "$ADMIN_NAME",
  "role": "superuser",
  "createdBy": "manual-setup",
  "createdAt": "$CURRENT_DATE"
}
EOF

echo ""
echo "6. Click 'Add'"
echo ""

read -p "Press Enter when you've added the admin to the database..."
echo ""

echo -e "${YELLOW}Step 3: Test Admin Access${NC}"
echo "1. Open: https://$PROJECT_ID.web.app/admin"
echo "2. Sign in with the email and password you created"
echo "3. You should see the admin dashboard"
echo ""

read -p "Press Enter after testing the admin login..."
echo ""

echo -e "${GREEN}🎉 Admin setup complete!${NC}"
echo ""
echo -e "${BLUE}Your admin panel URLs:${NC}"
echo "🌐 Admin Panel: https://$PROJECT_ID.web.app/admin"
echo "🎓 Student Portal: https://$PROJECT_ID.web.app/student"
echo "🏠 Landing Page: https://$PROJECT_ID.web.app"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo "1. Create belt levels (e.g., White Belt, Yellow Belt)"
echo "2. Set up point rewards if using the point system"
echo "3. Create student accounts"
echo "4. Create additional admin users through the admin panel"
echo ""

echo -e "${YELLOW}Security reminders:${NC}"
echo "• Use a strong password for your admin account"
echo "• This admin has 'superuser' role and can create other admins"
echo "• You can create additional admins through Admin Panel → Admin Users"
echo ""

# Optional: Create a backup admin data file
echo -e "${BLUE}Creating backup admin configuration...${NC}"
cat >"admin-backup-$PROJECT_ID.json" <<EOF
{
  "project": "$PROJECT_NAME",
  "projectId": "$PROJECT_ID",
  "organization": "$ORG_NAME",
  "adminEmail": "$ADMIN_EMAIL",
  "adminName": "$ADMIN_NAME",
  "createdAt": "$CURRENT_DATE",
  "urls": {
    "admin": "https://$PROJECT_ID.web.app/admin",
    "student": "https://$PROJECT_ID.web.app/student",
    "console": "https://console.firebase.google.com/project/$PROJECT_ID"
  }
}
EOF

echo "📄 Saved backup info to: admin-backup-$PROJECT_ID.json"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
