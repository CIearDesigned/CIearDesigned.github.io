# RoBazaar — Roblox creator marketplace

This website is a static GitHub Pages app powered by **Firebase Authentication, Cloud Firestore, and Firebase Storage**. There are no mock listings or seed data: only listings published by signed-in users are fetched from Firestore.

## Firebase setup

1. Open Firebase Console and create/select the Firebase project you already use.
2. In **Project settings → Your apps**, create/select a Web app and copy its web configuration into `firebase-config.js`. Replace every `YOUR_...` placeholder. Firebase web API keys are public identifiers; never put service-account private keys or other secrets in this file.
3. Enable **Authentication → Sign-in method → Email/Password**.
4. Create a **Cloud Firestore** database in production mode. Publish the contents of `firestore.rules` as its Firestore security rules.
5. Enable **Firebase Storage** and publish the contents of `storage.rules` as Storage security rules. Confirm that Storage is enabled for your project/billing plan.
6. In Authentication → Settings → Authorized domains, make sure `cieardesigned.github.io` is allowed.
7. Commit the Firebase config and setup files, then wait for GitHub Pages to redeploy. The storefront shows an empty state until actual creators post listings.

Firebase client configuration is not a security boundary: Firestore and Storage rules enforce access. Never deploy admin SDK/service account credentials to GitHub Pages.

## Features

- Firebase email/password signup/login. Creator profile documents live in Firestore.
- Real-time Firestore marketplace feed, search, genre/currency/price filters, dual Robux/USD prices, and creator links.
- Authenticated listing form, thumbnail uploads, optional `.rbxl`/`.rbxlx` file uploads to Firebase Storage.
- Real-time, per-listing Firestore comments. Comments by the listing owner receive a Seller badge.
- USD checkout can redirect to a seller-provided Stripe Payment Link. Robux instructions are displayed for manual gamepass/group payout arrangements. This static site does not implement payment escrow, secure order fulfillment, or payment verification; add a trusted backend before handling real payments.
- Roblox usernames and links are self-reported. A public account is not Roblox verification. Never share Roblox passwords.

## Data model

- `profiles/{uid}` — creator Roblox handle/link.
- `gameListings/{listingId}` — title, description, genre, asset type, accepted currencies, prices, seller identity, image/file Storage paths and active status.
- `gameListings/{listingId}/comments/{commentId}` — user identity, body, and server timestamp.
- Storage paths: `users/{uid}/listings/{listingId}/...`.

No records are seeded. Listing creation and comment posting require Firebase Authentication; public reads are constrained to active listings and their comments by the provided rules.
