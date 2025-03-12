#!/bin/bash

# Check if both HTML files exist and are different
echo "Checking HTML files..."

if [ ! -f "Admin/admin.html" ]; then
  echo "❌ Admin/admin.html is missing"
  exit 1
else
  echo "✅ Admin/admin.html exists"
fi

if [ ! -f "Student/student.html" ]; then
  echo "❌ Student/student.html is missing"
  exit 1
else
  echo "✅ Student/student.html exists"
fi

# Check if files are identical
if cmp -s "Admin/admin.html" "Student/student.html"; then
  echo "⚠️ WARNING: admin.html and student.html are identical!"

  # Create backup of original files
  cp Admin/admin.html Admin/admin.html.bak
  cp Student/student.html Student/student.html.bak

  # Get HTML content that needs to be unique
  echo "Creating distinct HTML files..."

  # For admin.html
  cat > Admin/admin.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Unity Game Submissions Admin</title>
  <link rel="icon" href="/favicon.ico">
  <link href="/css/tailwind.css" rel="stylesheet">
</head>
<body>
  <div id="elm-admin-app"></div>
  <script>
    // Just to verify which page this is - can be removed later
    console.log("This is the ADMIN page");
  </script>

  <!-- Compiled Elm application -->
  <script src="./admin.js"></script>

  <!-- Import Firebase integration -->
  <script type="module">
    import { initializeFirebase } from './firebase-admin.js';

    document.addEventListener('DOMContentLoaded', function() {
      // Check if Elm is defined
      if (typeof Elm === 'undefined') {
        console.error("Error: Elm is not defined. The Elm application JS file might not be loading correctly.");
        document.getElementById('elm-admin-app').innerHTML =
          '<div style="color: red; padding: 20px;">' +
          '<h2>Error: Application could not load</h2>' +
          '<p>The Elm application could not be loaded. This might be due to a deployment issue.</p>' +
          '<p>Error: Elm is not defined</p>' +
          '</div>';
        return;
      }

      // Initialize the Elm application
      try {
        const elmApp = Elm.Admin.init({
          node: document.getElementById('elm-admin-app')
        });

        // Initialize Firebase with the Elm app
        initializeFirebase(elmApp);
      } catch (e) {
        console.error("Error initializing Elm application:", e);
        document.getElementById('elm-admin-app').innerHTML =
          '<div style="color: red; padding: 20px;">' +
          '<h2>Error: Application initialization failed</h2>' +
          '<p>Error details: ' + e.message + '</p>' +
          '</div>';
      }
    });
  </script>
</body>
</html>
EOF

  # For student.html
  cat > Student/student.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Unity Game Student Records</title>
  <link rel="icon" href="/favicon.ico">
  <link href="/css/tailwind.css" rel="stylesheet">
</head>
<body>
  <div id="elm-app"></div>
  <script>
    // Just to verify which page this is - can be removed later
    console.log("This is the STUDENT page");
  </script>

  <!-- Compiled Elm application -->
  <script src="./student.js"></script>

  <!-- Import Firebase integration -->
  <script type="module">
    import { initializeFirebase } from './student-firebase.js';

    document.addEventListener('DOMContentLoaded', function() {
      // Check if Elm is defined
      if (typeof Elm === 'undefined') {
        console.error("Error: Elm is not defined. The Elm application JS file might not be loading correctly.");
        document.getElementById('elm-app').innerHTML =
          '<div style="color: red; padding: 20px;">' +
          '<h2>Error: Application could not load</h2>' +
          '<p>The Elm application could not be loaded. This might be due to a deployment issue.</p>' +
          '<p>Error: Elm is not defined</p>' +
          '</div>';
        return;
      }

      // Initialize the Elm application
      try {
        const elmApp = Elm.Student.init({
          node: document.getElementById('elm-app')
        });

        // Initialize Firebase with the Elm app
        initializeFirebase(elmApp);
      } catch (e) {
        console.error("Error initializing Elm application:", e);
        document.getElementById('elm-app').innerHTML =
          '<div style="color: red; padding: 20px;">' +
          '<h2>Error: Application initialization failed</h2>' +
          '<p>Error details: ' + e.message + '</p>' +
          '</div>';
      }
    });
  </script>
</body>
</html>
EOF

  echo "✅ Created distinct HTML files with relative paths (./admin.js and ./student.js)"
  echo "Original files backed up as Admin/admin.html.bak and Student/student.html.bak"
else
  echo "✅ admin.html and student.html are already different files"
fi

# Check script paths
echo "Checking script paths..."
ADMIN_SCRIPT_PATH=$(grep -o 'src="[^"]*admin\.js[^"]*"' Admin/admin.html | head -1 | cut -d'"' -f2)
STUDENT_SCRIPT_PATH=$(grep -o 'src="[^"]*student\.js[^"]*"' Student/student.html | head -1 | cut -d'"' -f2)

echo "Admin script path: $ADMIN_SCRIPT_PATH"
echo "Student script path: $STUDENT_SCRIPT_PATH"

if [[ "$ADMIN_SCRIPT_PATH" == "/Admin/admin.js" ]]; then
  echo "⚠️ Admin script uses absolute path, switching to relative path..."
  sed -i.bak 's|src="/Admin/admin.js"|src="./admin.js"|g' Admin/admin.html
  echo "✅ Updated admin.html to use relative path"
fi

if [[ "$STUDENT_SCRIPT_PATH" == "/Student/student.js" ]]; then
  echo "⚠️ Student script uses absolute path, switching to relative path..."
  sed -i.bak 's|src="/Student/student.js"|src="./student.js"|g' Student/student.html
  echo "✅ Updated student.html to use relative path"
fi

# Check Firebase import paths
ADMIN_FIREBASE_PATH=$(grep -o 'import { initializeFirebase } from.*' Admin/admin.html | head -1)
STUDENT_FIREBASE_PATH=$(grep -o 'import { initializeFirebase } from.*' Student/student.html | head -1)

echo "Admin Firebase import: $ADMIN_FIREBASE_PATH"
echo "Student Firebase import: $STUDENT_FIREBASE_PATH"

if [[ "$ADMIN_FIREBASE_PATH" == *"'/Admin/firebase-admin.js'"* ]]; then
  echo "⚠️ Admin Firebase import uses absolute path, switching to relative path..."
  sed -i.bak "s|import { initializeFirebase } from '/Admin/firebase-admin.js'|import { initializeFirebase } from './firebase-admin.js'|g" Admin/admin.html
  echo "✅ Updated admin.html Firebase import to use relative path"
fi

if [[ "$STUDENT_FIREBASE_PATH" == *"'/Student/student-firebase.js'"* ]]; then
  echo "⚠️ Student Firebase import uses absolute path, switching to relative path..."
  sed -i.bak "s|import { initializeFirebase } from '/Student/student-firebase.js'|import { initializeFirebase } from './student-firebase.js'|g" Student/student.html
  echo "✅ Updated student.html Firebase import to use relative path"
fi

echo "HTML paths check complete!"
