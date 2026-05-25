# Android Fastlane Automation

This directory contains the Fastlane configuration and metadata files used to automate building, signing, and releasing the Luanti Android application.

---

## How Each File in this Directory Works

### `metadata/`
This subdirectory contains structured directories and files reflecting Google Play Store's metadata specifications. They are read by Fastlane commands (like `fastlane supply`) to update store listings automatically.

- **`metadata/android/en-US/title.txt`**:
  Contains the application's official display name on the English US Google Play Store.
- **`metadata/android/en-US/short_description.txt`**:
  Contains the brief tagline displayed on mobile search views (limited to 80 characters).
- **`metadata/android/en-US/full_description.txt`**:
  Contains the comprehensive marketing text, links, and detailed description of the app displayed on the Play Store page.
- **`metadata/android/en-US/images/`**:
  Houses screenshots of the game, promotional graphics, high-res app icons, and TV banners uploaded to store listings.
- **`metadata/android/en-US/changelogs/`**:
  Contains subfiles named after build numbers (e.g. `123.txt`) that hold short bullet points describing what's new in that specific release. This text is displayed to users when they view update descriptions on their devices.
- **`Fastfile`** (Usually in root `fastlane/`):
  Defines the pipeline "lanes" (scripts). For example:
  - `lane :beta` compiles the Android release APK, signs it using target keys, and uploads it directly to Google Play's internal testing track.
  - `lane :release` uploads production-ready AAB bundles and synchronizes all locale metadata files from this directory to the live store page.
