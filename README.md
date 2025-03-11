# Unity Game Submissions

A web application for managing Unity game submissions built with Elm and Firebase, using Nix for reproducible builds.

## 🌐 Live Demo

Visit the application at: [https://elm-unity-subs.web.app](https://elm-unity-subs.web.app)

## 🚀 Features

- Separate interfaces for administrators and students
- Real-time data synchronization with Firebase
- Responsive design with Tailwind CSS
- Reproducible builds with Nix flakes

## 📋 Project Structure

```
.
├── Admin/                  # Admin interface
│   ├── admin.html          # Admin HTML template
│   ├── admin.js            # Compiled Elm code for Admin
│   ├── firebase-admin.js   # Firebase integration for Admin
│   └── style.css           # Compiled CSS for Admin
├── Student/                # Student interface
│   ├── student.html        # Student HTML template
│   ├── student.js          # Compiled Elm code for Student
│   ├── student-firebase.js # Firebase integration for Student
│   └── style.css           # Compiled CSS for Student
├── css/                    # Global CSS directory
│   └── tailwind.css        # Compiled Tailwind CSS
├── src/                    # Source files
│   ├── Admin.elm           # Elm source for Admin interface
│   ├── Student.elm         # Elm source for Student interface
│   └── css/                # CSS source
│       └── tailwind.css    # Tailwind CSS source file
├── flake.nix               # Nix flake configuration
├── elm.json                # Elm package configuration
├── firebase.json           # Firebase configuration
└── tailwind.config.js      # Tailwind CSS configuration
```

## 🛠️ Development

This project uses Nix flakes for reproducible builds and development environments. Here's how to get started:

### Prerequisites

- [Nix package manager](https://nixos.org/download.html) with flakes enabled
- Firebase project for deployment

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/stamnostomp/unity_link_submissions.git
cd unity_link_submissions
```

2. Enter the development shell:
```bash
nix develop
```

3. Build the project:
```bash
build_all
```

### Available Commands

Once in the Nix development shell, you can use these commands:

- `build_all` - Build Elm and CSS for local development
- `deploy_firebase` - Deploy to Firebase
- `nix run` - Show interactive menu
- `nix run .#build-elm` - Build only Elm files
- `nix run .#favicon` - Generate favicon
- `nix run .#deploy` - Deploy to Firebase

## 📝 Firebase Configuration

To deploy to Firebase:

1. Create a file named `.firebaserc` with your project ID:
```json
{
  "projects": {
    "default": "your-firebase-project-id"
  }
}
```

2. Deploy the project:
```bash
nix run .#deploy
```

## 📜 URL Routes

- `/admin` - Administrator interface
- `/student` - Student interface

## 🧰 Technologies Used

- [Elm](https://elm-lang.org/) - The frontend language
- [Firebase](https://firebase.google.com/) - Backend and hosting
- [Tailwind CSS](https://tailwindcss.com/) - Styling
- [Nix](https://nixos.org/) - Build system

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
