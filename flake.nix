{
  description = "Unity Game Submissions with Elm and Firebase";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # SVG content for favicon
        faviconSvg = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
            <!-- Background -->
            <rect width="64" height="64" rx="14" fill="#2C2C2C"/>

            <!-- Unity-like triangular logo -->
            <polygon points="32,10 50,45 14,45" fill="#f5f5f5" stroke="#1A1A1A" stroke-width="2"/>

            <!-- Form element suggestion -->
            <rect x="18" y="24" width="28" height="15" rx="3" fill="#4169E1" opacity="0.7"/>

            <!-- Upload arrow -->
            <path d="M32,18 L38,26 H34 V32 H30 V26 H26 Z" fill="#56C173" stroke="#1A1A1A" stroke-width="1"/>

            <!-- Submission text line suggestions -->
            <rect x="22" y="28" width="20" height="2" rx="1" fill="#f5f5f5" opacity="0.8"/>
            <rect x="22" y="32" width="14" height="2" rx="1" fill="#f5f5f5" opacity="0.8"/>
          </svg>
        '';
      in
      {
        packages = {
          # Generate favicon
          favicon = pkgs.runCommand "favicon" {
            buildInputs = [ pkgs.imagemagick ];
          } ''
            # Create SVG file
            mkdir -p $out
            echo '${faviconSvg}' > favicon.svg

            # Convert to ICO
            convert favicon.svg -background none -define icon:auto-resize=64,48,32,16 $out/favicon.ico
          '';

          # Use pre-built Elm JavaScript files
          elm-apps = pkgs.stdenv.mkDerivation {
            name = "elm-applications";
            src = ./.;

            # No build needed - we'll use the pre-built JS files
            dontBuild = true;

            installPhase = ''
              # Create root directory with the correct structure
              mkdir -p $out/Admin $out/Student $out/css

              # Copy HTML files
              if [ -f "./Admin/admin.html" ]; then
                cp ./Admin/admin.html $out/Admin/ || true
                echo "Copied Admin/admin.html"
              else
                # Create admin.html if it doesn't exist
                cat > $out/Admin/admin.html << 'EOF'
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

  <!-- Compiled Elm application -->
  <script src="/Admin/admin.js"></script>

  <!-- Import Firebase integration -->
  <script type="module">
    import { initializeFirebase } from '/Admin/firebase-admin.js';

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
                echo "Created Admin/admin.html"
              fi

              if [ -f "./Student/student.html" ]; then
                cp ./Student/student.html $out/Student/ || true
                echo "Copied Student/student.html"
              else
                # Create student.html if it doesn't exist
                cat > $out/Student/student.html << 'EOF'
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

  <!-- Compiled Elm application -->
  <script src="/Student/student.js"></script>

  <!-- Import Firebase integration -->
  <script type="module">
    import { initializeFirebase } from '/Student/student-firebase.js';

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
                echo "Created Student/student.html"
              fi

              # Copy Firebase integration files
              if [ -f "./Admin/firebase-admin.js" ]; then
                cp ./Admin/firebase-admin.js $out/Admin/ || true
                echo "Copied Admin/firebase-admin.js"
              fi

              if [ -f "./Student/student-firebase.js" ]; then
                cp ./Student/student-firebase.js $out/Student/ || true
                echo "Copied Student/student-firebase.js"
              fi

              # Copy compiled Elm files
              if [ -f "./Admin/admin.js" ]; then
                cp ./Admin/admin.js $out/Admin/ || true
                echo "Found and copied Admin/admin.js"
              else
                echo "Warning: Admin/admin.js not found"
              fi

              if [ -f "./Student/student.js" ]; then
                cp ./Student/student.js $out/Student/ || true
                echo "Found and copied Student/student.js"
              else
                echo "Warning: Student/student.js not found"
              fi

              # Copy favicon to root
              cp ${self.packages.${system}.favicon}/favicon.ico $out/
            '';
          };

          # Build Tailwind CSS
          tailwind = pkgs.stdenv.mkDerivation {
            name = "tailwind-css";
            src = ./.;

            nativeBuildInputs = [ pkgs.nodePackages.tailwindcss ];

            buildPhase = ''
              # Create output directory
              mkdir -p css-output

              # Check if tailwind.css exists
              if [ -f "./src/css/tailwind.css" ]; then
                # Build Tailwind CSS
                tailwindcss \
                  -i ./src/css/tailwind.css \
                  -o ./css-output/tailwind.css \
                  --minify
              else
                # Create a basic CSS file
                echo "/* Basic Tailwind-like CSS */" > ./css-output/tailwind.css
                echo "body { font-family: sans-serif; margin: 0; padding: 0; }" >> ./css-output/tailwind.css
                echo "Warning: Could not find tailwind.css source. Created basic CSS file."
              fi
            '';

            installPhase = ''
              # Create output directories
              mkdir -p $out/css $out/Admin $out/Student

              # Copy CSS to the css directory
              cp ./css-output/tailwind.css $out/css/

              # Also copy to individual app directories for backward compatibility
              cp ./css-output/tailwind.css $out/Admin/style.css
              cp ./css-output/tailwind.css $out/Student/style.css
            '';
          };

          # Combined package
          default = pkgs.symlinkJoin {
            name = "unity-game-submissions";
            paths = [
              self.packages.${system}.elm-apps
              self.packages.${system}.tailwind
            ];

            # Add firebase.json to the output
            postBuild = ''
              # Create firebase.json if it doesn't exist in source
              if [ ! -f "$out/firebase.json" ]; then
                cat > $out/firebase.json << 'EOF'
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
    ]
  }
}
EOF
                echo "Created firebase.json for root directory hosting"
              fi
            '';
          };
        };

        apps = {
          build-elm = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "build-elm" ''
              set -e
              echo "Building Elm applications..."
              # Ensure Admin and Student directories exist
              mkdir -p Admin Student

              # Compile Elm directly to Admin and Student directories
              ${pkgs.elmPackages.elm}/bin/elm make src/Admin.elm --output=Admin/admin.js --optimize
              ${pkgs.elmPackages.elm}/bin/elm make src/Student.elm --output=Student/student.js --optimize

              echo "Elm build complete!"
            '';
          };

deploy = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "deploy" ''
              # Get Firebase project ID
              if [ -f .firebaserc ]; then
                PROJECT_ID=$(${pkgs.jq}/bin/jq -r '.projects.default' .firebaserc)
                echo "Using Firebase project: $PROJECT_ID"
              else
                echo "No .firebaserc file found."
                echo "Please specify your Firebase project ID:"
                read PROJECT_ID

                # Create .firebaserc file
                echo "{\"projects\":{\"default\":\"$PROJECT_ID\"}}" > .firebaserc
                echo "Created .firebaserc with project: $PROJECT_ID"
              fi

              echo "Building Elm applications locally..."
              # Build Elm apps using the build-elm app
              $(nix run .#build-elm)

              echo "Packaging with Nix..."
              # Build the project with Nix
              nix build

              echo "Preparing for deployment..."
              # Handle dist directory with proper permissions
              if [ -d "dist" ]; then
                echo "Removing old dist directory (may require sudo)..."
                if ! rm -rf dist 2>/dev/null; then
                  sudo rm -rf dist
                fi
              fi

              # Create a fresh dist directory with proper permissions
              mkdir -p dist/Admin dist/Student dist/css

              # Copy build artifacts
              echo "Copying build artifacts..."
              cp -r ${self.packages.${system}.default}/* dist/

              # IMPORTANT: Explicitly copy the compiled Elm files that we just built
              echo "Copying compiled Elm files..."
              cp ./Admin/admin.js dist/Admin/ || echo "Warning: Failed to copy Admin/admin.js"
              cp ./Student/student.js dist/Student/ || echo "Warning: Failed to copy Student/student.js"

              # Display content for debugging
              echo "Content of dist directory:"
              ls -la dist/
              echo "Content of dist/Admin directory:"
              ls -la dist/Admin/
              echo "Content of dist/Student directory:"
              ls -la dist/Student/

              # Make sure firebase.json exists
              if [ ! -f "dist/firebase.json" ]; then
                echo "Creating firebase.json..."
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
    ]
  }
}
EOF
              fi

              # Copy Firebase config files
              cp ./.firebaserc dist/ || echo "{\"projects\":{\"default\":\"$PROJECT_ID\"}}" > dist/.firebaserc

              # Ensure correct permissions for deployment
              chmod -R u+w dist

              echo "Deploying to Firebase project: $PROJECT_ID"
              cd dist && ${pkgs.firebase-tools}/bin/firebase deploy --project $PROJECT_ID
            '';
          };

          favicon = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "generate-favicon" ''
              echo "Generating favicon..."
              nix build .#favicon

              # Copy to project root
              cp ${self.packages.${system}.favicon}/favicon.ico ./

              echo "Favicon generated and copied to the project root."
            '';
          };

          default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "unity-submissions" ''
              echo "Unity Game Submissions Manager"
              echo "-----------------------------"
              echo "1: Build Elm applications"
              echo "2: Generate favicon"
              echo "3: Deploy to Firebase"
              echo "4: Build and Deploy"
              echo "5: Exit"
              echo ""
              echo "Enter your choice (1-5):"
              read choice

              case $choice in
                1)
                  nix run .#build-elm
                  ;;
                2)
                  nix run .#favicon
                  ;;
                3)
                  nix run .#deploy
                  ;;
                4)
                  nix run .#build-elm && nix run .#deploy
                  ;;
                5)
                  echo "Exiting..."
                  exit 0
                  ;;
                *)
                  echo "Invalid choice. Exiting."
                  exit 1
                  ;;
              esac
            '';
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            # Development dependencies
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-test
            pkgs.nodejs
            pkgs.nodePackages.tailwindcss
            pkgs.firebase-tools
            pkgs.jq
            pkgs.imagemagick
          ];

          shellHook = ''
            build_all() {
              echo "Building everything..."
              # Build Elm
              nix run .#build-elm

              # Generate favicon
              nix run .#favicon

              # Build CSS
              echo "Building CSS..."
              mkdir -p css
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./css/tailwind.css \
                --minify || echo "Warning: Tailwind CSS build failed, check if src/css/tailwind.css exists"

              # Also copy to individual directories for compatibility
              mkdir -p Admin Student
              cp ./css/tailwind.css ./Admin/style.css || true
              cp ./css/tailwind.css ./Student/style.css || true

              echo "Build complete!"
            }

            deploy_firebase() {
              nix run .#deploy
            }

            echo "Nix development environment loaded!"
            echo "Available commands:"
            echo "  build_all - Build everything for local development"
            echo "  deploy_firebase - Deploy to Firebase"
            echo "  nix run - Show interactive menu"
            echo "  nix run .#build-elm - Build only Elm files"
            echo "  nix run .#favicon - Generate favicon"
            echo "  nix run .#deploy - Deploy to Firebase"
          '';
        };
      }
    );
}
