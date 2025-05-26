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
          if [ ! -f "${./.}/public/js/firebase/integrations/admin-integration.js" ]; then
            echo "ERROR: public/js/firebase/integrations/admin-integration.js not found!"
            echo "This file is required for Firebase integration."
            exit 1
          fi

          if [ ! -f "${./.}/public/js/firebase/integrations/student-integration.js" ]; then
            echo "ERROR: public/js/firebase/integrations/student-integration.js not found!"
            echo "This file is required for Firebase integration."
            exit 1
          fi

          # Check for Firebase config
          if [ ! -f "${./.}/public/js/firebase/config/firebase-config.js" ]; then
            echo "ERROR: public/js/firebase/config/firebase-config.js not found!"
            exit 1
          fi

          # Check for password reset files
          if [ ! -d "${./.}/public/resetPassword" ]; then
            echo "ERROR: public/resetPassword directory not found!"
            exit 1
          fi

          if [ ! -f "${./.}/public/resetPassword/handle-reset.html" ]; then
            echo "ERROR: public/resetPassword/handle-reset.html not found!"
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

          # Copy public files with CSS
          default = pkgs.stdenv.mkDerivation {
            name = "unity-game-submissions";
            src = ./.;

            buildInputs = [ checkRequiredFiles ];

            installPhase = ''
                            # Copy entire public directory structure
                            cp -r ./public $out/

                            # Copy compiled CSS to public directory
                            mkdir -p $out/css
                            cp ${self.packages.${system}.tailwind}/css/tailwind.css $out/css/

                            # Create firebase.json with correct configuration for public directory
                            cat > $out/firebase.json << 'EOF'
              {
                "hosting": {
                  "public": ".",
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
                    "postcss.config.js"
                  ],
                  "rewrites": [
                    {
                      "source": "/admin",
                      "destination": "/admin/admin.html"
                    },
                    {
                      "source": "/admin/**",
                      "destination": "/admin/admin.html"
                    },
                    {
                      "source": "/student",
                      "destination": "/student/student.html"
                    },
                    {
                      "source": "/student/**",
                      "destination": "/student/student.html"
                    },
                    {
                      "source": "/handle-reset",
                      "destination": "/resetPassword/handle-reset.html"
                    },
                    {
                      "source": "**",
                      "destination": "/index.html"
                    }
                  ],
                  "headers": [
                    {
                      "source": "/js/**/*.js",
                      "headers": [
                        {
                          "key": "Content-Type",
                          "value": "application/javascript; charset=utf-8"
                        }
                      ]
                    },
                    {
                      "source": "/resetPassword/**/*.js",
                      "headers": [
                        {
                          "key": "Content-Type",
                          "value": "application/javascript; charset=utf-8"
                        }
                      ]
                    },
                    {
                      "source": "**/*.js",
                      "headers": [
                        {
                          "key": "Content-Type",
                          "value": "application/javascript"
                        },
                        {
                          "key": "Cache-Control",
                          "value": "no-cache, no-store, must-revalidate"
                        }
                      ]
                    },
                    {
                      "source": "**/*.css",
                      "headers": [
                        {
                          "key": "Content-Type",
                          "value": "text/css"
                        }
                      ]
                    }
                  ]
                }
              }
              EOF
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

              PROJECT_ID=$(${pkgs.jq}/bin/jq -r '.projects.default' .firebaserc)
              echo "Using Firebase project: $PROJECT_ID"

              echo "Building Elm applications..."
              ${self.apps.${system}.build-elm.program}

              echo "Building CSS..."
              ${self.apps.${system}.build-css.program}

              echo "Building project with Nix..."
              nix build

              echo "Preparing deployment directory..."
              # Clean and create dist directory
              rm -rf dist
              mkdir -p dist

              # Copy all built files (this includes the public directory structure)
              cp -r result/* dist/

              # Copy compiled Elm files (should already be in place from build-elm)
              echo "Ensuring compiled Elm applications are in place..."
              cp ./public/admin/admin.js dist/admin/ 2>/dev/null || echo "Admin JS already in place"
              cp ./public/student/student.js dist/student/ 2>/dev/null || echo "Student JS already in place"

              # Copy .firebaserc to dist directory
              cp .firebaserc dist/

              echo "Deployment structure:"
              echo "├── dist/"
              echo "│   ├── admin/"
              echo "│   │   ├── admin.html"
              echo "│   │   └── admin.js"
              echo "│   ├── student/"
              echo "│   │   ├── student.html"
              echo "│   │   └── student.js"
              echo "│   ├── js/firebase/"
              echo "│   ├── css/"
              echo "│   └── index.html"

              echo "Deploying to Firebase..."
              cd dist && ${pkgs.firebase-tools}/bin/firebase deploy --project $PROJECT_ID
            '';
          };

          # Interactive menu
          default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "unity-submissions" ''
              echo "Unity Game Submissions Manager"
              echo "=============================="
              echo "Project Structure: public/ directory"
              echo ""
              echo "1: Build Elm applications"
              echo "2: Build CSS"
              echo "3: Build All (Elm + CSS)"
              echo "4: Deploy to Firebase"
              echo "5: Build All + Deploy"
              echo "6: Exit"
              echo ""
              echo "Enter your choice (1-6):"
              read choice

              case $choice in
                1)
                  ${self.apps.${system}.build-elm.program}
                  ;;
                2)
                  ${self.apps.${system}.build-css.program}
                  ;;
                3)
                  ${self.apps.${system}.build-elm.program} && ${self.apps.${system}.build-css.program}
                  ;;
                4)
                  ${self.apps.${system}.deploy.program}
                  ;;
                5)
                  ${self.apps.${system}.build-elm.program} && ${self.apps.${system}.build-css.program} && ${
                    self.apps.${system}.deploy.program
                  }
                  ;;
                6)
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
            pkgs.nodejs
            pkgs.nodePackages.tailwindcss
            pkgs.firebase-tools
            pkgs.jq
          ];

          shellHook = ''
            echo "Unity Game Submissions Development Environment"
            echo "============================================="
            echo "Project Structure: public/ directory"
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

            # Watch mode for development
            watch_css() {
              echo "Watching CSS changes..."
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --watch
            }

            echo "Available commands:"
            echo "  build_elm       - Build Elm applications to public/"
            echo "  build_css       - Build CSS to public/"
            echo "  build_all       - Build everything"
            echo "  watch_css       - Watch CSS changes"
            echo "  deploy_firebase - Deploy to Firebase"
            echo "  nix run         - Interactive menu"
            echo ""
            echo "File outputs:"
            echo "  ├── public/admin/admin.js      (Elm compiled)"
            echo "  ├── public/student/student.js  (Elm compiled)"
            echo "  └── public/css/tailwind.css    (CSS compiled)"
            echo ""
          '';
        };
      }
    );
}
