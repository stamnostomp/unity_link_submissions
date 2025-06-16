{
  description = "Unity Game Submissions with Elm and Firebase";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Check for required files and error if missing
        checkRequiredFiles = pkgs.runCommand "check-files" { } ''
          # Check for required Elm source files
          if [ ! -f "${./.}/src/elm/Admin.elm" ]; then
            echo "ERROR: src/elm/Admin.elm not found!"
            exit 1
          fi

          if [ ! -f "${./.}/src/elm/Student.elm" ]; then
            echo "ERROR: src/elm/Student.elm not found!"
            exit 1
          fi

          if [ ! -f "${./.}/src/css/tailwind.css" ]; then
            echo "ERROR: src/css/tailwind.css not found!"
            exit 1
          fi

          # Check for public directory structure
          if [ ! -f "${./.}/public/index.html" ]; then
            echo "ERROR: public/index.html not found!"
            exit 1
          fi

          if [ ! -f "${./.}/public/admin/admin.html" ]; then
            echo "ERROR: public/admin/admin.html not found!"
            exit 1
          fi

          if [ ! -f "${./.}/public/student/student.html" ]; then
            echo "ERROR: public/student/student.html not found!"
            exit 1
          fi

          # Check for Firebase integration files
          if [ ! -f "${./.}/public/js/firebase/admin.js" ]; then
            echo "ERROR: public/js/firebase/admin.js not found!"
            echo "This file is required for Firebase integration."
            exit 1
          fi

          if [ ! -f "${./.}/public/js/firebase/student.js" ]; then
            echo "ERROR: public/js/firebase/student.js not found!"
            echo "This file is required for Firebase integration."
            exit 1
          fi

          # Check for Firebase config
          if [ ! -f "${./.}/public/js/firebase/config/firebase-config.js" ]; then
            echo "ERROR: public/js/firebase/config/firebase-config.js not found!"
            exit 1
          fi

          # Check for firebase.json
          if [ ! -f "${./.}/firebase.json" ]; then
            echo "ERROR: firebase.json not found!"
            exit 1
          fi

          touch $out
        '';
      in
      {
        packages = {
          # Build Tailwind CSS
          tailwind = pkgs.stdenv.mkDerivation {
            name = "tailwind-css";
            src = ./.;
            nativeBuildInputs = [ pkgs.nodePackages.tailwindcss ];

            buildPhase = ''
              mkdir -p css-output
              tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./css-output/tailwind.css \
                --minify
            '';

            installPhase = ''
              mkdir -p $out/css
              cp ./css-output/tailwind.css $out/css/tailwind.css
            '';
          };

          # Simple build that just copies files and uses pre-compiled assets
          default = pkgs.stdenv.mkDerivation {
            name = "unity-game-submissions";
            src = ./.;

            buildInputs = [ checkRequiredFiles ];

            installPhase = ''
              # Copy entire public directory structure
              cp -r ./public $out/

              # Copy compiled CSS
              mkdir -p $out/css
              cp ${self.packages.${system}.tailwind}/css/tailwind.css $out/css/

              # Copy the existing firebase.json (don't generate a new one)
              cp ./firebase.json $out/firebase.json

              # Copy .firebaserc if it exists
              if [ -f ./.firebaserc ]; then
                cp ./.firebaserc $out/.firebaserc
              fi

              # Note: Elm files should be pre-compiled to public/ before running nix build
              if [ ! -f "$out/admin/admin.js" ]; then
                echo "WARNING: admin.js not found in public/admin/"
                echo "Run 'build_elm' or 'build_all' first"
              fi

              if [ ! -f "$out/student/student.js" ]; then
                echo "WARNING: student.js not found in public/student/"
                echo "Run 'build_elm' or 'build_all' first"
              fi
            '';
          };
        };

        apps = {
          # Build Elm applications to public directory
          build-elm = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "build-elm" ''
              set -e
              echo "Building Elm applications to public directory..."

              # Ensure public directories exist
              mkdir -p public/admin public/student

              # Compile Elm applications directly to public directory
              echo "Compiling Admin application..."
              ${pkgs.elmPackages.elm}/bin/elm make src/elm/Admin.elm --output=public/admin/admin.js --optimize

              echo "Compiling Student application..."
              ${pkgs.elmPackages.elm}/bin/elm make src/elm/Student.elm --output=public/student/student.js --optimize

              echo "Elm applications compiled successfully!"
              echo "✓ public/admin/admin.js"
              echo "✓ public/student/student.js"
            '';
          };

          # Build CSS to public directory
          build-css = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "build-css" ''
              echo "Building Tailwind CSS to public directory..."
              mkdir -p public/css
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --minify
              echo "✓ public/css/tailwind.css"
            '';
          };

          # NEW: Development server for Admin interface
          dev-admin = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "dev-admin" ''
              echo "Starting development server for Admin interface..."
              echo "Building CSS first..."
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --minify

              echo "Starting elm-live for Admin..."
              echo "Open http://localhost:8000/admin/admin.html in your browser"
              ${pkgs.elmPackages.elm-live}/bin/elm-live src/elm/Admin.elm \
                --port=8000 \
                --dir=public \
                --start-page=admin/admin.html \
                -- --output=public/admin/admin.js
            '';
          };

          # NEW: Development server for Student interface
          dev-student = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "dev-student" ''
              echo "Starting development server for Student interface..."
              echo "Building CSS first..."
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --minify

              echo "Starting elm-live for Student..."
              echo "Open http://localhost:8000/student/student.html in your browser"
              ${pkgs.elmPackages.elm-live}/bin/elm-live src/elm/Student.elm \
                --port=8000 \
                --dir=public \
                --start-page=student/student.html \
                -- --output=public/student/student.js
            '';
          };

          # Simple deploy without Nix build (alternative)
          deploy-simple = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "deploy-simple" ''
              set -e

              # Check for Firebase project configuration
              if [ ! -f .firebaserc ]; then
                echo "ERROR: .firebaserc file not found!"
                exit 1
              fi

              PROJECT_ID=$(${pkgs.jq}/bin/jq -r '.projects.default' .firebaserc)
              echo "Using Firebase project: $PROJECT_ID"

              echo "Building Elm applications..."
              ${self.apps.${system}.build-elm.program}

              echo "Building CSS..."
              ${self.apps.${system}.build-css.program}

              echo "Preparing deployment directory..."
              rm -rf dist
              mkdir -p dist

              # Copy public directory to dist/public (preserving structure)
              cp -r ./public dist/

              # Copy config files to dist root
              cp ./firebase.json dist/
              if [ -f ./.firebaserc ]; then
                cp ./.firebaserc dist/
              fi

              echo "Verifying files..."
              for file in "public/admin/admin.js" "public/student/student.js" "public/css/tailwind.css"; do
                if [ -f "dist/$file" ]; then
                  echo "✓ dist/$file"
                else
                  echo "✗ dist/$file MISSING!"
                  exit 1
                fi
              done

              echo "Deploying to Firebase..."
              cd dist && ${pkgs.firebase-tools}/bin/firebase deploy --project $PROJECT_ID
            '';
          };

          # Deploy to Firebase
          deploy = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "deploy" ''
              set -e

              # Check for Firebase project configuration
              if [ ! -f .firebaserc ]; then
                echo "ERROR: .firebaserc file not found!"
                echo "Create a .firebaserc file with your Firebase project ID:"
                echo '{"projects":{"default":"your-firebase-project-id"}}'
                exit 1
              fi

              # Check for firebase.json
              if [ ! -f firebase.json ]; then
                echo "ERROR: firebase.json file not found!"
                echo "Please ensure firebase.json exists in the project root."
                exit 1
              fi

              PROJECT_ID=$(${pkgs.jq}/bin/jq -r '.projects.default' .firebaserc)
              echo "Using Firebase project: $PROJECT_ID"

              echo "Building Elm applications..."
              ${self.apps.${system}.build-elm.program}

              echo "Building CSS..."
              ${self.apps.${system}.build-css.program}

              echo "Verifying compiled files exist..."
              if [ ! -f "public/admin/admin.js" ]; then
                echo "ERROR: public/admin/admin.js not found after compilation!"
                exit 1
              fi

              if [ ! -f "public/student/student.js" ]; then
                echo "ERROR: public/student/student.js not found after compilation!"
                exit 1
              fi

              echo "✓ All Elm files compiled successfully"

              echo "Building CSS with Nix..."
              nix build .#tailwind

              echo "Preparing deployment directory..."
              # Clean and create dist directory
              rm -rf dist
              mkdir -p dist

              # Copy entire public directory structure (preserving public/ folder)
              cp -r ./public dist/

              # Copy compiled CSS from Nix build to the public directory in dist
              mkdir -p dist/public/css
              cp result/css/tailwind.css dist/public/css/

              # Copy config files to dist root
              cp ./firebase.json dist/
              if [ -f ./.firebaserc ]; then
                cp ./.firebaserc dist/
              fi

              echo "Verifying deployment structure..."
              echo "Checking for required files:"

              if [ -f "dist/public/admin/admin.js" ]; then
                echo "✓ dist/public/admin/admin.js"
                echo "  Size: $(wc -c < dist/public/admin/admin.js) bytes"
              else
                echo "✗ dist/public/admin/admin.js MISSING!"
                exit 1
              fi

              if [ -f "dist/public/student/student.js" ]; then
                echo "✓ dist/public/student/student.js"
                echo "  Size: $(wc -c < dist/public/student/student.js) bytes"
              else
                echo "✗ dist/public/student/student.js MISSING!"
                exit 1
              fi

              if [ -f "dist/public/css/tailwind.css" ]; then
                echo "✓ dist/public/css/tailwind.css"
              else
                echo "✗ dist/public/css/tailwind.css MISSING!"
                exit 1
              fi

              echo ""
              echo "Final deployment structure:"
              echo "├── dist/"
              echo "│   ├── public/                   ← Firebase serves from here"
              echo "│   │   ├── admin/"
              echo "│   │   │   ├── admin.html"
              echo "│   │   │   └── admin.js          ← Compiled Elm"
              echo "│   │   ├── student/"
              echo "│   │   │   ├── student.html"
              echo "│   │   │   └── student.js        ← Compiled Elm"
              echo "│   │   ├── js/firebase/          ← Firebase integration files"
              echo "│   │   ├── css/"
              echo "│   │   │   └── tailwind.css      ← Compiled CSS"
              echo "│   │   └── index.html"
              echo "│   ├── firebase.json             ← Points to public/ directory"
              echo "│   └── .firebaserc"

              echo ""
              echo "Deploying to Firebase..."
              cd dist && ${pkgs.firebase-tools}/bin/firebase deploy --project $PROJECT_ID
            '';
          };

          # Interactive menu
          default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "unity-submissions" ''
              echo "Unity Game Submissions Manager"
              echo "=============================="
              echo "Uses your existing firebase.json config"
              echo ""
              echo "Development:"
              echo "1: Start Admin dev server (elm-live)"
              echo "2: Start Student dev server (elm-live)"
              echo ""
              echo "Building:"
              echo "3: Build Elm applications"
              echo "4: Build CSS"
              echo "5: Build All (Elm + CSS)"
              echo ""
              echo "Deployment:"
              echo "6: Deploy to Firebase (with Nix CSS)"
              echo "7: Deploy to Firebase (simple, no Nix)"
              echo "8: Build All + Deploy (with Nix CSS)"
              echo "9: Build All + Deploy (simple)"
              echo ""
              echo "Utilities:"
              echo "10: Show deployment structure"
              echo "11: Exit"
              echo ""
              echo "Enter your choice (1-11):"
              read choice

              case $choice in
                1)
                  ${self.apps.${system}.dev-admin.program}
                  ;;
                2)
                  ${self.apps.${system}.dev-student.program}
                  ;;
                3)
                  ${self.apps.${system}.build-elm.program}
                  ;;
                4)
                  ${self.apps.${system}.build-css.program}
                  ;;
                5)
                  ${self.apps.${system}.build-elm.program} && ${self.apps.${system}.build-css.program}
                  ;;
                6)
                  ${self.apps.${system}.deploy.program}
                  ;;
                7)
                  ${self.apps.${system}.deploy-simple.program}
                  ;;
                8)
                  ${self.apps.${system}.build-elm.program} && ${self.apps.${system}.build-css.program} && ${
                    self.apps.${system}.deploy.program
                  }
                  ;;
                9)
                  ${self.apps.${system}.build-elm.program} && ${self.apps.${system}.build-css.program} && ${
                    self.apps.${system}.deploy-simple.program
                  }
                  ;;
                10)
                  echo "Current project structure:"
                  if [ -d "public" ]; then
                    echo "public/ directory:"
                    ls -la public/
                    echo ""
                    echo "public/admin/:"
                    ls -la public/admin/ 2>/dev/null || echo "  (empty or missing)"
                    echo ""
                    echo "public/student/:"
                    ls -la public/student/ 2>/dev/null || echo "  (empty or missing)"
                  fi
                  if [ -d "dist" ]; then
                    echo ""
                    echo "dist/ directory (deployment):"
                    tree dist/ 2>/dev/null || ls -la dist/
                  fi
                  ;;
                11)
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
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-test
            pkgs.elmPackages.elm-live # ← Added elm-live here!
            pkgs.nodejs
            pkgs.nodePackages.tailwindcss
            pkgs.firebase-tools
            pkgs.jq
            pkgs.tree
          ];

          shellHook = ''
            echo "Unity Game Submissions Development Environment"
            echo "============================================="
            echo "Uses your existing firebase.json config file"
            echo "Elm compilation happens in shell, not Nix sandbox"
            echo ""

            # Create convenient build functions
            build_elm() {
              echo "Building Elm applications..."
              ${self.apps.${system}.build-elm.program}
            }

            build_css() {
              echo "Building CSS..."
              ${self.apps.${system}.build-css.program}
            }

            build_all() {
              echo "Building everything..."
              build_elm
              build_css
              echo "✅ Build complete!"
            }

            deploy_firebase() {
              ${self.apps.${system}.deploy.program}
            }

            deploy_simple() {
              ${self.apps.${system}.deploy-simple.program}
            }

            # NEW: Development server functions
            dev_admin() {
              echo "Starting Admin development server..."
              ${self.apps.${system}.dev-admin.program}
            }

            dev_student() {
              echo "Starting Student development server..."
              ${self.apps.${system}.dev-student.program}
            }

            # Watch mode for development
            watch_css() {
              echo "Watching CSS changes..."
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --watch
            }

            # Debug function to check structure
            check_structure() {
              echo "Current project structure:"
              if [ -d "public" ]; then
                echo ""
                echo "public/admin/:"
                ls -la public/admin/ 2>/dev/null || echo "  (empty or missing)"
                if [ -f "public/admin/admin.js" ]; then
                  echo "  ✓ admin.js ($(wc -c < public/admin/admin.js) bytes)"
                else
                  echo "  ✗ admin.js missing"
                fi
                echo ""
                echo "public/student/:"
                ls -la public/student/ 2>/dev/null || echo "  (empty or missing)"
                if [ -f "public/student/student.js" ]; then
                  echo "  ✓ student.js ($(wc -c < public/student/student.js) bytes)"
                else
                  echo "  ✗ student.js missing"
                fi
              fi
              if [ -d "dist" ]; then
                echo ""
                echo "dist/ directory (deployment):"
                tree dist/ 2>/dev/null || ls -la dist/
              fi
            }

            echo "Available commands:"
            echo "  build_elm       - Build Elm applications to public/"
            echo "  build_css       - Build CSS to public/"
            echo "  build_all       - Build everything"
            echo "  watch_css       - Watch CSS changes"
            echo "  dev_admin       - Start Admin dev server with elm-live"
            echo "  dev_student     - Start Student dev server with elm-live"
            echo "  deploy_firebase - Deploy to Firebase (includes build_all, uses Nix for CSS)"
            echo "  deploy_simple   - Deploy to Firebase (includes build_all, no Nix)"
            echo "  check_structure - Show current directory structure"
            echo "  nix run         - Interactive menu"
            echo ""
            echo "Development workflow:"
            echo "  1. dev_admin      - Start admin dev server (hot reload)"
            echo "  2. dev_student    - Start student dev server (hot reload)"
            echo ""
            echo "Build workflow:"
            echo "  1. build_all           - Compiles everything to public/"
            echo "  2a. deploy_firebase    - Builds + deploys (recommended)"
            echo "  2b. deploy_simple      - Builds + deploys (if Nix issues)"
            echo ""
            echo "File outputs:"
            echo "  ├── public/admin/admin.js      (Elm compiled)"
            echo "  ├── public/student/student.js  (Elm compiled)"
            echo "  └── public/css/tailwind.css    (CSS compiled)"
            echo ""
            echo "After deployment:"
            echo "  ├── dist/public/admin/admin.js     (Ready for Firebase)"
            echo "  ├── dist/public/student/student.js (Ready for Firebase)"
            echo "  ├── dist/public/css/tailwind.css   (Compiled CSS)"
            echo "  └── dist/firebase.json              (Points to public/ directory)"
            echo ""
            echo "🚀 Quick start: run 'dev_admin' or 'dev_student' for live development!"
            echo ""
          '';
        };
      }
    );
}
