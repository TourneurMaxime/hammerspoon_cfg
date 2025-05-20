
# Hammerspoon Smart Window Layout Manager

A powerful **Hammerspoon** script to **automatically organize windows** based on your screen configuration. Includes **layout save/restore**, **keyboard shortcuts**, **menu bar controls**, and optional **Spotify notifications**.

---

## 📦 Main Features

### 🖥️ Automatic Window Management
- Automatically moves applications to the **left**, **center**, or **right** screen based on predefined lists.
- Automatically resizes (maximizes) windows, excluding specific apps (Messages, WhatsApp, etc.).
- Triggers automatically on **startup**, **screen change**, or **wake from sleep**.

### 💾 Layout Save & Restore
- Save the current window positions and sizes tied to the current screen setup.
- Restore them exactly—even after reboots or screen changes.

### ⌨️ Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| `cmd + shift + G` | Reorganize windows |
| `cmd + shift + M` | Maximize windows |

### 🧭 Menu Bar Integration
Icon: `™` (Can be changed)

Options available:
- 💾 Save current layout
- ⏮️ Restore saved layout
- 🔁 Organize & Maximize windows
- 🔄 Organize only
- 🔼 Maximize only
- ♻️ Reload Hammerspoon config
- 🛠️ Open Hammerspoon console
- ❌ Quit Hammerspoon

---

## ⚙️ Setup Instructions

### 1. Install Hammerspoon
Download here: https://www.hammerspoon.org/

### 2. Add the script
Create a file named `init.lua` in:
```sh
~/.hammerspoon/
```

Paste the full script inside that file.

### 3. Reload Hammerspoon
Launch Hammerspoon, open the console (`cmd + 4`) and click "Reload Config", or use the `™ > ♻️ Reload` menu option.

---

## 📁 Screen & Application Assignment

This script assumes a triple-screen setup: **left**, **center**, and **right**.

### 📌 App-to-Screen Mapping

#### 🖥️ Center Screen
an array containing a list of paths to apps like `/Applications/Path/To/App.app` or `/System/Applications/App.app` or `/Users/your_user_name/Applications/App.app`

#### 👉 Right Screen
An array containing a list of paths to apps like Center Screen array

#### 🚫 Apps Excluded from Maximization
These apps will not be maximized
An array containing a list of paths to apps

#### 🚫 Apps Excluded from Auto Move
These apps won’t be automatically moved
An array containing a list of paths to apps

---

## 🧠 How It Works

### 📡 Event Detection
The script reacts to:
- Screen connections/disconnections
- Waking from sleep
- Session lock/unlock
- App launches and new windows

For each event:
- Windows are auto-organized
- Windows are maximized unless excluded
- Placement follows predefined rules

### 🧠 Layout Logic
Each layout is saved with a unique key based on the UUID of your screen setup. This means different layouts can be saved and restored depending on your current monitor configuration.

---

## 🛠️ Author Notes

This script is optimized for a power-user workflow with:
- Triple-screen setups
- Advanced window placement rules
- Persistent layout management
- Minimal manual intervention

Feel free to adapt the app lists and screen behavior to match your preferences.
