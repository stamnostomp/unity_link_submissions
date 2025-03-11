#!/usr/bin/env bash
set -e

# Build Elm applications
echo "Building Elm applications..."
elm make src/Admin.elm --output=Admin/admin.js --optimize
elm make src/Student.elm --output=Student/student.js --optimize

# Build CSS with Tailwind
echo "Building CSS..."
npx tailwindcss -i src/css/tailwind.css -o Admin/style.css --minify
cp Admin/style.css Student/style.css

# Echo success message
echo "Build complete! Files are ready for deployment."
