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

        # Project directories based on existing structure
        srcDir = "./src";
        adminOutputDir = "./Admin";
        studentOutputDir = "./Student";

        # Node.js dependencies
        nodeDependencies = (pkgs.callPackage ./node-packages.nix {}).nodeDependencies;
      in
      {
        packages = {
          # Build Elm code for Admin
          admin = pkgs.stdenv.mkDerivation {
            name = "elm-admin-app";
            src = ./.;
            buildInputs = [ pkgs.elmPackages.elm ];
            buildPhase = ''
              # Ensure output directory exists
              mkdir -p ${adminOutputDir}

              # Compile Elm code
              ${pkgs.elmPackages.elm}/bin/elm make ${srcDir}/Admin.elm --output=${adminOutputDir}/admin.js --optimize
            '';
            installPhase = ''
              mkdir -p $out/Admin
              cp ${adminOutputDir}/admin.js $out/Admin/

              # Copy other static files from Admin folder
              cp ${adminOutputDir}/*.html $out/Admin/ || true
              cp ${adminOutputDir}/*.css $out/Admin/ || true
              cp ${adminOutputDir}/*.js $out/Admin/ || true

              # Exclude admin.js which we just compiled
              rm -f $out/Admin/admin.js
              cp ${adminOutputDir}/admin.js $out/Admin/
            '';
          };

          # Build Elm code for Student
          student = pkgs.stdenv.mkDerivation {
            name = "elm-student-app";
            src = ./.;
            buildInputs = [ pkgs.elmPackages.elm ];
            buildPhase = ''
              # Ensure output directory exists
              mkdir -p ${studentOutputDir}

              # Compile Elm code
              ${pkgs.elmPackages.elm}/bin/elm make ${srcDir}/Student.elm --output=${studentOutputDir}/student.js --optimize
            '';
            installPhase = ''
              mkdir -p $out/Student
              cp ${studentOutputDir}/student.js $out/Student/

              # Copy other static files from Student folder
              cp ${studentOutputDir}/*.html $out/Student/ || true
              cp ${studentOutputDir}/*.css $out/Student/ || true
              cp ${studentOutputDir}/*.js $out/Student/ || true

              # Exclude student.js which we just compiled
              rm -f $out/Student/student.js
              cp ${studentOutputDir}/student.js $out/Student/
            '';
          };

          # Build Tailwind CSS
          tailwind = pkgs.stdenv.mkDerivation {
            name = "tailwind-css";
            src = ./.;
            buildInputs = [ pkgs.nodejs ];
            buildPhase = ''
              # Setup Node environment
              export PATH="${nodeDependencies}/bin:$PATH"
              export NODE_PATH="${nodeDependencies}/lib/node_modules"

              # Create output directories
              mkdir -p ${adminOutputDir}
              mkdir -p ${studentOutputDir}

              # Build Tailwind CSS for Admin
              npx tailwindcss -i ${srcDir}/css/tailwind.css -o ${adminOutputDir}/style.css --minify
              # Copy the same CSS to Student folder
              cp ${adminOutputDir}/style.css ${studentOutputDir}/style.css
            '';
            installPhase = ''
              mkdir -p $out/Admin $out/Student
              cp ${adminOutputDir}/style.css $out/Admin/
              cp ${studentOutputDir}/style.css $out/Student/
            '';
          };

          # Combined package
          default = pkgs.symlinkJoin {
            name = "unity-game-submissions";
            paths = [
              self.packages.${system}.admin
              self.packages.${system}.student
              self.packages.${system}.tailwind
            ];
          };
        };

        apps.default = flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "deploy" ''
            echo "Building project..."
            # Clean and create dist directory
            rm -rf dist
            mkdir -p dist/Admin dist/Student

            # Copy files to dist
            cp -r ${self.packages.${system}.default}/* dist/

            # Copy firebase.json to dist
            cp ./firebase.json dist/

            echo "Deploying to Firebase..."
            export PATH="${pkgs.firebase-tools}/bin:$PATH"
            cd dist && firebase deploy
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Development dependencies
            pkgs.elmPackages.elm
            pkgs.elmPackages.elm-format
            pkgs.elmPackages.elm-test
            pkgs.nodejs
            pkgs.firebase-tools

            # For node_modules linking
            pkgs.nodePackages.node2nix
          ];

          shellHook = ''
            export NODE_PATH="${nodeDependencies}/lib/node_modules"
            export PATH="${nodeDependencies}/bin:$PATH"

            echo "Nix development environment loaded!"
            echo "Available commands:"
            echo "  nix build - Build all packages"
            echo "  nix run - Deploy to Firebase"
            echo "  node2nix - Update Node.js dependencies"

            # Helper for local development
            build_local() {
              echo "Building Elm applications..."
              elm make src/Admin.elm --output=Admin/admin.js --optimize
              elm make src/Student.elm --output=Student/student.js --optimize

              echo "Building CSS..."
              npx tailwindcss -i src/css/tailwind.css -o Admin/style.css --minify
              cp Admin/style.css Student/style.css

              echo "Build complete!"
            }

            echo "  build_local - Build project for local development"
          '';
        };
      }
    );
}
