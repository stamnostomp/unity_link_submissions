#!/usr/bin/env sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Unity Game Submissions - Create Deployment Branch${NC}"
echo "=================================================="

# Ensure we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo -e "${YELLOW}Warning: You're not on the main branch (currently on: $CURRENT_BRANCH)${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get deployment details
read -p "Deployment branch name (e.g., school-district-a, university-b): " BRANCH_NAME
read -p "Organization/Client name: " ORG_NAME
read -p "Firebase Project ID: " FIREBASE_PROJECT_ID
read -p "Project display name: " PROJECT_NAME
read -p "Admin contact email: " ADMIN_EMAIL
read -p "Primary brand color (hex, e.g., #1f2937): " BRAND_COLOR
read -p "Firebase API Key: " FIREBASE_API_KEY
read -p "Firebase Messaging Sender ID: " FIREBASE_MESSAGING_SENDER_ID
read -p "Firebase App ID: " FIREBASE_APP_ID

# Validate required inputs
if [[ -z "$BRANCH_NAME" || -z "$ORG_NAME" || -z "$FIREBASE_PROJECT_ID" || -z "$PROJECT_NAME" ]]; then
    echo -e "${RED}Error: Branch name, organization name, Firebase Project ID, and project name are required${NC}"
    exit 1
fi

# Check if branch already exists
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    echo -e "${RED}Error: Branch '$BRANCH_NAME' already exists${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating deployment branch: $BRANCH_NAME${NC}"

# Create and switch to new branch
git checkout -b $BRANCH_NAME

# Create deployment configuration
cat >.deployment-config.json <<EOF
{
  "branchName": "$BRANCH_NAME",
  "organizationName": "$ORG_NAME",
  "projectName": "$PROJECT_NAME",
  "firebaseProjectId": "$FIREBASE_PROJECT_ID",
  "adminEmail": "$ADMIN_EMAIL",
  "brandColor": "$BRAND_COLOR",
  "createdDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "version": "1.0.0",
  "features": {
    "customBranding": true,
    "pointSystem": true,
    "adminManagement": true,
    "beltSystem": true
  },
  "customizations": []
}
EOF

# Clean up multi-environment structure (since each branch is single environment)
rm -rf environments/
rm -rf templates/

# Create single environment configuration
mkdir -p environment/config

# Create .firebaserc
cat >.firebaserc <<EOF
{
  "projects": {
    "default": "$FIREBASE_PROJECT_ID"
  }
}
EOF

# Create firebase.json (same as template but simpler)
cat >firebase.json <<EOF
{
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      ".firebaserc",
      "**/.*",
      "**/node_modules/**",
      "**/elm-stuff/**",
      "**/src/**",
      "dist/**",
      "flake.nix",
      "flake.lock",
      "tailwind.config.js",
      "elm.json",
      "package.json",
      "postcss.config.js",
      "scripts/**",
      "branding/**",
      "docs/**"
    ],
    "rewrites": [
      {
        "source": "/admin",
        "destination": "/admin/admin.html"
      },
      {
        "source": "/student",
        "destination": "/student/student.html"
      },
      {
        "source": "/handle-reset",
        "destination": "/resetPassword/handle-reset.html"
      },
      {
        "source": "!**/*.{js,css,png,jpg,jpeg,gif,ico,svg,woff,woff2,ttf,eot}",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.js",
        "headers": [
          {
            "key": "Content-Type",
            "value": "application/javascript; charset=utf-8"
          }
        ]
      },
      {
        "source": "**/*.css",
        "headers": [
          {
            "key": "Content-Type",
            "value": "text/css; charset=utf-8"
          }
        ]
      }
    ]
  }
}
EOF

# Create Firebase configuration
DEPLOYMENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION=$(date +"%Y.%m.%d")

cat >environment/config/firebase-config.js <<EOF
// Firebase configuration for $PROJECT_NAME
// Branch: $BRANCH_NAME
// Generated: $DEPLOYMENT_DATE

const firebaseConfig = {
  apiKey: "$FIREBASE_API_KEY",
  authDomain: "$FIREBASE_PROJECT_ID.firebaseapp.com",
  databaseURL: "https://$FIREBASE_PROJECT_ID-default-rtdb.firebaseio.com/",
  projectId: "$FIREBASE_PROJECT_ID",
  storageBucket: "$FIREBASE_PROJECT_ID.appspot.com",
  messagingSenderId: "$FIREBASE_MESSAGING_SENDER_ID",
  appId: "$FIREBASE_APP_ID"
};

// Application configuration
const appConfig = {
  projectName: "$PROJECT_NAME",
  organizationName: "$ORG_NAME",
  environment: "$BRANCH_NAME",
  version: "$VERSION",
  deploymentDate: "$DEPLOYMENT_DATE",
  brandColor: "$BRAND_COLOR",
  adminEmail: "$ADMIN_EMAIL"
};

// Export for both environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { firebaseConfig, appConfig };
} else {
  window.firebaseConfig = firebaseConfig;
  window.appConfig = appConfig;
}
EOF

# Create branding directory with customization examples
mkdir -p branding/{css,images,docs}

# Create custom CSS overrides
cat >branding/css/custom.css <<EOF
/* Custom CSS for $ORG_NAME */
/* This file is included after Tailwind CSS for customizations */

:root {
  --brand-primary: $BRAND_COLOR;
  --brand-primary-light: ${BRAND_COLOR}20;
  --brand-primary-dark: ${BRAND_COLOR}cc;
}

/* Custom brand colors */
.bg-brand-primary { background-color: var(--brand-primary); }
.text-brand-primary { color: var(--brand-primary); }
.border-brand-primary { border-color: var(--brand-primary); }

/* Custom header styling for $ORG_NAME */
.custom-header {
  background: linear-gradient(135deg, var(--brand-primary) 0%, var(--brand-primary-dark) 100%);
}

/* Organization-specific customizations go here */
EOF

# Create index.html with organization branding
cat >public/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PROJECT_NAME</title>
    <link href="/css/tailwind.css" rel="stylesheet">
    <link href="/branding/css/custom.css" rel="stylesheet">
    <style>
        .brand-gradient {
            background: linear-gradient(135deg, $BRAND_COLOR 0%, ${BRAND_COLOR}cc 100%);
        }
    </style>
</head>
<body class="bg-gray-100">
    <div class="min-h-screen flex flex-col">
        <header class="brand-gradient text-white p-6">
            <div class="max-w-4xl mx-auto">
                <h1 class="text-3xl font-bold">$PROJECT_NAME</h1>
                <p class="text-lg opacity-90">$ORG_NAME</p>
            </div>
        </header>

        <main class="flex-grow flex items-center justify-center p-6">
            <div class="max-w-2xl mx-auto text-center">
                <div class="bg-white rounded-lg shadow-lg p-8">
                    <h2 class="text-2xl font-semibold text-gray-800 mb-6">Welcome to Unity Game Submissions</h2>

                    <div class="grid md:grid-cols-2 gap-6">
                        <a href="/student" class="block bg-blue-50 hover:bg-blue-100 border-2 border-blue-200 rounded-lg p-6 transition-colors">
                            <div class="text-4xl mb-3">🎓</div>
                            <h3 class="text-xl font-semibold text-blue-800">Student Portal</h3>
                            <p class="text-blue-600 mt-2">Submit your Unity game projects</p>
                        </a>

                        <a href="/admin" class="block bg-purple-50 hover:bg-purple-100 border-2 border-purple-200 rounded-lg p-6 transition-colors">
                            <div class="text-4xl mb-3">👨‍💼</div>
                            <h3 class="text-xl font-semibold text-purple-800">Admin Panel</h3>
                            <p class="text-purple-600 mt-2">Review and grade submissions</p>
                        </a>
                    </div>

                    <div class="mt-8 pt-6 border-t border-gray-200">
                        <p class="text-sm text-gray-500">
                            Need help? Contact <a href="mailto:$ADMIN_EMAIL" class="text-brand-primary hover:underline">$ADMIN_EMAIL</a>
                        </p>
                    </div>
                </div>
            </div>
        </main>

        <footer class="bg-gray-800 text-white text-center p-4">
            <p>&copy; $(date +%Y) $ORG_NAME. All rights reserved.</p>
        </footer>
    </div>
</body>
</html>
EOF

# Create branch-specific documentation
cat >docs/README.md <<EOF
# $PROJECT_NAME
## $ORG_NAME Deployment

### Branch Information
- **Branch**: $BRANCH_NAME
- **Organization**: $ORG_NAME
- **Firebase Project**: $FIREBASE_PROJECT_ID
- **Created**: $DEPLOYMENT_DATE
- **Admin Contact**: $ADMIN_EMAIL

### Quick Start

\`\`\`bash
# Switch to this branch
git checkout $BRANCH_NAME

# Build and deploy
nix run .#deploy-branch

# Development
nix run .#dev-admin    # Admin interface
nix run .#dev-student  # Student interface
\`\`\`

### URLs
- **Live Site**: https://$FIREBASE_PROJECT_ID.web.app
- **Admin Panel**: https://$FIREBASE_PROJECT_ID.web.app/admin
- **Student Portal**: https://$FIREBASE_PROJECT_ID.web.app/student
- **Firebase Console**: https://console.firebase.google.com/project/$FIREBASE_PROJECT_ID

### Customizations
This branch includes the following customizations for $ORG_NAME:

- Custom branding with color: $BRAND_COLOR
- Organization-specific landing page
- Custom CSS overrides in \`branding/css/custom.css\`

### Making Changes
1. Make your changes to source files
2. Test locally with \`nix run .#dev-admin\` or \`nix run .#dev-student\`
3. Build and deploy with \`nix run .#deploy-branch\`

### Syncing with Main Branch
To get updates from the main branch:

\`\`\`bash
# Switch to main and pull latest
git checkout main
git pull origin main

# Switch back to your branch and merge
git checkout $BRANCH_NAME
git merge main

# Resolve any conflicts and test
# Then deploy
nix run .#deploy-branch
\`\`\`

### File Structure
\`\`\`
$BRANCH_NAME/
├── .deployment-config.json    # Branch configuration
├── .firebaserc               # Firebase project config
├── firebase.json             # Firebase hosting config
├── src/                      # Source code (customizable)
├── public/                   # Built files (customizable)
├── environment/              # Environment config
├── branding/                 # Custom branding
│   ├── css/custom.css       # Custom styles
│   └── images/              # Custom images
└── docs/                    # Documentation
\`\`\`
EOF

# Create branch-specific deployment script
cat >scripts/deploy-branch.sh <<EOF
#!/bin/bash
# Deploy this specific branch
set -e

CONFIG_FILE=".deployment-config.json"
if [[ ! -f "\$CONFIG_FILE" ]]; then
    echo "Error: Not in a deployment branch (missing \$CONFIG_FILE)"
    exit 1
fi

PROJECT_ID=\$(jq -r '.firebaseProjectId' \$CONFIG_FILE)
PROJECT_NAME=\$(jq -r '.projectName' \$CONFIG_FILE)
BRANCH_NAME=\$(jq -r '.branchName' \$CONFIG_FILE)

echo "Deploying \$PROJECT_NAME (\$BRANCH_NAME) to \$PROJECT_ID"
echo "=================================================="

# Build applications
echo "Building Elm applications..."
nix run .#build-elm

echo "Building CSS..."
nix run .#build-css

# Copy environment config
echo "Copying Firebase configuration..."
mkdir -p public/js/firebase/config
cp environment/config/firebase-config.js public/js/firebase/config/

# Copy custom CSS if it exists
if [[ -f "branding/css/custom.css" ]]; then
    echo "Including custom CSS..."
    cat branding/css/custom.css >> public/css/tailwind.css
fi

# Deploy to Firebase
echo "Deploying to Firebase..."
firebase deploy --project \$PROJECT_ID

echo ""
echo "✅ Deployment successful!"
echo "🌐 Live Site: https://\$PROJECT_ID.web.app"
echo "👨‍💼 Admin Panel: https://\$PROJECT_ID.web.app/admin"
echo "🎓 Student Portal: https://\$PROJECT_ID.web.app/student"
EOF

chmod +x scripts/deploy-branch.sh

# Update .gitignore for branch-specific files
cat >>.gitignore <<EOF

# Branch-specific build files
/public/js/firebase/config/firebase-config.js
/dist/
EOF

# Create customization guide
cat >branding/CUSTOMIZATION.md <<EOF
# Customization Guide for $ORG_NAME

## Overview
This branch is customized for $ORG_NAME. You can modify the application to fit your organization's needs.

## Customization Options

### 1. Branding & Colors
- Edit \`branding/css/custom.css\` to change colors, fonts, and styling
- Replace images in \`branding/images/\`
- Update the brand color in \`.deployment-config.json\`

### 2. Landing Page
- Modify \`public/index.html\` for custom landing page
- Add organization logo and information

### 3. Application Features
You can modify the source code in \`src/\` to:
- Add custom fields to forms
- Modify the grading system
- Add organization-specific features
- Change terminology (e.g., "belts" to "levels")

### 4. Configuration
- Update \`.deployment-config.json\` for metadata
- Modify Firebase rules if needed
- Adjust hosting configuration in \`firebase.json\`

## Common Customizations

### Change Application Title
Edit \`src/elm/Admin/Main.elm\` and \`src/elm/Student.elm\` to change page titles.

### Add Custom Fields
Modify the types in \`src/elm/Shared/Types.elm\` and update forms accordingly.

### Custom Styling
Add CSS rules to \`branding/css/custom.css\`:

\`\`\`css
/* Example: Change button colors */
.btn-primary {
  background-color: $BRAND_COLOR;
}

/* Example: Custom header */
.custom-nav {
  background: linear-gradient(45deg, $BRAND_COLOR, #ffffff);
}
\`\`\`

### Testing Changes
Always test your changes locally before deploying:

\`\`\`bash
# Test admin interface
nix run .#dev-admin

# Test student interface
nix run .#dev-student
\`\`\`

### Deploying Changes
After making changes:

\`\`\`bash
nix run .#deploy-branch
\`\`\`
EOF

# Commit the new branch setup
git add .
git commit -m "Initial setup for $BRANCH_NAME deployment

- Organization: $ORG_NAME
- Firebase Project: $FIREBASE_PROJECT_ID
- Brand Color: $BRAND_COLOR
- Custom branding and configuration
- Branch-specific deployment scripts"

echo ""
echo -e "${GREEN}✅ Deployment branch '$BRANCH_NAME' created successfully!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Customize your deployment in branding/ and src/ directories"
echo "2. Test locally: nix run .#dev-admin or nix run .#dev-student"
echo "3. Deploy: nix run .#deploy-branch"
echo ""
echo -e "${YELLOW}Branch details:${NC}"
echo "- Branch: $BRANCH_NAME"
echo "- Organization: $ORG_NAME"
echo "- Firebase Project: $FIREBASE_PROJECT_ID"
echo "- Live URL: https://$FIREBASE_PROJECT_ID.web.app"
echo ""
echo -e "${BLUE}Files created:${NC}"
echo "- .deployment-config.json (branch metadata)"
echo "- .firebaserc & firebase.json (Firebase config)"
echo "- environment/config/firebase-config.js (app config)"
echo "- branding/ (customization files)"
echo "- docs/ (documentation)"
echo "- scripts/deploy-branch.sh (deployment script)"
EOF
