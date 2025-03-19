### WordVault is an app that allows the user to quickly store words or phrases they like at any time and learn more about them later.

To do list:

P0:
- Add Siri integration, store word when user says "Hey Siri, word vault <insert word>". Siri double checks spelling with user and asks confirmation (Should   provide option to disable spelling check in settings)
- Add ability to organize words into collections. Collections can be created and accessed from home screen
- Create a default collection called favorites and allow any word to be flagged or unflagged as favorite
- Make data models resilient to updates in the future

P1:
- Add timeline
- Display fun fact about word using LLM 
- Add Learning features
    - Write sentences with word and assess correctness of usage with LLM
    - Write definition for word and have meaning assessed by LLM
    - Mix and match words with corresponding definitions/Synonyms 
- Add a notification option for word of the day
- Add a settings view in which the user can turn on/off certain preferences
- Change post to save in share screen 

P2:
- Focus on maximizing UI quality of app across all screens and modals



## Cursor Rules

you are an expert in coding with swift, swift ui. you always write maintainable code and clean code.
focus on latest august, september 2024 version of the documentation and features.
your descriptions should be short and concise.
don't remove any comments.

SwiftUI Project structure: 

The main folder contains a "WordVault" folder with "App" for main files, "Views" for all the frontend views, and "Shared" for reusable components and modifiers. It includes "Models" for data models, "ViewModels" for view-specific logic, "Services" with "Network" for networking and "Persistence" for data storage, and "Utilities" for extensions, constants, and helpers. The "Assets" folder for images and colors. Lastly, the "Tests" folder includes files for unit tests adn UI tests.

SwiftUI UI Design Rules:

Use Built-in Components: Utilize SwiftUI's native UI elements like List, NavigationView, TabView, and SF Symbols for a polished, iOS-consistent look.

Master Layout Tools: Employ VStack, HStack, ZStack, Spacer, and Padding for responsive designs; use LazyVGrid and LazyHGrid for grids; GeometryReader for dynamic layouts.

Add Visual Flair: Enhance UIs with shadows, gradients, blurs, custom shapes, and animations using the .animation() modifier for smooth transitions.

Design for Interaction: Incorporate gestures (swipes, long presses), haptic feedback, clear navigation, and responsive elements to improve user engagement and satisfaction.
