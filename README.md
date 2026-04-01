# Vez 🌟

**Vez** is a modern social media platform designed to bridge the gap between the digital and physical worlds. It empowers users to create, discover, and participate in real-life events, fostering genuine human connections through a sleek and intuitive mobile experience.

---

## 🚀 Key Features

- **Event Creation & Discovery**: Easily organize your own events or browse through a curated list of activities happening around you.
- **Seamless Authentication**: Secure Sign Up and Login system with password hashing (SHA-256) for maximum user data protection.
- **Glassmorphism UI**: A beautiful, modern interface powered by `liquid_glass_easy`, providing a high-end visual experience.
- **Real-time Integration**: Powered by a remote database for instant updates and reliable data management.
- **Personalized Profiles**: Custom profiles featuring user-specific bios, event statistics, and profile pictures.
- **Media Support**: Integrated image picking and uploading capabilities for profile customization.

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (v3.11.0+)
- **Language**: [Dart](https://dart.dev/)
- **Backend/Database**: REST-based remote DB (Supabase/PostgreSQL)
- **UI/UX**: Custom Glassmorphism design with Material 3 support.
- **Security**: SHA-256 Hashing for secure credential storage.

---

## 📦 Core Dependencies

- `http`: For robust network communication with the remote API.
- `crypto`: Implementation of secure hashing algorithms.
- `image_picker`: For handling media selection from the gallery or camera.
- `liquid_glass_easy`: For achieving the signature translucent glass effect in the UI.
- `cupertino_icons`: For high-quality iOS-style iconography.

---

## 🎨 Design Philosophy

Our goal is to create an application with a **modern and intuitive UI** by offering a **simple and captivating UX**. We aim for **simplicity and a minimalist but effective design**, ensuring that users can focus on what matters most: real-life connections.

Key visual pillars:
- **Instagram-style Typography**: Utilizing custom `InstagramSans` fonts for a premium aesthetic.
- **Modern Glassmorphism**: Creating a sophisticated look with depth and transparency.
- **Adaptive Experience**: A consistent look across platforms with an **Adaptive Icon** system for both Android and iOS.

---

## 🛠 Installation & Setup

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/your-username/vez.git
    cd vez
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Setup API Keys**:
    Create a `lib/services/api_keys.dart` file (if not present) and add your remote DB configuration:
    ```dart
    class ApiKeys {
      static const String remoteDbKey = 'YOUR_SUPABASE_KEY';
      static const String baseUrl = 'YOUR_SUPABASE_URL';
    }
    ```

4.  **Run the application**:
    ```bash
    flutter run
    ```

---

## 📈 Project Status

- [x] Database Integration
- [x] User Authentication
- [x] UI Prototype (Glassmorphism)
- [ ] Event Feed Implementation
- [ ] Notifications System

---

## 🤝 Contributing

We welcome contributions! If you'd like to improve Vez, please fork the repository and create a pull request, or open an issue with the tag "enhancement".

---

## 📄 License

Developed and Designed by **Outly** • © 2026. All rights reserved.
