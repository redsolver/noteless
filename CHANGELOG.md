# Changelog

## 1.4.6

- Added support for the Android 11 permission system
- Added option to sort tags alphabetically in the sidebar
- Improved compatibility with other Markdown-based note-taking tools (especially Dendron)
- Some small bug and theme fixes

## 1.3.1

- Added optional auto save option
- Added optional auto pairing of brackets/quotes (thanks to @RubbaBoy)
- Editor: Added option to move and restore note to/from trash
- Improved table styling (thanks to @davidebersani)
- Fixed some bugs

## 1.3.0

- Added feature to create a new note by sharing text with Noteless (#42)
- Adding an attachment to a note now automatically embeds it
- Improved blockquote styling (#44)
- Fixed some bugs

## 1.2.1

- Added Android App Shortcut for creating a new note from the homescreen
- Added proper table borders
- Fixed some bugs

## 1.2.0

- Added AsciiMath support
- Added Black/AMOLED theme
- Added experimental option: Automatic bullet points
- Added optional single line break syntax
- Increased height of editor toolbar
- Changed behaviour of list-button in editor toolbar
- Fixed image sizing in preview
- Fixed text field submitting when adding a tag

## 1.1.1

- Added support for spaces in links (#36)

## 1.1.0

- Made checkboxes in preview mode toggleable (#37)
- Added support for Wiki-style links like `[[My Note]]` (#38)

## 1.0.0

- First stable release
- Submitted the app to Google Play Store and F-Droid
- Updated to Flutter 1.20 (Better Performance and some bug fixes in the editor)

## 0.3.2

- Added F-Droid metadata

## 0.3.1

- Fixed editor content not loading without front matter data

## 0.3.0

- Fully reworked editor with syntax highlighting and a new keyboard toolbar to help with common Markdown operations
- Added fallback to file metadata if front matter data is missing

## 0.2.1

- Disabled the preview feature on Android 4.4 KitKat devices.
- Removed WebDav sync

## Important Changes in Version 0.2.0

The app has been renamed from `Notable Mobile` to `Noteless` on 02.07.2020.

If you used an earlier Alpha Version, you need to uninstall the old one and install one of the new APKs (Don't forget to backup your notes!)

This is because the app also has a new package name: `net.redsolver.noteless`.

Also I decided to drop support for syncing notes directly via the app because there are alternative options which work a lot better.

I recommend using an external data directory and a third-party sync app for Android like [Syncthing](https://syncthing.net/), Nextcloud Sync or FolderSync for other cloud services.

## 0.2.0

- Renamed the app to "Noteless"
- New app icon
- Reworked tutorial notes
- The Editor/Preview Mode Switcher is now the default option
- New error handling: When an exception occurs while reading a note, the note is skipped and the errors are shown as "virtual notes".
- Show loading dialog when changing external data directory
- Fixed issue with using an external data directory on Android Q (10)
- QOL Improvements (Autofocus, Small design improvements)

## 0.1.8

- Added support for subdirectories
- Added options to restore notes from trash
  - With the swipe actions of a note
  - With the "Restore from trash" button in the multi select options
- Added option to create a logfile for sync
- Added experimental option to enable virtual folder tags
- Minor theme fixes

## 0.1.7

- Fixed white flash when loading note preview

## 0.1.6

- Added option to use a mode switcher for editor and preview

## 0.1.5

- Added feature to add and remove attachments
- Searching in content of notes
  - Enabled by default
  - Can be disabled in settings
  - Can get slow with more than 2000 notes

## 0.1.4

- Added KaTeX and mhchem support
- Added option to change accent color
- Added note swipe actions (trash, delete, pin and favorite)

## 0.1.3

- Fixed webdav sync

## 0.1.2

- Fixed sync when using different data directory

## 0.1.1

- Added option to select data directory on device
- Moved multi select options to bottom app bar
- Pressing back while being in select mode cancels it
- Added option to recreate all tutorial notes and attachments in settings
- Updated info page
- Dark Theme now supports markdown preview

## 0.1.0

- Select multiple notes by long pressing
- After entering select mode, add notes to the selection by tapping them
- Select or unselect all notes in the select menu
- Favorite/Unfavorite multiple notes at once
- Pin/Unpin multiple notes at once
- Add and remove tags to multiple notes at once
- Move to Trash and delete multiple notes at once

## 0.0.9

- Dark Theme
- Confirmation Dialogs
