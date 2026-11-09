---
name: Preview scope
description: Constraints when adapting the imported Android app to Replit's browser preview.
---

Keep the imported Flutter structure; browser preview support is not permission to
rewrite the application in another framework or activate the optional AI module.

**Why:** The user requested running the imported project, not migrating it. Its
offline/privacy promises would be weakened by substituting browser cloud speech
or external OCR for Android's local integrations.

**How to apply:** Keep text checks local. Explicitly explain unavailable native
features in the browser, preserve native implementations, and do not claim web
verification proves Android integrations work. Bundle Hindi font coverage rather
than relying on browser/system fallback fonts, which can render missing glyphs.
