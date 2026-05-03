---
name: adb-wireless
description: Connect to an Android phone via wireless ADB over Wi-Fi
allowed-tools:
  - Bash(adb *)
when_to_use: Use when the user asks to "connect adb wireless", "adb wifi", "wireless adb", "connect phone wirelessly", or wants to set up ADB over Wi-Fi. TRIGGER when user mentions wireless/adb together.
disable-model-invocation: true
---

# Wireless ADB Setup

Connect to an Android phone via ADB over Wi-Fi, eliminating the need for a USB cable after initial setup.

## Goal

Establish a working wireless ADB connection. Success: `adb devices` shows a connection with an IP:port entry.

## Steps

### 1. Check existing connections

Run `adb devices` and inspect the output:

- If a wireless connection (IP:port) is already listed → inform the user nothing needs to be done, skill is complete.
- If a USB device is listed → proceed to step 2.
- If no device is listed → ask the user to plug in a USB cable. Wireless setup requires an initial USB connection.

### 2. Query the phone's IP address

Run:
```
adb shell sh -c "ip a | grep 192.168"
```
Parse the output to extract the phone's IP (e.g. `192.168.71.6` from `inet 192.168.71.6/24 ...`).

**Artifacts**: The phone's Wi-Fi IP address.

### 3. Enable TCP/IP mode and connect

Run these two commands:
```
adb tcpip 5555
adb connect <phone_ip>
```
Replace `<phone_ip>` with the IP from step 2.

### 4. Verify and inform

Run `adb devices` to confirm the wireless connection appears. Tell the user they can now disconnect the USB cable and use `adb shell` to connect over Wi-Fi.
