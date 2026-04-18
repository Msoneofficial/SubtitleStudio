# Subtitle Studio

[![GitHub license](https://img.shields.io/github/license/anzilr/SubtitleStudio)](https://github.com/anzilr/SubtitleStudio/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/anzilr/SubtitleStudio)](https://github.com/anzilr/SubtitleStudio/issues)
[![GitHub stars](https://img.shields.io/github/stars/anzilr/SubtitleStudio)](https://github.com/anzilr/SubtitleStudio/stargazers)

A professional, cross-platform subtitle editing application built with **Flutter**. Subtitle Studio provides powerful tools for editing, synchronizing, and managing subtitle files with an intuitive, modern interface.

## ✨ Features

### Core Features
- 🎬 **Cross-Platform Support**: Android, iOS, macOS, Windows, Linux, and Web
- ✏️ **Professional Editing**: Frame-accurate timing adjustments and text formatting
- 🎥 **Video Synchronization**: Real-time subtitle sync with video playback
- 💾 **Auto-Save**: Never lose your work with automatic saving
- 🎨 **Customization**: Light, dark, and classic themes with color customization
- 📁 **Multi-Format Support**: SRT, ASS, VTT, and more
- 🔍 **Search & Replace**: Powerful find and replace with regex support
- ⌨️ **Keyboard Shortcuts**: Desktop-class editing experience
- 🌐 **Multi-Language**: Malayalam subtitle support and normalization
- 📊 **Performance**: Optimized for smooth playback and responsiveness

### Advanced Features
- Dual subtitle editing
- Batch operations
- Recent sessions tracking
- File association handling
- Subtitle statistics and analysis
- Custom color picker
- Export to multiple formats

## 📋 Requirements

### System Requirements
- **Flutter SDK**: 3.7.2 or later (stable channel)
- **Dart SDK**: 3.7.2 or later
- **Git**: For cloning the repository

### Platform-Specific Requirements

**Android**
- Minimum SDK: 24 (Android 7.0)
- Target SDK: 35 (Android 15)

**iOS**
- Minimum: iOS 12.0
- Xcode 14.0+

**macOS**
- Minimum: macOS 10.14
- Xcode 14.0+

**Windows**
- Windows 10/11
- Visual Studio 2019+ or Build Tools

**Linux**
- GTK 3.0+
- GCC/Clang toolchain

## 🚀 Quick Start

### 1. Installation

**Clone the repository:**
```bash
git clone https://github.com/anzilr/SubtitleStudio.git
cd SubtitleStudio
```

**Install Flutter dependencies:**
```bash
flutter pub get
```

**Optional: Set up environment variables** (for Telegram integration):
```bash
cp .env.example .env
# Edit .env and add your credentials if needed
# See .env.example for instructions
```

### 2. Running the App

**Android:**
```bash
flutter run
```

**iOS:**
```bash
flutter run
```

**macOS:**
```bash
flutter run -d macos
```

**Windows:**
```bash
flutter run -d windows
```

**Linux:**
```bash
flutter run -d linux
```

**Web:**
```bash
flutter run -d web
```

### 3. Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

**macOS:**
```bash
flutter build macos --release
```

**Windows:**
```bash
flutter build windows --release
```

**Linux:**
```bash
flutter build linux --release
```

## 🛠️ Development

### Setting Up Development Environment

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run code analysis:**
   ```bash
   dart analyze
   ```

3. **Format code:**
   ```bash
   dart format .
   ```

4. **Run tests:**
   ```bash
   flutter test
   ```

### Project Structure

```
lib/
├── main.dart                 # Application entry point
├── screens/                  # UI screens and pages
├── widgets/                  # Reusable UI components
├── services/                 # Business logic services
├── utils/                    # Utility functions
├── themes/                   # App theme configuration
├── database/                 # Local database models
├── operations/               # Subtitle operations
├── features/                 # Feature modules
```

### Architecture

Subtitle Studio follows a modular architecture with:
- **Feature-first organization** for scalability
- **Provider pattern** for state management
- **Isar database** for local persistence
- **Clean separation** of concerns


## 📦 Environment Configuration

### Telegram Integration (Optional)

To enable Telegram integration for bug reporting:

1. **Get a Telegram bot token:**
   - Talk to [@BotFather](https://t.me/BotFather)
   - Create a new bot
   - Copy the token

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   ```

3. **Edit `.env` file:**
   ```
   TELEGRAM_BOT_TOKEN=your_token_here
   TELEGRAM_CHANNEL_ID=your_channel_id_here
   ```

4. **Rebuild the app** for changes to take effect

## 📊 Version Information

### Current Version
- **App Version**: 3.0.0+30
- **Flutter SDK**: 3.7.2+
- **Dart SDK**: 3.7.2+
- **Status**: Actively Maintained ✓

### Build Information
- **Gradle**: 8.13
- **Kotlin**: 2.0.21+
- **Java**: VERSION_17+
- **Android Target SDK**: 35
- **Android Build Tools**: 35.0.0

## 🎨 Themes

Switch between three beautiful themes:
- **Light Theme** - Clean and minimal
- **Dark Theme** - Easy on the eyes
- **Classic Theme** - Traditional interface



## 📝 Changelog

### Latest Release: v3.0.0 - Subtitle Studio v3
- Complete UI/UX redesign
- Video player integration
- Enhanced subtitle editing
- Performance improvements
- Multi-platform support


## 📦 Dependencies

Key dependencies include:
- **Flutter**: UI framework
- **Provider**: State management
- **Isar**: Local database
- **Media Kit**: Video playback
- **FFmpeg**: Video processing
- **Flutter Dotenv**: Environment configuration

Run `flutter pub outdated` to check for dependency updates.

## 🐛 Known Issues

See [GitHub Issues](https://github.com/anzilr/SubtitleStudio/issues) for known issues and bug reports.

## 🎯 Roadmap

Future planned features:
- [ ] Cloud synchronization
- [ ] Batch processing improvements
- [ ] Performance optimizations
- [ ] Additional language support

## 📄 License

This project is licensed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for details.


## 🔗 Links

- **GitHub**: [anzilr/SubtitleStudio](https://github.com/anzilr/SubtitleStudio)
- **Issues**: [Report a bug](https://github.com/anzilr/SubtitleStudio/issues)
- **Discussions**: [Get help](https://github.com/anzilr/SubtitleStudio/discussions)

## 💬 Contact & Support

- 🐛 Report bugs via [GitHub Issues](https://github.com/anzilr/MsoneSubEditor/issues)
- 💬 Start a discussion on [GitHub Discussions](https://github.com/anzilr/MsoneSubEditor/discussions)

---

Made with ❤️ by the Msone community

**[⬆ back to top](#subtitle-studio)**

