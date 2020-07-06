---
tags: [Basics, Notebooks/Tutorial]
title: 01 - The Data Directory
created: '2018-12-16T21:43:52.886Z'
modified: '2020-07-05T12:00:00.000Z'
---

# 01 - The Data Directory

The data directory is where all your notes and attachments will be stored, it has the following structure:

```
/path/to/your/data_directory
├─┬ attachments
│ ├── foo.ext
│ ├── bar.ext
│ └── …
└─┬ notes
  ├── foo.md
  ├── bar.md
  └── …
```

## Features

- The data directory gives you freedom since your notes are never locked into some sort of proprietary database, all your files use sane formats and are easily accessible and portable.
- You can also change the data directory at any time via `Settings -> Data Directory`, the current content won't be copied over to the new one.
- You can edit your notes/attachments without even using Noteless, all changes you make to them will be reflected here (after a quick refresh). In fact you could also import a Markdown note simply by copying it into the `notes` directory.

## Advanced Features

The data directory allows you to leverage third-party tools to have powerful features like synchronization, versioning and encryption, we'll talk about those in the [advanced](@tag/Advanced) sections.
