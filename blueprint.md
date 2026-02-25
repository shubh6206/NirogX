
# NirogX App Blueprint

## Overview

NirogX is a health and wellness application that allows users to track their health, get AI-powered insights, and manage their medical information.

## Style, Design, and Features

### Initial Version (v1.0)

*   **UI Flow:**
    *   **Authentication:** Login and Sign Up screens.
    *   **Home Screen:** A central hub with a bottom navigation bar.
    *   **Main Sections:** Analyze Data, AI Chat, Insights, and Profile.
*   **Design:**
    *   **Color Scheme:** Primary color is a shade of green, inspired by the logo.
    *   **Typography:** Using Google Fonts for a modern and clean look.
    *   **Iconography:** Using Material Design icons for navigation and actions.
*   **Features:**
    *   **Authentication:** Basic email/password authentication flow.
    *   **Analyze Data:** UI for scanning reports, logging symptoms, and connecting devices.
    *   **AI Chat:** A simple chat interface.
    *   **Insights:** Placeholders for trends, reports, and alerts.
    *   **Profile:** A screen with options for managing user information and settings.

## Current Plan

### Implement the UI Flow from the Design

1.  **Project Structure:**
    *   Create a `screens` directory for all the app screens.
    *   Create a `widgets` directory for reusable UI components.
    *   Create placeholder files for each screen.
2.  **Authentication Flow:**
    *   Implement the `LoginScreen` and `SignUpScreen`.
    *   Set up navigation to the `HomeScreen` after successful authentication.
3.  **Home Screen:**
    *   Create a `HomeScreen` with a `BottomNavigationBar`.
    *   Implement the navigation to the "Analyze", "Insights", "AI Chat", and "Profile" screens.
4.  **Implement Screens:**
    *   Create the UI for the "Analyze Data" screen.
    *   Create the UI for the "AI Chat" screen.
    *   Create the UI for the "Insights" screen.
    *   Create the UI for the "Profile" screen.
5.  **Theming:**
    *   Apply a consistent `ThemeData` across the app.
    *   Use the green color scheme and Google Fonts.
