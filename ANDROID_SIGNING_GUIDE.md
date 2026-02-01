# Android Signing Configuration Guide

## 🔐 Creating Your Android Keystore

### Step 1: Generate Keystore

Run this command in your project root:

```bash
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You will be prompted for:
- **Keystore password:** Choose a strong password (save it!)
- **Key password:** Choose a strong password (can be same as keystore password)
- **Name:** Your name or company name
- **Organizational unit:** Your department (e.g., "Development")
- **Organization:** Your company name
- **City:** Your city
- **State:** Your state/province
- **Country code:** Your country code (e.g., "TR" for Turkey)

### Step 2: Create key.properties File

Create `android/key.properties` with the following content:

```properties
KEYSTORE_FILE=../upload-keystore.jks
KEYSTORE_PASSWORD=your_keystore_password_here
KEY_ALIAS=upload
KEY_PASSWORD=your_key_password_here
```

**IMPORTANT:** Replace `your_keystore_password_here` and `your_key_password_here` with your actual passwords!

### Step 3: Update .gitignore

Ensure these lines are in your `.gitignore`:

```
android/key.properties
android/upload-keystore.jks
*.jks
*.keystore
```

### Step 4: Update build.gradle.kts

The signing configuration has been added to `android/app/build.gradle.kts`. It will automatically use the key.properties file.

## 🔒 CRITICAL: Backup Your Keystore!

**⚠️ WARNING:** If you lose your keystore file or passwords, you will NEVER be able to update your app on Google Play Store. You will have to publish a completely new app with a different package name.

### Backup Checklist:

- [ ] Copy `android/upload-keystore.jks` to a secure cloud storage (Google Drive, Dropbox, etc.)
- [ ] Save passwords in a password manager (1Password, LastPass, Bitwarden, etc.)
- [ ] Keep a physical backup on an external drive
- [ ] Share with a trusted team member (if applicable)
- [ ] Test that you can access the backup

## 📦 Building Release APK/AAB

### Build App Bundle (Recommended for Play Store):

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Build APK (For testing or direct distribution):

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## ✅ Verify Signing

Check that your app is properly signed:

```bash
# For AAB
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# For APK
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

You should see "jar verified" in the output.

## 🚀 Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to "Release" → "Production" (or "Internal testing" for first upload)
4. Click "Create new release"
5. Upload the `app-release.aab` file
6. Fill in release notes
7. Review and rollout

## 🔑 Keystore Information Storage

Store this information securely:

```
Keystore Location: android/upload-keystore.jks
Keystore Password: [YOUR_KEYSTORE_PASSWORD]
Key Alias: upload
Key Password: [YOUR_KEY_PASSWORD]
Key Algorithm: RSA
Key Size: 2048
Validity: 10000 days
```

## 📝 Troubleshooting

### Error: "key.properties not found"

Make sure you created the file at `android/key.properties` with the correct content.

### Error: "Keystore was tampered with, or password was incorrect"

Your password in `key.properties` is incorrect. Double-check the password.

### Error: "Cannot recover key"

Your KEY_PASSWORD is incorrect. Make sure it matches what you entered when creating the keystore.

## 🔄 Migrating to Google Play App Signing

After your first upload, Google Play will offer to manage your app signing key. This is recommended for additional security. You can then use an "upload key" instead of the "app signing key".

For more info: https://support.google.com/googleplay/android-developer/answer/9842756

---

**Remember:** Your keystore is as important as your source code. Treat it with the same level of security!
