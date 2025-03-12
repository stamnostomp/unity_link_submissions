# Unity Game Submissions

A comprehensive web application for managing Unity game submissions built with Elm and Firebase, using Nix for reproducible builds.

## 🌐 Live Demo

Visit the application at: [https://elm-unity-subs.web.app](https://elm-unity-subs.web.app)

## 🚀 Features

### Student Portal
- Simple submission form for uploading Unity game projects
- Personalized student profiles displaying submission history
- Belt-based progression system for tracking skill advancement
- Game selection based on current belt level
- GitHub repository link management

### Admin Portal
- Comprehensive dashboard for reviewing and grading student submissions
- Advanced filtering and sorting options for submissions management
- Grade submissions with detailed feedback and scoring
- Student record management
- Belt level configuration with customizable game options
- Admin user management with role-based permissions
- Password reset functionality

### New Features
- **Belt Management System**: Configure custom belt levels with specific colors and ordered progression
- **Game Options by Belt Level**: Customize available games for each belt level
- **Role-Based Admin Access**: Superuser and regular admin roles with appropriate permissions
- **Admin User Management**: Create, edit, and delete admin users
- **Password Reset Functionality**: Self-service password recovery for admin users
- **Student Directory**: Comprehensive view of all students with sorting and filtering
- **Detailed Grading System**: Provide scores and feedback for student submissions
- **Confirmation Dialogs**: Safe deletion of student records, submissions, and admin accounts
- **Real-time Data Updates**: Immediate data synchronization with Firebase

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

## 🔐 Authentication and Security

- Firebase Authentication for secure admin access
- Role-based permissions system
- Only authenticated admins can access student records and submissions
- Superuser role required for admin user management
- Secure password reset process

## 📱 Responsive Design

The application is fully responsive and works well on:
- Desktop computers
- Tablets
- Mobile phones

All interface elements adapt to different screen sizes for optimal user experience.

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
- `nix run` - Show interactive menu with all available options
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

## 🗂️ Database Structure

The Firebase Realtime Database follows this structure:

```
├── students/              # Student records
│   ├── [student-id]/      # Individual student
│   │   ├── name           # Student name (firstname.lastname format)
│   │   ├── created        # Account creation date
│   │   └── lastActive     # Last activity date
│
├── submissions/           # Game submissions
│   ├── [submission-id]/   # Individual submission
│   │   ├── studentId      # ID of the submitting student
│   │   ├── beltLevel      # Belt level for this submission
│   │   ├── gameName       # Selected game name
│   │   ├── githubLink     # GitHub repository link
│   │   ├── notes          # Additional notes
│   │   ├── submissionDate # Date of submission
│   │   └── grade/         # Optional grading information
│   │       ├── score      # Numeric score (0-100)
│   │       ├── feedback   # Detailed feedback
│   │       ├── gradedBy   # Admin email who graded
│   │       └── gradingDate # Date of grading
│
├── belts/                # Belt configurations
│   ├── [belt-id]/        # Individual belt
│   │   ├── name          # Belt name (e.g., "White Belt")
│   │   ├── color         # Belt color in hex format
│   │   ├── order         # Display/progression order
│   │   └── gameOptions   # Array of game options for this belt
│
└── admins/               # Admin user accounts
    └── [user-uid]/       # Individual admin
        ├── email         # Admin email
        ├── displayName   # Display name
        ├── role          # User role (admin or superuser)
        ├── createdBy     # Email of admin who created this account
        └── createdAt     # Creation timestamp
```

## 📜 URL Routes

- `/` - Application landing page with links to student and admin portals
- `/student` - Student interface for game submissions
- `/admin` - Administrator interface for managing submissions, students, and belts

## 🧰 Technologies Used

- [Elm](https://elm-lang.org/) - The frontend language for reliable web applications
- [Firebase](https://firebase.google.com/) - Backend, authentication, and hosting
- [Tailwind CSS](https://tailwindcss.com/) - Utility-first CSS framework
- [Nix](https://nixos.org/) - Build system for reproducible development

## 👥 User Roles

- **Students**: Submit game projects and view their submission history
- **Admin**: Review and grade submissions, manage student records, configure belt levels
- **Superuser**: Additional privileges to manage other admin accounts

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
