# Mobile Device Setup Guide for Testing

This guide will help you connect your Android or iOS device to test your Flutter app.

## Prerequisites

✅ Flutter is already installed and configured
✅ Android Studio is installed
✅ Android SDK is set up

---

## For Android Devices

### Step 1: Enable Developer Options on Your Android Device

1. Go to **Settings** → **About Phone**
2. Find **Build Number** (usually at the bottom)
3. Tap **Build Number** 7 times until you see "You are now a developer!"

### Step 2: Enable USB Debugging

1. Go back to **Settings** → **Developer Options** (now visible)
2. Enable **USB Debugging**
3. Enable **Stay Awake** (optional, keeps screen on while charging)

### Step 3: Connect Your Device

1. Connect your Android device to your computer via USB cable
2. On your phone, you may see a prompt asking "Allow USB debugging?" - tap **Allow**
3. Check the box "Always allow from this computer" if you want to skip this prompt in the future

### Step 4: Verify Connection

Run this command in your terminal:
```bash
flutter devices
```

You should see your device listed. Example:
```
SM-G950F (mobile) • ce12171c • android-arm64 • Android 10 (API 29)
```

### Step 5: Run Your App

```bash
flutter run
```

Or specify the device:
```bash
flutter run -d <device-id>
```

---

## For iOS Devices (macOS only)

**Note:** iOS development requires macOS and Xcode. Since you're on Windows, you cannot test on physical iOS devices directly. You would need:
- A Mac computer, OR
- Use an iOS Simulator on a Mac, OR
- Use cloud-based iOS testing services

### If you have access to macOS:

1. Install **Xcode** from the App Store
2. Open Xcode and accept the license agreement
3. Install additional components when prompted
4. Connect your iOS device via USB
5. Trust the computer on your device when prompted
6. In Xcode, go to **Window** → **Devices and Simulators**
7. Select your device and click "Use for Development"
8. Run `flutter devices` to verify

---

## Alternative: Using Android Emulator

If you don't have a physical device, you can use an Android emulator:

### Step 1: Create an Android Virtual Device (AVD)

1. Open **Android Studio**
2. Go to **Tools** → **Device Manager** (or click the device manager icon)
3. Click **Create Device**
4. Select a device (e.g., Pixel 5)
5. Select a system image (e.g., Android 13 - API 33)
6. Click **Finish**

### Step 2: Start the Emulator

1. In Android Studio Device Manager, click the **Play** button next to your AVD
2. Or run from terminal:
```bash
flutter emulators --launch <emulator-id>
```

### Step 3: Verify and Run

```bash
flutter devices
flutter run
```

---

## Troubleshooting

### Android Device Not Detected

1. **Check USB Connection:**
   - Try a different USB cable
   - Try a different USB port
   - Make sure USB debugging is enabled

2. **Install USB Drivers:**
   - For Samsung: Install Samsung USB drivers
   - For other devices: Install manufacturer-specific drivers
   - Or use Google USB Driver from Android SDK Manager

3. **Check ADB:**
   ```bash
   adb devices
   ```
   If device shows as "unauthorized", check your phone for the USB debugging authorization prompt.

4. **Restart ADB:**
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

### Device Shows as Offline

- Disconnect and reconnect the USB cable
- Revoke USB debugging authorizations on your phone and reconnect
- Restart ADB (commands above)

### Flutter Can't Find Device

- Make sure the device is unlocked
- Make sure USB debugging is enabled
- Try running `flutter doctor -v` to see detailed diagnostics

---

## Quick Commands Reference

```bash
# List all connected devices
flutter devices

# List available emulators
flutter emulators

# Launch a specific emulator
flutter emulators --launch <emulator-id>

# Run app on specific device
flutter run -d <device-id>

# Run app and let Flutter choose device
flutter run

# Check Flutter setup
flutter doctor

# Detailed Flutter diagnostics
flutter doctor -v
```

---

## Wireless Debugging (Android 11+)

For Android 11 and above, you can connect wirelessly:

1. Connect your device via USB first
2. Enable **Wireless debugging** in Developer Options
3. Pair your device using the pairing code
4. Once paired, you can disconnect USB and use WiFi

---

## Next Steps

Once your device is connected:
1. Run `flutter devices` to verify
2. Run `flutter run` to launch your app
3. Use hot reload (press `r` in terminal) for quick testing
4. Use hot restart (press `R` in terminal) for full restart



