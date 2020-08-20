---
attachments: [icon_small.png]
tags: [Intermediate, Notebooks/Tutorial]
title: '08 - Linking Attachments, Notes, Tags and Searches'
created: '2018-12-27T18:53:01.510Z'
modified: '2020-07-05T12:00:00.000Z'
---

# 08 - Linking Attachments, Notes, Tags and Searches

Sometimes, like when writing a tutorial for a note-taking app :wink:, you may need to link to other notes or embed a few attachments. Noteless makes this easy for you.

## Attachments

Attachments can be rendered inline, linked to, and linked to via a button. The `@attachment` token is used for this.

##### Syntax

```markdown
![Icon](@attachment/icon_small.png)
[Icon](@attachment/icon_small.png)
```

##### Result

![Icon](@attachment/icon_small.png)

[Icon](@attachment/icon_small.png)

## Notes

Notes can be linked to, and linked to via a button. The `@note` token is used for this. Wiki-style links are supported too.

##### Syntax

```markdown
[Tags](@note/06 - Tags.md)
[[06 - Tags]]
```

##### Result

[Tags](@note/06 - Tags.md)

[[06 - Tags]]

## Tags

Tags can be linked to, and linked to via a button. The `@tag` token is used for this.

##### Syntax

```markdown
[Basics](@tag/Basics)
```

##### Result

[Basics](@tag/Basics)

## Searches

Searches can be linked to, and linked to via a button. The `@search` token is used for this.

##### Syntax

```markdown
[linking](@search/linking)
```

##### Result

[linking](@search/linking)
