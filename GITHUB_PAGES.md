# Publish Satark_2 on GitHub Pages

The linked GitHub ZIP is the original Android project. The Replit workspace
contains additional web-preview changes; this Pages-ready bundle includes those
changes plus `.github/workflows/deploy-satark-pages.yml`.

## One-time setup

1. Extract the bundle at the root of a local clone of
   `stavansomaiya/construct`, replacing its `Satark_2` folder and adding the
   included `.github` folder. Do not extract it inside `Satark_2`.
2. In the GitHub repository, open **Settings → Pages** and set the build and
   deployment source to **GitHub Actions**.
3. Commit and push the updated `Satark_2` folder and workflow to `main`.
4. Open the repository's **Actions** tab and wait for **Deploy Satark to GitHub
   Pages** to finish. Subsequent pushes to `main` that change `Satark_2` deploy
   automatically.

The deployment builds the Flutter app at `/construct/`, matching the repository
name. The repository must be public for the intended free Pages hosting. The
app is static: message checks run in the browser, and saved history/contacts
stay in that browser. Android OCR, offline dictation, and share-sheet features
are not provided by the web build.

This deployment bundle contains the current web-enabled app source, not an APK
and not Git commit history. Its included workflow only runs after you add and
push the files to GitHub; it does not publish from Replit on its own.
