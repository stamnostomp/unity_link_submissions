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
              mkdir -p $out/Admin $out/Student $out/css $out/resetPassword/js

              # Check required files
              if [ ! -f "./Admin/admin.html" ]; then
                echo "Error: Admin/admin.html not found"
                exit 1
              fi

              if [ ! -f "./Student/student.html" ]; then
                echo "Error: Student/student.html not found"
                exit 1
              fi

              if [ ! -f "./index.html" ]; then
                echo "Error: index.html not found"
                exit 1
              fi

              # Check for compiled Elm files
              if [ ! -f "./Admin/admin.js" ]; then
                echo "Error: Admin/admin.js not found. Please run 'nix run .#build-elm' first"
                exit 1
              fi

              if [ ! -f "./Student/student.js" ]; then
                echo "Error: Student/student.js not found. Please run 'nix run .#build-elm' first"
                exit 1
              fi

              # Copy HTML files
              cp ./Admin/admin.html $out/Admin/
              cp ./Student/student.html $out/Student/
              cp ./index.html $out/

              # Copy Firebase integration files
              if [ -f "./Admin/firebase-admin.js" ]; then
                cp ./Admin/firebase-admin.js $out/Admin/
              else
                echo "Error: Admin/firebase-admin.js not found"
                exit 1
              fi

              if [ -f "./Student/student-firebase.js" ]; then
                cp ./Student/student-firebase.js $out/Student/
              else
                echo "Error: Student/student-firebase.js not found"
                exit 1
              fi

              # Copy the pre-compiled Elm JS files
              cp ./Admin/admin.js $out/Admin/
              cp ./Student/student.js $out/Student/
              echo "Copied pre-compiled Elm JS files"

              # Copy resetPassword files - create js subdirectory and handle rename
              if [ -d "./resetPassword" ]; then
                # Create directory first to ensure it exists
                mkdir -p $out/resetPassword/js

                # Look for handle-reset.html
                if [ -f "./resetPassword/handle-reset.html" ]; then
                  # Modify it to use the new JS path
                  cat "./resetPassword/handle-reset.html" | sed 's|src="handle-reset.js"|src="js/reset-handler.js"|g' > "$out/resetPassword/handle-reset.html"
                  echo "Copied and modified HTML file: handle-reset.html (updated script path)"
                else
                  echo "Error: resetPassword/handle-reset.html not found"
                  exit 1
                fi

                # Look for handle-reset.js
                if [ -f "./resetPassword/handle-reset.js" ]; then
                  # Copy and rename to avoid Firebase routing conflicts
                  cp "./resetPassword/handle-reset.js" $out/resetPassword/js/reset-handler.js
                  chmod 644 $out/resetPassword/js/reset-handler.js
                  echo "Copied JS file as: resetPassword/js/reset-handler.js"
                else
                  echo "Error: resetPassword/handle-reset.js not found"
                  exit 1
                fi

                # Copy any CSS files if they exist
                for file in ./resetPassword/*.css; do
                  if [ -f "$file" ]; then
                    cp "$file" $out/resetPassword/
                    echo "Copied CSS file: $file"
                  fi
                done

                echo "Copied resetPassword directory files"
              else
                echo "Error: resetPassword directory not found"
                exit 1
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
                echo "Error: src/css/tailwind.css not found"
                exit 1
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
              # Copy firebase.json - fail if it doesn't exist
              if [ -f "./firebase.json" ]; then
                cp ./firebase.json $out/
              else
                echo "Error: firebase.json not found"
                exit 1
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

              # Check for Elm source files
              if [ ! -f "src/Admin.elm" ]; then
                echo "Error: src/Admin.elm not found"
                exit 1
              fi

              if [ ! -f "src/Student.elm" ]; then
                echo "Error: src/Student.elm not found"
                exit 1
              fi

              # Compile Elm directly to Admin and Student directories
              ${pkgs.elmPackages.elm}/bin/elm make src/Admin.elm --output=Admin/admin.js --optimize
              ${pkgs.elmPackages.elm}/bin/elm make src/Student.elm --output=Student/student.js --optimize

              echo "Elm build complete!"
            '';
          };

          deploy = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "deploy" ''
              # Check for .firebaserc or create it
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
              # Build Elm apps before packaging with Nix
              nix run .#build-elm

              echo "Packaging with Nix..."
              # Now build with Nix (which will use the pre-compiled JS files)
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
              mkdir -p dist/Admin dist/Student dist/css dist/resetPassword/js

              # Copy build artifacts
              echo "Copying build artifacts..."
              cp -r ${self.packages.${system}.default}/* dist/

              # Copy Firebase config files
              echo "Copying Firebase configuration files..."
              cp ./firebase.json dist/ || (echo "Error: firebase.json not found" && exit 1)
              cp ./.firebaserc dist/ || echo "{\"projects\":{\"default\":\"$PROJECT_ID\"}}" > dist/.firebaserc

              # Display content for debugging
              echo "Content of dist directory:"
              ls -la dist/
              echo "Content of dist/Admin directory:"
              ls -la dist/Admin/
              echo "Content of dist/Student directory:"
              ls -la dist/Student/
              echo "Content of dist/resetPassword directory:"
              ls -la dist/resetPassword/
              echo "Content of dist/resetPassword/js directory:"
              ls -la dist/resetPassword/js/

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
                --minify || echo "Error: Tailwind CSS build failed, src/css/tailwind.css may be missing"

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
