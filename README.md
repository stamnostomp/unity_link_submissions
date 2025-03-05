# Unity Game Submission System

A web-based platform for students to submit Unity game projects and for instructors to manage, grade, and track student progress using a martial arts belt progression system.

## 🌟 Features

### For Students
- **Personalized Student Experience**: Students can access their records using a firstname.lastname format
- **Belt-based Progression System**: Visual progression through different belt levels (White → Yellow → Green → Black)
- **Streamlined Submission Process**: Easy game submission with GitHub repository integration
- **Progress Tracking**: View submission history and grades

### For Instructors
- **Comprehensive Admin Dashboard**: Overview of all student submissions
- **Belt Management System**: Create, edit, and configure belt levels and associated games
- **Grading Tools**: Provide scores and feedback on student submissions
- **Student Management**: Create and manage student accounts

## 🔧 Technical Architecture

This application combines the type-safety and reliability of Elm with the real-time database capabilities of Firebase. The architecture follows a ports-based communication pattern to enable seamless interaction between Elm's pure functional world and Firebase's JavaScript API.

### Communication Flow

```
┌───────────────────────────────────────────────────────────┐
│                        Browser                            │
├───────────────┬───────────────────────┬──────────────────┤
│               │                       │                  │
│   ┌───────────▼──────────┐    ┌───────▼────────┐        │
│   │                      │    │                │        │
│   │      Elm Runtime     │    │   Firebase JS  │        │
│   │                      │    │                │        │
│   └───────────┬──────────┘    └───────┬────────┘        │
│               │                       │                  │
├───────────────┼───────────────────────┼──────────────────┤
│               │                       │                  │
│   ┌───────────▼──────────┐    ┌───────▼────────┐        │
│   │                      │    │                │        │
│   │     Elm Application  │◄───┼────►  Firebase │        │
│   │     (Admin/Student)  │    │     Database   │        │
│   │                      │    │                │        │
│   └──────────────────────┘    └────────────────┘        │
│                                                          │
└───────────────────────────────────────────────────────────┘

           │                       ▲
           │                       │
           │                       │
           ▼                       │

  ┌─────────────────────────────────────────────┐
  │              Firebase Backend               │
  │                                             │
  │  ┌─────────────┐     ┌───────────────────┐  │
  │  │   Students  │     │    Submissions    │  │
  │  └─────────────┘     └───────────────────┘  │
  │                                             │
  │  ┌─────────────┐     ┌───────────────────┐  │
  │  │    Belts    │     │    Grades         │  │
  │  └─────────────┘     └───────────────────┘  │
  │                                             │
  └─────────────────────────────────────────────┘
```

### Elm-Firebase Integration

The application uses **ports** as the communication channel between Elm and Firebase:

1. **Outgoing Ports**: Elm sends commands to JavaScript to perform Firebase operations
   - Creating/updating students
   - Saving submissions
   - Authentication requests
   - Belt management

2. **Incoming Ports**: JavaScript sends data back to Elm from Firebase responses
   - Authentication results
   - Student records
   - Submission lists
   - Belt configurations

3. **Firebase Operations**: Wrapped in JavaScript modules that handle:
   - Path sanitization (converting firstname.lastname to firstname_lastname)
   - Real-time database connections
   - Authentication flow
   - Error handling

## 📁 File Structure

```
src/
├── Admin.elm             # Admin interface for instructors
├── Student.elm           # Student submission interface
├── firebase-admin.js     # Firebase integration for admin features
├── student-firebase.js   # Firebase integration for student features
├── index.html            # Main HTML entry point
```

### Key Components

- **Admin.elm**: Provides the instructor dashboard for grading submissions and managing belts
- **Student.elm**: Offers the student interface for submitting games and viewing progress
- **firebase-admin.js**: Handles Firebase operations for the admin interface
- **student-firebase.js**: Manages Firebase operations for the student interface

## 🔄 Data Models

### Student
```elm
type alias Student =
    { id : String          -- "firstname_lastname" (sanitized for Firebase)
    , name : String        -- "firstname.lastname" (preserved for display)
    , created : String     -- ISO date
    , lastActive : String  -- ISO date
    , submissions : List Submission
    }
```

### Belt
```elm
type alias Belt =
    { id : String
    , name : String        -- "White Belt", "Yellow Belt", etc.
    , color : String       -- Color code: "#FFFFFF", "#FFEB3B", etc.
    , order : Int          -- Progression order
    , gameOptions : List String  -- Available games for this belt
    }
```

### Submission
```elm
type alias Submission =
    { id : String
    , studentId : String
    , beltLevel : String
    , gameName : String
    , githubLink : String
    , notes : String
    , submissionDate : String
    , grade : Maybe Grade
    }
```

## 🚀 Setup and Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/stamnostomp/unity_link_submissions.git
   cd unity_link_submission
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure Firebase**
   - Create a Firebase project at [firebase.google.com](https://firebase.google.com)
   - Update the `firebaseConfig` object in both JavaScript files

4. **Compile Elm code**
   ```bash
   elm make src/Admin.elm --output=admin.js
   elm make src/Student.elm --output=student.js
   ```

5. **Serve the application**
   ```bash
   npx serve
   ```

## 💡 Usage

### Student Flow
1. Enter your name in firstname.lastname format (e.g., tyler.smith)
2. View your current belt level and available games
3. Select a game to submit and provide your GitHub repository link
4. Submit your game and wait for instructor feedback

### Admin Flow
1. Login with your admin credentials
2. View all student submissions across different belt levels
3. Grade submissions and provide feedback
4. Manage belt levels and configure available games for each belt
5. Create new student accounts when needed

## 🔍 Firebase Database Structure

```
elm-unity-subs/
├── students/
│   ├── firstname_lastname/
│   │   ├── name: "firstname.lastname"
│   │   ├── created: "2025-03-04"
│   │   └── lastActive: "2025-03-04"
│
├── submissions/
│   ├── submission_id/
│   │   ├── studentId: "firstname_lastname"
│   │   ├── beltLevel: "white-belt"
│   │   ├── gameName: "Game 1"
│   │   ├── githubLink: "https://github.com/..."
│   │   ├── notes: "..."
│   │   ├── submissionDate: "2025-03-04"
│   │   └── grade: { score, feedback, gradedBy, gradingDate }
│
└── belts/
    ├── white-belt/
    │   ├── name: "White Belt"
    │   ├── color: "#FFFFFF"
    │   ├── order: 1
    │   └── gameOptions: ["Game 1", "Game 2", "Game 3"]
    └── yellow-belt/
        ├── name: "Yellow Belt"
        ├── color: "#FFEB3B"
        ├── order: 2
        └── gameOptions: ["Game A", "Game B"]
```

## 📝 Special Considerations

### Firebase Path Sanitization

Firebase doesn't allow certain characters in database paths, including periods (`.`). Since our application uses firstname.lastname format, we implement path sanitization to convert:

- User enters: `tyler.smith`
- Display name: `tyler.smith` (preserved for UI)
- Database path: `students/tyler_smith` (sanitized for Firebase)

This allows us to maintain the desired naming convention while complying with Firebase's requirements.

## 🔒 Authentication

The admin interface uses Firebase Authentication with email/password. The student interface is public but requires students to enter their name to access their records.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
