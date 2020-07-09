# Noteless

A markdown note-taking app for mobile devices (Android only at the moment, iOS is planned).

Compatible with notes saved in [Notable](https://notable.app/)

## Download

[https://github.com/redsolver/noteless/releases](https://github.com/redsolver/noteless/releases)

## Screenshots

<p>
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen1.png" width="250">
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen2.png" width="250">
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen3.png" width="250">
</p>

<p>
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen4.png" width="250">
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen5.png" width="250">
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen6.png" width="250">
</p>

<p>
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen7.png" width="250">
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen8.png" width="250">
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen9.png" width="250">
</p>

<p>
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen10.png" width="250">
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen11.png" width="250">
  <img src="https://github.com/redsolver/noteless/raw/master/screenshots/screen12.png" width="250">
</p>

## Important Changes in Version 0.2.0 

The app has been renamed from `Notable Mobile` to `Noteless` on 02.07.2020.

If you used an earlier Alpha Version, you need to uninstall the old one and install one of the new APKs (Don't forget to backup your notes!)

This is because the app also has a new package name: `net.redsolver.noteless`.

Also I decided to drop support for syncing notes directly via the app because there are alternative options which work a lot better.

I recommend using an external data directory and a third-party sync app for Android like [Syncthing](https://syncthing.net/), Nextcloud Sync or FolderSync for other cloud services.

## Changelog

### 0.3.1

- Fixed editor content not loading without front matter data

### 0.3.0

- Fully reworked editor with syntax highlighting and a new keyboard toolbar to help with common Markdown operations
- Added fallback to file metadata if front matter data is missing

### 0.2.1

- Disabled the preview feature on Android 4.4 KitKat devices.
- Removed WebDav sync

### 0.2.0

- Renamed the app to "Noteless"
- New app icon
- Reworked tutorial notes
- The Editor/Preview Mode Switcher is now the default option
- New error handling: When an exception occurs while reading a note, the note is skipped and the errors are shown as "virtual notes".
- Show loading dialog when changing external data directory
- Fixed issue with using an external data directory on Android Q (10)
- QOL Improvements (Autofocus, Small design improvements)

### 0.1.8

- Added support for subdirectories
- Added options to restore notes from trash
  - With the swipe actions of a note
  - With the "Restore from trash" button in the multi select options
- Added option to create a logfile for sync 
- Added experimental option to enable virtual folder tags
- Minor theme fixes

### 0.1.7

- Fixed white flash when loading note preview

### 0.1.6

- Added option to use a mode switcher for editor and preview

### 0.1.5

- Added feature to add and remove attachments
- Searching in content of notes
  - Enabled by default
  - Can be disabled in settings
  - Can get slow with more than 2000 notes

### 0.1.4

- Added KaTeX and mhchem support
- Added option to change accent color
- Added note swipe actions (trash, delete, pin and favorite)

### 0.1.3

- Fixed webdav sync

### 0.1.2

- Fixed sync when using different data directory

### 0.1.1

- Added option to select data directory on device
- Moved multi select options to bottom app bar
- Pressing back while being in select mode cancels it
- Added option to recreate all tutorial notes and attachments in settings
- Updated info page
- Dark Theme now supports markdown preview

### 0.1.0

- Select multiple notes by long pressing
- After entering select mode, add notes to the selection by tapping them
- Select or unselect all notes in the select menu
- Favorite/Unfavorite multiple notes at once
- Pin/Unpin multiple notes at once
- Add and remove tags to multiple notes at once
- Move to Trash and delete multiple notes at once

### 0.0.9

- Dark Theme
- Confirmation Dialogs

## License

The app is MIT licensed.
