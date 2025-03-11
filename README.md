# Unity Game Submissions with Nix Flake

This project uses Nix flakes to provide a consistent development environment and build pipeline for an Elm application that integrates with Firebase.

## Prerequisites

- [Nix package manager](https://nixos.org/download.html) with flakes enabled
- Firebase project and credentials

## Getting Started

1. Clone this repository:
   ```bash
   git clone <your-repository-url>
   cd <your-repository-directory>
   ```

2. Generate the Node.js packages file:
   ```bash
   node2nix -i node-packages.json -o node-packages.nix
   ```

3. Enter the development shell:
   ```bash
   nix develop
   ```

## Project Structure

```
.
├── Admin/                  # Admin Elm application
│   ├── src/                # Elm source files
│   ├── index.html          # Admin HTML template
│   └── firebase-admin.js   # Firebase integration for admin
├── Students/               # Student Elm application
│   ├── src/                # Elm source files
│   ├── index.html          # Student HTML template
│   └── student-firebase.js # Firebase integration for students
├── src/
│   └── css/
│       └── tailwind.css    # Tailwind CSS entry point
├── flake.nix               # Nix flake configuration
├── node-packages.json      # Node.js dependencies
├── node-packages.nix       # Generated Node.js packages
├── tailwind.config.js      # Tailwind configuration
├── postcss.config.js       # PostCSS configuration
└── firebase.json           # Firebase configuration
```

## Available Commands

- **Build the entire project**:
  ```bash
  nix build
  ```

- **Deploy to Firebase**:
  ```bash
  nix run
  ```

- **Update Node.js dependencies**:
  ```bash
  node2nix -i node-packages.json -o node-packages.nix
  ```

## Adding or Modifying Dependencies

1. Update the `node-packages.json` file with your new dependencies
2. Run `node2nix -i node-packages.json -o node-packages.nix`
3. Rebuild your project with `nix build`

## Elm Dependencies

Elm dependencies are managed through the standard `elm.json` file in each Elm application directory. When you add new Elm dependencies, the Nix build process will automatically pick them up.

## Firebase Configuration

Make sure to set up your Firebase project and credentials:

1. Log in to Firebase:
   ```bash
   firebase login
   ```

2. Initialize your project (if you haven't already):
   ```bash
   firebase init
   ```

3. Update the `firebase.json` file as needed for your specific project requirements.
