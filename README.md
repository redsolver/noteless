# Noteless

A markdown note-taking app for mobile devices (Android only at the moment, iOS is planned).

Compatible with notes saved in [Notable](https://notable.app/)

## Download

[https://github.com/redsolver/noteless/releases](https://github.com/redsolver/noteless/releases)

## Important Changes in Version 0.2.0 

The app has been renamed from `Notable Mobile` to `Noteless` on 02.07.2020.

If you used an earlier Alpha Version, you need to uninstall the old one and install one of the new APKs (Don't forget to backup your notes!)

This is because the app also has a new package name: `net.redsolver.noteless`.

## Screenshots

<p>
  <img src="https://user-images.githubusercontent.com/30355444/63541799-2c55f680-c51f-11e9-9137-a9fe6bc4b80e.png" width="250">
  <img src="https://user-images.githubusercontent.com/30355444/63541801-2c55f680-c51f-11e9-89a0-050867563cee.png" width="250">
  <img src="https://user-images.githubusercontent.com/30355444/63541802-2cee8d00-c51f-11e9-9b74-0ca1d1b48ef1.png" width="250">
</p>

<p>
  <img src="https://user-images.githubusercontent.com/30355444/63541804-2cee8d00-c51f-11e9-95c7-e0fdca7aaa9b.png" width="250">
  <img src="https://user-images.githubusercontent.com/30355444/63541805-2cee8d00-c51f-11e9-8833-73e6525a0511.png" width="250">
  <img src="https://user-images.githubusercontent.com/30355444/63541806-2d872380-c51f-11e9-95b8-56dbacf044f7.png" width="250">
</p>

<p>
  <img src="https://user-images.githubusercontent.com/30355444/63541809-2d872380-c51f-11e9-80e2-b56e975d76f0.png" width="250">
  <img src="https://user-images.githubusercontent.com/30355444/63541810-2d872380-c51f-11e9-8904-247d5da359a8.png" width="250">
  <img src="https://user-images.githubusercontent.com/30355444/63541812-2d872380-c51f-11e9-972a-55c9469c4045.png" width="250">
</p>

## Changelog

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
