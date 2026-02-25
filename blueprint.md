
# NirogX App Blueprint

## Overview

NirogX is a personal health assistant application designed to help users track, analyze, and understand their health data. The app provides AI-powered insights, a chat interface for health queries, and tools for managing personal health information.

## Style, Design, and Features

### Version 1.0 (Initial Implementation)

#### Authentication
- **Login Screen:** Allows existing users to log in.
- **Sign-up Screen:** Allows new users to create a profile.

#### Main Application
- **Home Screen:** The central navigation hub of the application.
- **Bottom Navigation Bar:** Provides access to the main sections of the app: Home, Analyze, Insights, AI Chat, and Profile.

#### Core Features
- **Analyze Data:** A section for users to input health data by scanning reports, logging symptoms, or connecting devices.
- **AI Chat:** An interface for users to ask health-related questions and upload documents for analysis.
- **Insights:** A section to display trends, personalized reports, and predictive alerts based on the user's health data.
- **Profile:** A section for users to manage their personal information, medical history, connected devices, and app settings.

#### Styling
- **Theme:** A modern, clean theme with a green and white color palette, inspired by the NirogX logo.
- **Typography:** Uses the Google Fonts library for a clean and readable text hierarchy.
- **UI Components:** Follows Material Design 3 principles for a consistent and intuitive user experience.

## Current Plan

### Implement the Basic UI Flow and Navigation

**Objective:** Create the foundational structure of the app, including all the main screens and the navigation between them.

**Steps:**

1.  **Set up Project:**
    *   Add necessary dependencies: `provider`, `google_fonts`, and `go_router`.

2.  **Create File Structure:**
    *   Organize the `lib` directory into subfolders for screens, routing, theme, and widgets to maintain a clean and scalable codebase.

3.  **Implement Routing:**
    *   Use `go_router` to define routes for all screens, including a nested navigation structure for the bottom navigation bar.

4.  **Design Theme:**
    *   Create a `ThemeData` object that defines the app's color scheme, typography, and component styles.

5.  **Build Screens (Placeholder):**
    *   Create stateless widgets for each screen in the UI flow:
        - `LoginScreen`
        - `SignUpScreen`
        - `HomeScreen`
        - `AnalyzeDataScreen`
        - `AiChatScreen`
        - `InsightsScreen`
        - `ProfileScreen`

6.  **Create Main Scaffold:**
    *   Implement a stateful shell route with a `Scaffold` and a `BottomNavigationBar` to manage the main app sections.

7.  **Update `main.dart`:**
    *   Configure the `MaterialApp.router` to use the defined router and theme.
