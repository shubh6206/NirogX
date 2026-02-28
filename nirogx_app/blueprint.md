# NirogX App Blueprint

## Overview

NirogX is a modern, AI-powered health and wellness application designed to provide users with insightful analysis of their health data. The app features a clean, intuitive user interface and leverages the Gemini API for intelligent symptom analysis. The primary goal of NirogX is to empower users to take a proactive approach to their health by providing them with a personalized and easy-to-understand overview of their well-being.

## Style and Design

The application follows a modern, clean, and user-friendly design aesthetic, adhering to Material Design 3 principles. The visual design is intended to be both visually appealing and highly functional, ensuring a seamless user experience.

### Color Palette

*   **Primary Color:** `#00C853` (a vibrant, energetic green)
*   **Accent Color:** `#64FFDA` (a lighter, complementary green for highlights)
*   **Background Color:** `#FFFFFF` (clean white for a spacious feel)
*   **Text Color:** `#000000` (bold, readable black)

### Typography

*   **Primary Font:** `Roboto` - A versatile and highly-readable sans-serif font used for main titles and headlines.
*   **Secondary Font:** `Open Sans` - A clean and modern font used for body text and descriptions.
*   **Logo Font:** `Oswald` - A bold and impactful font used for the app's logo.

### Iconography

The app utilizes the `lucide_icons` package to provide a consistent and modern set of icons throughout the user interface. These icons are designed to be simple, clear, and easily recognizable.

### Layout and Components

The layout is designed to be spacious and uncluttered, with a focus on a clear visual hierarchy. Key UI components include:

*   **Gradient Health Score Card:** A prominent, eye-catching card on the home screen that displays the user's overall health score.
*   **Quick Action Buttons:** A set of clearly-labeled buttons for easy access to the app's main features.
*   **AI Insight Card:** A clean and simple card that provides users with AI-generated health tips and observations.

## Features

### 1.  AI-Powered Symptom Analysis

*   **Description:** Users can input their symptoms into a text field, and the app will use the Gemini API to provide a preliminary analysis of potential causes.
*   **Implementation:** The `SymptomCheckerView` allows users to enter their symptoms, which are then sent to the `GeminiService` for analysis. The response is then displayed in a clean and easy-to-read format.
*   **Disclaimer:** The app includes a clear disclaimer that the AI analysis is not a substitute for professional medical advice.

### 2.  Health Score Dashboard

*   **Description:** The app provides a comprehensive health score dashboard that gives users a quick and easy way to assess their overall well-being.
*   **Implementation:** The `HealthScoreView` displays the user's health score, along with a breakdown of key metrics such as heart rate, activity, and sleep quality.
*   **Visualizations:** The dashboard includes a circular progress indicator that provides a clear visual representation of the user's health score.

### 3.  Modern Onboarding and Authentication

*   **Description:** The app features a modern and intuitive onboarding process, with separate screens for login and sign-up.
*   **Implementation:** The `LoginScreen` and `SignUpScreen` provide a seamless authentication experience, with a clean design and clear calls-to-action.
*   **UI/UX:** The authentication screens utilize a gradient background and modern UI components to create a visually appealing and user-friendly experience.

### 4.  Navigation and Routing

*   **Description:** The app uses the `go_router` package for navigation, providing a robust and scalable solution for managing routes.
*   **Implementation:** The main navigation is handled by a `BottomNavigationBar`, which allows users to easily switch between the app's main screens.
*   **Routes:** The app includes routes for the home screen, symptom checker, and health score view.

## Project Structure

The project follows a feature-based structure, with each feature organized into its own directory. This approach promotes modularity and makes it easy to add new features in the future.

*   `lib/`
    *   `main.dart`: The main entry point of the application.
    *   `app.dart`: The root widget of the application, which includes the `MaterialApp` and `GoRouter` configuration.
    *   `gemini_service.dart`: A service that handles all interactions with the Gemini API.
    *   `models/`: Contains the data models used throughout the application.
    *   `screens/`: Contains the main screens of the application, organized by feature.
    *   `theme/`: Contains the application's theme data, including colors, fonts, and component styles.
    *   `widgets/`: Contains reusable widgets that are used across multiple screens.

## Next Steps and Future Enhancements

### Short-Term

*   **User Profile:** Implement a user profile screen where users can view and edit their personal information.
*   **Firebase Integration:** Integrate Firebase for user authentication, data storage, and analytics.
*   **Enhanced AI Insights:** Expand the AI-powered insights to include more personalized recommendations and health tips.

### Long-Term

*   **Wearable Device Integration:** Integrate with popular wearable devices to automatically track health data.
*   **Telemedicine Features:** Add telemedicine features that allow users to connect with healthcare professionals directly from the app.
*   **Gamification:** Introduce gamification elements to encourage users to stay engaged with their health goals.