#!/bin/bash

# Clear dist and prepare for deployment
rm -rf dist
mkdir -p dist dist/Admin dist/Student dist/css

# Confirm files before deployment
echo "Building Elm applications..."
elm make src/Admin.elm --output=Admin/admin.js --optimize
elm make src/Student.elm --output=Student/student.js --optimize

# Verify compiled files
if [[ ! -f Admin/admin.js ]]; then
  echo "ERROR: Admin/admin.js not created"
  exit 1
fi

if [[ ! -f Student/student.js ]]; then
  echo "ERROR: Student/student.js not created"
  exit 1
fi

# Verify size of files
ADMIN_SIZE=$(stat -c%s "Admin/admin.js" 2>/dev/null || stat -f%z "Admin/admin.js")
STUDENT_SIZE=$(stat -c%s "Student/student.js" 2>/dev/null || stat -f%z "Student/student.js")

echo "Admin/admin.js size: $ADMIN_SIZE bytes"
echo "Student/student.js size: $STUDENT_SIZE bytes"

if [ "$ADMIN_SIZE" -lt 10000 ] || [ "$STUDENT_SIZE" -lt 10000 ]; then
  echo "WARNING: Compiled Elm files seem too small, they might not contain the full Elm code"
fi

# Copy all necessary files to dist
echo "Copying files to dist..."
cp -v Admin/admin.html dist/Admin/
cp -v Admin/admin.js dist/Admin/
cp -v Admin/firebase-admin.js dist/Admin/
cp -v Student/student.html dist/Student/
cp -v Student/student.js dist/Student/
cp -v Student/student-firebase.js dist/Student/
cp -v css/tailwind.css dist/css/
cp -v favicon.ico dist/

# Create firebase.json with specific routing
cat > dist/firebase.json << 'EOF'
{
  "hosting": {
    "public": ".",
    "ignore": [
      "firebase.json",
      ".firebaserc",
      "**/.*",
      "**/node_modules/**",
      "elm-stuff/**",
      "src/**",
      "dist/**"
    ],
    "rewrites": [
      {
        "source": "/Admin",
        "destination": "/Admin/admin.html"
      },
      {
        "source": "/Student",
        "destination": "/Student/student.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      }
    ]
  }
}
EOF

# Copy .firebaserc if it exists
if [ -f .firebaserc ]; then
  cp .firebaserc dist/
else
  echo "WARNING: .firebaserc not found"
fi

# Compare files to ensure they're distinct
echo "Verifying files are distinct..."
if cmp -s "dist/Admin/admin.js" "dist/Student/student.js"; then
  echo "ERROR: admin.js and student.js are identical!"
  exit 1
else
  echo "✅ admin.js and student.js are different files (expected)"
fi

if cmp -s "dist/Admin/admin.html" "dist/Student/student.html"; then
  echo "ERROR: admin.html and student.html are identical!"
  exit 1
else
  echo "✅ admin.html and student.html are different files (expected)"
fi

# Final verification before deploying
echo "Files in dist/Admin:"
ls -la dist/Admin/

echo "Files in dist/Student:"
ls -la dist/Student/

echo "Ready to deploy? (y/n)"
read answer
if [[ "$answer" != "y" ]]; then
  echo "Deployment canceled"
  exit 0
fi

# Deploy to Firebase
cd dist
firebase deploy
