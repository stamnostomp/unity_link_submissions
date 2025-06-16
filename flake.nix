{
  description = "Unity Game Submissions with Elm and Firebase - Branch-Based Deployment";

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

          # Default build package
          default = pkgs.stdenv.mkDerivation {
            name = "unity-game-submissions";
            src = ./.;

            installPhase = ''
              cp -r ./public $out/
              mkdir -p $out/css
              cp ${self.packages.${system}.tailwind}/css/tailwind.css $out/css/
            '';
          };
        };

        apps = {
          # Build Elm applications
          build-elm = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "build-elm" ''
              set -e
              echo "Building Elm applications..."

              mkdir -p public/admin public/student

              echo "Compiling Admin application..."
              ${pkgs.elmPackages.elm}/bin/elm make src/elm/Admin.elm --output=public/admin/admin.js --optimize

              echo "Compiling Student application..."
              ${pkgs.elmPackages.elm}/bin/elm make src/elm/Student.elm --output=public/student/student.js --optimize

              echo "✅ Elm applications compiled successfully!"
            '';
          };

          # Build CSS
          build-css = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "build-css" ''
              echo "Building Tailwind CSS..."
              mkdir -p public/css
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --minify
              echo "✅ CSS compiled successfully!"
            '';
          };

          # NEW: Create deployment branch
          create-branch = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "create-branch" ''
              if [[ ! -f "scripts/create-deployment-branch.sh" ]]; then
                echo "Error: scripts/create-deployment-branch.sh not found"
                echo "Make sure you're running this from the project root"
                exit 1
              fi
              chmod +x scripts/create-deployment-branch.sh
              ./scripts/create-deployment-branch.sh
            '';
          };

          # NEW: Sync from main branch
          sync-main = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "sync-main" ''
              if [[ ! -f "scripts/sync-from-main.sh" ]]; then
                echo "Error: scripts/sync-from-main.sh not found"
                echo "Make sure you're running this from a deployment branch"
                exit 1
              fi
              chmod +x scripts/sync-from-main.sh
              ./scripts/sync-from-main.sh
            '';
          };

          # NEW: Deploy current branch
          deploy-branch = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "deploy-branch" ''
              # Check if we're in a deployment branch
              if [[ ! -f ".deployment-config.json" ]]; then
                echo "Error: Not in a deployment branch"
                echo "This command should be run from a deployment branch"
                echo ""
                echo "Available commands:"
                echo "  nix run .#create-branch  - Create new deployment branch"
                echo "  git checkout <branch>    - Switch to existing deployment branch"
                exit 1
              fi

              PROJECT_NAME=$(${pkgs.jq}/bin/jq -r '.projectName' .deployment-config.json)
              BRANCH_NAME=$(${pkgs.jq}/bin/jq -r '.branchName' .deployment-config.json)
              PROJECT_ID=$(${pkgs.jq}/bin/jq -r '.firebaseProjectId' .deployment-config.json)

              echo "Deploying $PROJECT_NAME ($BRANCH_NAME) to $PROJECT_ID"
              echo "=================================================="

              # Build applications
              echo "Building Elm applications..."
              ${self.apps.${system}.build-elm.program}

              echo "Building CSS..."
              ${self.apps.${system}.build-css.program}

              # Copy environment config
              echo "Copying Firebase configuration..."
              mkdir -p public/js/firebase/config
              if [[ -f "environment/config/firebase-config.js" ]]; then
                cp environment/config/firebase-config.js public/js/firebase/config/
              else
                echo "Error: Firebase config not found at environment/config/firebase-config.js"
                exit 1
              fi

              # Append custom CSS if it exists
              if [[ -f "branding/css/custom.css" ]]; then
                echo "Including custom CSS..."
                echo "" >> public/css/tailwind.css
                echo "/* Custom CSS for $BRANCH_NAME */" >> public/css/tailwind.css
                cat branding/css/custom.css >> public/css/tailwind.css
              fi

              # Deploy to Firebase
              echo "Deploying to Firebase..."
              ${pkgs.firebase-tools}/bin/firebase deploy --project $PROJECT_ID

              echo ""
              echo "✅ Deployment successful!"
              echo "🌐 Live Site: https://$PROJECT_ID.web.app"
              echo "👨‍💼 Admin Panel: https://$PROJECT_ID.web.app/admin"
              echo "🎓 Student Portal: https://$PROJECT_ID.web.app/student"
            '';
          };

          # Development servers
          dev-admin = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "dev-admin" ''
              echo "Starting development server for Admin interface..."

              # Build CSS first
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --minify

              # Add custom CSS if we're in a deployment branch
              if [[ -f "branding/css/custom.css" ]]; then
                echo "Including custom CSS for development..."
                echo "" >> public/css/tailwind.css
                echo "/* Custom CSS for development */" >> public/css/tailwind.css
                cat branding/css/custom.css >> public/css/tailwind.css
              fi

              # Copy Firebase config if we're in a deployment branch
              if [[ -f "environment/config/firebase-config.js" ]]; then
                mkdir -p public/js/firebase/config
                cp environment/config/firebase-config.js public/js/firebase/config/
              fi

              echo "Starting elm-live for Admin..."
              echo "Open http://localhost:8000/admin/admin.html in your browser"
              ${pkgs.elmPackages.elm-live}/bin/elm-live src/elm/Admin.elm \
                --port=8000 \
                --dir=public \
                --start-page=admin/admin.html \
                -- --output=public/admin/admin.js
            '';
          };

          dev-student = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "dev-student" ''
              echo "Starting development server for Student interface..."

              # Build CSS first
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --minify

              # Add custom CSS if we're in a deployment branch
              if [[ -f "branding/css/custom.css" ]]; then
                echo "Including custom CSS for development..."
                echo "" >> public/css/tailwind.css
                echo "/* Custom CSS for development */" >> public/css/tailwind.css
                cat branding/css/custom.css >> public/css/tailwind.css
              fi

              # Copy Firebase config if we're in a deployment branch
              if [[ -f "environment/config/firebase-config.js" ]]; then
                mkdir -p public/js/firebase/config
                cp environment/config/firebase-config.js public/js/firebase/config/
              fi

              echo "Starting elm-live for Student..."
              echo "Open http://localhost:8000/student/student.html in your browser"
              ${pkgs.elmPackages.elm-live}/bin/elm-live src/elm/Student.elm \
                --port=8000 \
                --dir=public \
                --start-page=student/student.html \
                -- --output=public/student/student.js
            '';
          };

          # Branch management menu
          default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "unity-submissions" ''
              # Check if we're in a deployment branch
              IS_DEPLOYMENT_BRANCH=false
              PROJECT_NAME=""
              BRANCH_NAME=""

              if [[ -f ".deployment-config.json" ]]; then
                IS_DEPLOYMENT_BRANCH=true
                PROJECT_NAME=$(${pkgs.jq}/bin/jq -r '.projectName' .deployment-config.json)
                BRANCH_NAME=$(${pkgs.jq}/bin/jq -r '.branchName' .deployment-config.json)
              fi

              echo "Unity Game Submissions Manager - Branch-Based Deployment"
              echo "========================================================"

              if [[ "$IS_DEPLOYMENT_BRANCH" == true ]]; then
                echo "📍 Current deployment: $PROJECT_NAME ($BRANCH_NAME)"
              else
                echo "📍 Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
              fi
              echo ""

              if [[ "$IS_DEPLOYMENT_BRANCH" == true ]]; then
                echo "🚀 Deployment Commands:"
                echo "1: Deploy this branch to Firebase"
                echo "2: Sync updates from main branch"
                echo ""
              fi

              echo "🌿 Branch Management:"
              echo "3: Create new deployment branch"
              echo "4: List all branches"
              echo "5: Switch to different branch"
              echo ""
              echo "💻 Development:"
              echo "6: Start Admin dev server (elm-live)"
              echo "7: Start Student dev server (elm-live)"
              echo ""
              echo "🔨 Building:"
              echo "8: Build Elm applications"
              echo "9: Build CSS"
              echo "10: Build All (Elm + CSS)"
              echo ""
              echo "ℹ️  Information:"
              echo "11: Show project structure"
              echo "12: Show branch information"
              echo "13: Exit"
              echo ""
              echo "Enter your choice (1-13):"
              read choice

              case $choice in
                1)
                  if [[ "$IS_DEPLOYMENT_BRANCH" == true ]]; then
                    ${self.apps.${system}.deploy-branch.program}
                  else
                    echo "Error: Not in a deployment branch"
                    echo "Use option 3 to create a deployment branch or option 5 to switch to one"
                  fi
                  ;;
                2)
                  if [[ "$IS_DEPLOYMENT_BRANCH" == true ]]; then
                    ${self.apps.${system}.sync-main.program}
                  else
                    echo "Error: Not in a deployment branch"
                    echo "This command syncs updates from main to a deployment branch"
                  fi
                  ;;
                3)
                  ${self.apps.${system}.create-branch.program}
                  ;;
                4)
                  echo "All branches:"
                  git branch -a | sed 's/^/  /'
                  echo ""
                  echo "Deployment branches:"
                  git branch | grep -v main | while read branch; do
                    branch_name=$(echo $branch | sed 's/^[* ]*//')
                    if git show $branch_name:.deployment-config.json >/dev/null 2>&1; then
                      project_name=$(git show $branch_name:.deployment-config.json | ${pkgs.jq}/bin/jq -r '.projectName' 2>/dev/null || echo "Unknown")
                      echo "  $branch_name -> $project_name"
                    fi
                  done
                  ;;
                5)
                  echo "Available branches:"
                  git branch | sed 's/^/  /'
                  echo ""
                  read -p "Branch to switch to: " target_branch
                  if [[ -n "$target_branch" ]]; then
                    git checkout $target_branch
                    echo "Switched to branch: $target_branch"
                  fi
                  ;;
                6)
                  ${self.apps.${system}.dev-admin.program}
                  ;;
                7)
                  ${self.apps.${system}.dev-student.program}
                  ;;
                8)
                  ${self.apps.${system}.build-elm.program}
                  ;;
                9)
                  ${self.apps.${system}.build-css.program}
                  ;;
                10)
                  ${self.apps.${system}.build-elm.program} && ${self.apps.${system}.build-css.program}
                  ;;
                11)
                  echo "Project structure:"
                  echo "📁 Unity Game Submissions"
                  echo "├── 🏗️  src/ (Elm source code)"
                  echo "├── 📦 public/ (compiled output)"
                  if [[ "$IS_DEPLOYMENT_BRANCH" == true ]]; then
                    echo "├── 🎨 branding/ (custom styling)"
                    echo "├── ⚙️  environment/ (Firebase config)"
                    echo "└── 📚 docs/ (branch documentation)"
                  else
                    echo "├── 🌍 environments/ (multi-environment configs)"
                    echo "├── 📝 templates/ (config templates)"
                    echo "└── 🔧 scripts/ (deployment scripts)"
                  fi
                  ;;
                12)
                  if [[ "$IS_DEPLOYMENT_BRANCH" == true ]]; then
                    echo "📋 Branch Information:"
                    echo "$(${pkgs.jq}/bin/jq -r '"Branch: " + .branchName' .deployment-config.json)"
                    echo "$(${pkgs.jq}/bin/jq -r '"Organization: " + .organizationName' .deployment-config.json)"
                    echo "$(${pkgs.jq}/bin/jq -r '"Project: " + .projectName' .deployment-config.json)"
                    echo "$(${pkgs.jq}/bin/jq -r '"Firebase Project: " + .firebaseProjectId' .deployment-config.json)"
                    echo "$(${pkgs.jq}/bin/jq -r '"Created: " + .createdDate' .deployment-config.json)"
                    echo "$(${pkgs.jq}/bin/jq -r '"Brand Color: " + .brandColor' .deployment-config.json)"
                    echo ""
                    echo "🌐 URLs:"
                    PROJECT_ID=$(${pkgs.jq}/bin/jq -r '.firebaseProjectId' .deployment-config.json)
                    echo "  Live Site: https://$PROJECT_ID.web.app"
                    echo "  Admin Panel: https://$PROJECT_ID.web.app/admin"
                    echo "  Student Portal: https://$PROJECT_ID.web.app/student"
                  else
                    echo "📋 Repository Information:"
                    echo "Current branch: $(git branch --show-current)"
                    echo "Latest commit: $(git log --oneline -1)"
                    echo ""
                    echo "This is not a deployment branch."
                    echo "Use option 3 to create a deployment branch."
                  fi
                  ;;
                13)
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
            pkgs.elmPackages.elm-live
            pkgs.nodejs
            pkgs.nodePackages.tailwindcss
            pkgs.firebase-tools
            pkgs.jq
            pkgs.tree
            pkgs.git
          ];

          shellHook = ''
            echo "Unity Game Submissions Development Environment - Branch-Based"
            echo "============================================================="

            # Check if we're in a deployment branch
            if [[ -f ".deployment-config.json" ]]; then
              PROJECT_NAME=$(jq -r '.projectName' .deployment-config.json)
              BRANCH_NAME=$(jq -r '.branchName' .deployment-config.json)
              ORG_NAME=$(jq -r '.organizationName' .deployment-config.json)

              echo "📍 Deployment Branch: $BRANCH_NAME"
              echo "🏢 Organization: $ORG_NAME"
              echo "📝 Project: $PROJECT_NAME"
              echo ""
              echo "🎨 This branch has custom branding and configuration"
            else
              echo "📍 Main/Development Branch"
              echo ""
              echo "💡 To create a new deployment, use: create_branch"
            fi
            echo ""

            # Core build functions
            build_elm() {
              ${self.apps.${system}.build-elm.program}
            }

            build_css() {
              ${self.apps.${system}.build-css.program}
            }

            build_all() {
              echo "Building everything..."
              build_elm && build_css
              echo "✅ Build complete!"
            }

            # Branch management functions
            create_branch() {
              ${self.apps.${system}.create-branch.program}
            }

            sync_main() {
              ${self.apps.${system}.sync-main.program}
            }

            deploy() {
              ${self.apps.${system}.deploy-branch.program}
            }

            # Development functions
            dev_admin() {
              ${self.apps.${system}.dev-admin.program}
            }

            dev_student() {
              ${self.apps.${system}.dev-student.program}
            }

            watch_css() {
              echo "Watching CSS changes..."
              ${pkgs.nodePackages.tailwindcss}/bin/tailwindcss \
                -i ./src/css/tailwind.css \
                -o ./public/css/tailwind.css \
                --watch
            }

            # Information functions
            show_branches() {
              echo "📋 All branches:"
              git branch -a
              echo ""
              echo "🚀 Deployment branches:"
              git branch | grep -v main | while read branch; do
                branch_name=$(echo $branch | sed 's/^[* ]*//')
                if git show $branch_name:.deployment-config.json >/dev/null 2>&1; then
                  project_name=$(git show $branch_name:.deployment-config.json | jq -r '.projectName' 2>/dev/null || echo "Unknown")
                  echo "  $branch_name -> $project_name"
                fi
              done
            }

            branch_info() {
              if [[ -f ".deployment-config.json" ]]; then
                echo "📋 Current Deployment Branch:"
                jq -r '"Branch: " + .branchName' .deployment-config.json
                jq -r '"Organization: " + .organizationName' .deployment-config.json
                jq -r '"Project: " + .projectName' .deployment-config.json
                jq -r '"Firebase Project: " + .firebaseProjectId' .deployment-config.json
                echo ""
                PROJECT_ID=$(jq -r '.firebaseProjectId' .deployment-config.json)
                echo "🌐 Live URL: https://$PROJECT_ID.web.app"
              else
                echo "📋 Current Branch: $(git branch --show-current)"
                echo "This is not a deployment branch."
              fi
            }

            echo "Available commands:"
            if [[ -f ".deployment-config.json" ]]; then
              echo "🚀 Deployment Commands:"
              echo "  deploy          - Deploy this branch to Firebase"
              echo "  sync_main       - Sync updates from main branch"
              echo ""
            fi
            echo "🌿 Branch Management:"
            echo "  create_branch   - Create new deployment branch"
            echo "  show_branches   - List all branches"
            echo "  branch_info     - Show current branch info"
            echo ""
            echo "💻 Development:"
            echo "  dev_admin       - Start Admin dev server"
            echo "  dev_student     - Start Student dev server"
            echo "  watch_css       - Watch CSS changes"
            echo ""
            echo "🔨 Building:"
            echo "  build_elm       - Build Elm applications"
            echo "  build_css       - Build CSS"
            echo "  build_all       - Build everything"
            echo ""
            echo "📋 Information:"
            echo "  nix run         - Interactive menu"
            echo ""
            if [[ -f ".deployment-config.json" ]]; then
              echo "🎯 Quick Start (Deployment Branch):"
              echo "  1. dev_admin or dev_student  - Start development"
              echo "  2. deploy                    - Deploy to Firebase"
              echo "  3. sync_main                 - Get updates from main"
            else
              echo "🎯 Quick Start (Main Branch):"
              echo "  1. create_branch             - Create deployment"
              echo "  2. dev_admin or dev_student  - Start development"
            fi
            echo ""
          '';
        };
      }
    );
}
