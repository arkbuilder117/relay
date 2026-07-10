# Relay — Product Specification

Relay is a web application that bridges Spotify and Apple Music. It lets users migrate playlists and liked songs between the two platforms, search for music to see where it's available, and share cross-platform links so anyone can open a song on whichever platform they use.

This spec is the authoritative description of all features — current and planned. It is the source of truth for designers, developers, and stakeholders. Technical implementation details (API calls, database schema, Rails architecture) live in `CLAUDE.md`.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [User Personas](#2-user-personas)
3. [Feature Inventory](#3-feature-inventory)
4. [Information Architecture](#4-information-architecture)
5. [Navigation](#5-navigation)
6. [Pages](#6-pages)
   - [Landing Page](#landing-page)
   - [Sign Up](#sign-up)
   - [Sign In](#sign-in)
   - [Music Search](#music-search)
   - [Share Page (v2)](#share-page-v2)
   - [Step 1 — Pick Direction](#step-1--pick-direction)
   - [Step 2 — Connect Accounts](#step-2--connect-accounts)
   - [Step 3 — Select Playlists](#step-3--select-playlists)
   - [Step 4 — Migration Status](#step-4--migration-status)
   - [Migration History (v2)](#migration-history-v2)
7. [User Flows](#7-user-flows)
8. [Track Matching Strategy](#8-track-matching-strategy)
9. [Data Overview](#9-data-overview)
10. [Roadmap](#10-roadmap)

---

## 1. Product Overview

Relay solves a real problem for music fans: your library is on one platform but you want it on another — or you want to share a song with someone who uses a different service.

**What it does:**

- **Migrate** — Move playlists and liked songs from Spotify to Apple Music (or reverse), with live progress updates in the browser
- **Search** — Look up any track or album and see whether it's on Spotify, Apple Music, or both, with direct links to open it
- **Share** — Generate a single URL that shows a song on both platforms so anyone can click through to their preferred service

**What it does not do:**

- No music playback
- No playlist editing after migration
- No recurring / scheduled sync
- No social features, followers, or activity feeds
- No support for other platforms (YouTube Music, Tidal, etc.)

**Auth model:**
- Song search and share pages are fully public — no account required
- Migration and history require a Relay account (email + password)

---

## 2. User Personas

**The Switcher**
Moving from Spotify to Apple Music (or vice versa) and wants to bring their entire library — playlists, liked songs, everything. They run Relay once and they're done. Their primary concern is completeness: did everything migrate?

**The Dual Subscriber**
Has active accounts on both platforms. Migrates playlists occasionally to keep libraries in sync. Cares about migration history so they don't accidentally re-migrate something they already moved.

**The Recommender**
Wants to send a song to a friend who uses a different platform. Searches for the track, copies the Relay share link, and sends it. Their friend clicks through to whichever platform they prefer. No account needed for either person.

**The Researcher**
Considering a platform switch and wants to know whether their favourite albums or artists are available on the other side. Uses song and album search to spot-check availability before committing.

---

## 3. Feature Inventory

### v1 — Current

| # | Feature | Description | Auth required |
|---|---|---|---|
| 1 | Song search | Search tracks by name/artist; see availability on Spotify and Apple Music with direct links | No |
| 2 | Playlist migration | Migrate playlists between platforms in either direction; live progress in browser | Yes |
| 3 | Account management | Connect / disconnect Spotify (OAuth) and Apple Music (MusicKit JS) accounts | Yes |

### v2 — Planned

| # | Feature | Description | Auth required |
|---|---|---|---|
| 4 | Album search | Search albums alongside tracks in the same search bar | No |
| 5 | Cross-platform share link | Shareable URL showing a song on both platforms with direct links to each | No |
| 6 | Liked songs migration | Migrate saved/liked songs in addition to playlists | Yes |
| 7 | Migration history | Browse past migrations: status, playlists moved, track match rates | Yes |
| 8 | Fuzzy matching | Fall back to title + artist search when ISRC matching fails, improving match rate | Background — no UI change |

---

## 4. Information Architecture

```
/                           → Root: migration wizard Step 1 (logged in) or Landing (logged out)
/search                     → Music search — public
/share/:token               → Cross-platform share page — public [v2]
/sign-up                    → Create account
/sign-in                    → Log in
/migration/connect          → Step 2: connect accounts
/migration/playlists        → Step 3: select playlists
/migration/:id              → Step 4: live migration status
/history                    → Past migrations [v2]
```

Unauthenticated users visiting `/` see a landing page. After sign-in they're redirected back to `/` which now shows the migration wizard.

---

## 5. Navigation

The top navigation bar appears on every page.

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay           Find music          Sign in   Sign up    │
└─────────────────────────────────────────────────────────────────┘
```

**Logged out:**
- Left: "Relay" logo link → `/`
- Centre: "Find music" link → `/search`
- Right: "Sign in" (text link) + "Sign up" (filled button)

**Logged in:**
- Left: "Relay" logo link → `/`
- Centre: "Find music" link → `/search`
- Right: user's email (greyed out) + "Sign out" (text button) + "History" link [v2]

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay   Find music      History   noah@... Sign out      │
└─────────────────────────────────────────────────────────────────┘
```

Flash messages (success / error) appear directly below the nav bar, full width, and dismiss automatically after 4 seconds or on click.

---

## 6. Pages

---

### Landing Page

**URL:** `/`
**Access:** Public (logged-out users only — logged-in users see Step 1 directly)
**Purpose:** Explain what Relay does and get visitors into the product.

#### ASCII Mockup

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay           Find music          Sign in   Sign up    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│              Move your music.                                   │
│              Anywhere you listen.                               │
│                                                                 │
│   Migrate playlists and liked songs between Spotify and Apple   │
│   Music in minutes. Or find out if a song is on both platforms  │
│   before you switch.                                            │
│                                                                 │
│         [ Get started — it's free ]   [ Find a song ]          │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────┐  ┌─────────────────┐  ┌───────────────┐  │
│   │  Migrate        │  │  Search         │  │  Share        │  │
│   │                 │  │                 │  │               │  │
│   │  Move playlists │  │  Find any track │  │  One link,    │  │
│   │  & liked songs  │  │  or album and   │  │  both         │  │
│   │  between Spotify│  │  see where it   │  │  platforms.   │  │
│   │  and Apple Music│  │  lives.         │  │               │  │
│   └─────────────────┘  └─────────────────┘  └───────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Prose Description

**Hero section** — full-width, centred. Two-line headline in large type. A two-sentence subheading that explains the product. Two CTA buttons side by side: primary "Get started — it's free" → `/sign-up`; secondary ghost button "Find a song" → `/search`.

**Feature cards** — a row of three cards below the hero, each with a short title and one-sentence description:
1. **Migrate** — Move playlists & liked songs between Spotify and Apple Music
2. **Search** — Find any track or album and see where it lives
3. **Share** — One link, both platforms

No pricing section, no testimonials, no footer beyond the three cards. Keep it minimal.

---

### Sign Up

**URL:** `/sign-up`
**Access:** Public

#### ASCII Mockup

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay           Find music          Sign in   Sign up    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    Create your account                          │
│                                                                 │
│              ┌────────────────────────────┐                     │
│   Email      │                            │                     │
│              └────────────────────────────┘                     │
│              ┌────────────────────────────┐                     │
│   Password   │                            │                     │
│              └────────────────────────────┘                     │
│                                                                 │
│              [ Create account ]                                 │
│                                                                 │
│              Already have an account? Sign in                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Prose Description

Centred single-column form. Email field, password field (minimum 8 characters), submit button. Inline validation on submit: show field-level error messages if email is already taken or password is too short. On success, log the user in and redirect to `/` (Step 1 of migration wizard). Link to sign in at the bottom.

---

### Sign In

**URL:** `/sign-in`
**Access:** Public

#### ASCII Mockup

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay           Find music          Sign in   Sign up    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                       Sign in                                   │
│                                                                 │
│              ┌────────────────────────────┐                     │
│   Email      │                            │                     │
│              └────────────────────────────┘                     │
│              ┌────────────────────────────┐                     │
│   Password   │                            │                     │
│              └────────────────────────────┘                     │
│                                                                 │
│              [ Sign in ]                                        │
│                                                                 │
│              Don't have an account? Sign up                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Prose Description

Same layout as sign-up. On failed auth, show a single error message ("Email or password is incorrect") — never reveal which field is wrong. On success, redirect to the page the user was trying to reach, or to `/` if they came directly.

---

### Music Search

**URL:** `/search`
**Access:** Public
**Purpose:** Search for tracks and albums (v2) and see their availability on Spotify and Apple Music.

#### ASCII Mockup — Empty State

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay           Find music          Sign in   Sign up    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Find music                                                    │
│   Search for any track or album and see which platforms it's on.│
│                                                                 │
│   ┌──────────────────────────────────────────┐ [ Search ]      │
│   │  Artist, song, or album...               │                  │
│   └──────────────────────────────────────────┘                  │
│                                                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### ASCII Mockup — Search Results (v1: tracks only)

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay           Find music          Sign in   Sign up    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Find music                                                    │
│   Search for any track or album and see which platforms it's on.│
│                                                                 │
│   ┌──────────────────────────────────────────┐ [ Search ]      │
│   │  Bohemian Rhapsody                        │                  │
│   └──────────────────────────────────────────┘                  │
│                                                                 │
│   5 results                                                     │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ [img]  Bohemian Rhapsody               4:55              │  │
│   │        Queen · A Night at the Opera                      │  │
│   │                              [ ● Spotify ] [ ■ Apple Music ] │
│   └──────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ [img]  Bohemian Rhapsody (Remaster)     4:59    E        │  │
│   │        Queen · Greatest Hits                             │  │
│   │                              [ ● Spotify ] [ Not on Apple Music ] │
│   └──────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ [img]  Bohemian Rhapsody (Live)         5:55             │  │
│   │        Queen · Live at Wembley                           │  │
│   │                              [ ● Spotify ] [ ■ Apple Music ] │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### ASCII Mockup — Search Results (v2: tracks + albums)

```
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ TRACKS                                                   │  │
│   ├──────────────────────────────────────────────────────────┤  │
│   │ [img]  Bohemian Rhapsody               4:55              │  │
│   │        Queen · A Night at the Opera                      │  │
│   │                              [ ● Spotify ] [ ■ Apple Music ] │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │ ALBUMS                                                   │  │
│   ├──────────────────────────────────────────────────────────┤  │
│   │ [img]  A Night at the Opera            1975 · 12 tracks  │  │
│   │        Queen                                             │  │
│   │                              [ ● Spotify ] [ ■ Apple Music ] │
│   └──────────────────────────────────────────────────────────┘  │
```

#### Prose Description

**Search bar** — single text input occupying most of the page width, with a "Search" button. Submitting navigates to the same URL with `?q=` appended (GET request). The query is preserved in the input on results load.

**Results count** — small grey text showing "N results" appears above the list when results exist.

**Track result card** — each card contains:
- Album artwork thumbnail (56×56px, rounded corners). Replaced by a grey placeholder if unavailable.
- Track title in semibold. If the track is explicit, an "E" badge appears inline with the title.
- Artist name on the second line (grey).
- Album name on the third line (lighter grey, smaller).
- Duration (right-aligned, small grey text).
- Platform buttons (far right):
  - If on Spotify: green pill button with Spotify logo + "Spotify" — links directly to the track on Spotify in a new tab.
  - If not on Spotify: muted grey text "Not on Spotify".
  - If on Apple Music: red pill button with Apple Music logo + "Apple Music" — links directly to the track on Apple Music in a new tab.
  - If not on Apple Music: muted grey text "Not on Apple Music".

**Share icon (v2)** — a share/link icon on each result opens or generates the share URL for that track. See Share Page below.

**Album result card (v2)** — same card layout but shows:
- Album artwork
- Album title
- Artist
- Release year + track count (e.g. "1975 · 12 tracks")
- Platform buttons (same Spotify / Apple Music pill pattern)

**Results are grouped (v2):** "TRACKS" section first, "ALBUMS" section below. Each section has its own count.

**Empty state:** If the query returns no results, show "No results found for `[query]`." in grey text.

**No state (no query yet):** Show only the search bar with placeholder text. No results area visible.

**Loading state:** While the search request is in flight, the Search button should be disabled and show a spinner or "Searching…" label.

**Search is public** — the page renders without authentication. No login prompt or redirect.

---

### Share Page (v2)

**URL:** `/share/:token`
**Access:** Public
**Purpose:** A sharable page for a single track showing it on both platforms. Anyone with the link can open it on whichever platform they prefer.

#### ASCII Mockup

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay           Find music          Sign in   Sign up    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                  ┌──────────────────────┐                       │
│                  │                      │                       │
│                  │   [album artwork]    │                       │
│                  │                      │                       │
│                  └──────────────────────┘                       │
│                                                                 │
│                  Bohemian Rhapsody                              │
│                  Queen                                          │
│                  A Night at the Opera · 1975                    │
│                                                                 │
│         ┌────────────────────┐  ┌────────────────────┐         │
│         │  ● Open on Spotify │  │  ■ Open on Apple   │         │
│         │                    │  │    Music            │         │
│         └────────────────────┘  └────────────────────┘         │
│                                                                 │
│         Not on Apple Music? Here are some alternatives:         │
│         (only appears when track isn't on one platform)         │
│                                                                 │
│         ─────────────────────────────────────────────          │
│         Share this song:  [ Copy link ]                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Prose Description

**Token** — the share token is a short, opaque identifier (e.g. ISRC or a short hash). The page looks up the track metadata server-side using the ISRC and renders the page. No account needed to view.

**Artwork** — large, centred album art (ideally 300×300px or larger).

**Track info** — title in large type, artist below, album + year below that.

**Platform buttons** — two large, full-width-ish buttons:
- Green "Open on Spotify" — if the track is on Spotify
- Red "Open on Apple Music" — if the track is on Apple Music
- If not available on a platform: the button is replaced with greyed-out text "Not available on [Platform]"

**"Copy link" button** — copies the current page URL to clipboard. On copy, the button label briefly changes to "Copied!" and reverts.

**How share links are created:** On the search results page (v2), each track result has a share icon. Clicking it either copies the share URL directly (if the ISRC is known) or redirects to `/share/:isrc`. The ISRC is the stable identifier that powers the cross-platform lookup on the share page.

---

### Step 1 — Pick Direction

**URL:** `/` (logged-in users) or accessible via "Get started" from the landing page
**Access:** Must be logged in
**Purpose:** The user chooses which direction they want to migrate.

#### ASCII Mockup

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay   Find music      History   noah@... Sign out      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Migrate your music                                            │
│   Choose a direction to get started.                            │
│                                                                 │
│   ┌───────────────────────────┐  ┌───────────────────────────┐  │
│   │                           │  │                           │  │
│   │  ● → ■                   │  │  ■ → ●                   │  │
│   │                           │  │                           │  │
│   │  Spotify                  │  │  Apple Music              │  │
│   │  → Apple Music            │  │  → Spotify                │  │
│   │                           │  │                           │  │
│   │  Move your Spotify        │  │  Move your Apple Music    │  │
│   │  playlists and liked      │  │  playlists and liked      │  │
│   │  songs to Apple Music.    │  │  songs to Spotify.        │  │
│   │                           │  │                           │  │
│   └───────────────────────────┘  └───────────────────────────┘  │
│                                                                  │
│                              [ Continue → ]                     │
│                              (disabled until a card is selected) │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Selected State

```
│   ┌───────────────────────────┐  ┌───────────────────────────┐  │
│   │ ✓ selected                │  │                           │  │
│   │  ● → ■                   │  │  ■ → ●                   │  │
│   │  (card has indigo border) │  │                           │  │
│   │  Spotify → Apple Music    │  │  Apple Music → Spotify    │  │
│   └───────────────────────────┘  └───────────────────────────┘  │
│                              [ Continue → ]                     │
│                              (now enabled)                      │
```

#### Prose Description

Two large, clickable cards side by side. Each card shows the migration direction with platform logos (or abbreviations), a title, and a one-sentence description.

**Interaction:** Clicking a card selects it (adds a visual indicator — highlighted border or checkmark overlay). The "Continue" button becomes enabled. Clicking the other card swaps the selection. A hidden form field tracks the chosen direction value (`spotify_to_apple` or `apple_to_spotify`).

**On submit:** Navigates to Step 2 (`/migration/connect?direction=...`).

**If the user is not logged in:** The page redirects to `/sign-in` with a `return_to` parameter so they come back here after authenticating.

---

### Step 2 — Connect Accounts

**URL:** `/migration/connect?direction=...`
**Access:** Must be logged in
**Purpose:** The user connects their Spotify and Apple Music accounts before the migration can run.

#### ASCII Mockup — Both Disconnected

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay   Find music      History   noah@... Sign out      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Connect your accounts                                         │
│   You need both accounts connected to migrate.                  │
│                                                                 │
│   ┌───────────────────────────┐  ┌───────────────────────────┐  │
│   │                           │  │                           │  │
│   │  Spotify                  │  │  Apple Music              │  │
│   │                           │  │                           │  │
│   │  ○ Not connected          │  │  ○ Not connected          │  │
│   │                           │  │                           │  │
│   │  [ Connect Spotify ]      │  │  [ Connect Apple Music ]  │  │
│   │                           │  │                           │  │
│   └───────────────────────────┘  └───────────────────────────┘  │
│                                                                  │
│                              [ Continue → ]                     │
│                              (disabled)                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### ASCII Mockup — Spotify Connected

```
│   ┌───────────────────────────┐  ┌───────────────────────────┐  │
│   │  Spotify                  │  │  Apple Music              │  │
│   │                           │  │                           │  │
│   │  ✓ Connected              │  │  ○ Not connected          │  │
│   │                           │  │                           │  │
│   │  [ Disconnect ]           │  │  [ Connect Apple Music ]  │  │
│   └───────────────────────────┘  └───────────────────────────┘  │
│                              [ Continue → ]                     │
│                              (still disabled — need Apple Music) │
```

#### ASCII Mockup — Both Connected

```
│   ┌───────────────────────────┐  ┌───────────────────────────┐  │
│   │  Spotify                  │  │  Apple Music              │  │
│   │                           │  │                           │  │
│   │  ✓ Connected              │  │  ✓ Connected              │  │
│   │                           │  │                           │  │
│   │  [ Disconnect ]           │  │  [ Disconnect ]           │  │
│   └───────────────────────────┘  └───────────────────────────┘  │
│                                                                  │
│                              [ Continue → ]                     │
│                              (now enabled)                      │
```

#### Prose Description

**Spotify card:**
- Not connected: shows a "Connect Spotify" button that starts the OAuth flow (full-page redirect to Spotify's authorisation screen). After authorising, Spotify redirects back to the app and the card updates to "✓ Connected" with a "Disconnect" button.
- Connected: shows "✓ Connected" in green. Shows a "Disconnect" button that removes the stored Spotify credentials and reloads the page with the card reset to disconnected state.
- Cancelling the Spotify OAuth screen returns the user to this page without an error message — treated as a no-op.

**Apple Music card:**
- Not connected: shows a "Connect Apple Music" button. Clicking it initialises MusicKit JS in the browser and triggers the Apple Music authorisation popup (no full-page redirect). On success the Music User Token is submitted to the server and the card updates to "✓ Connected".
- Connected: same pattern as Spotify — "✓ Connected" + "Disconnect" button.
- If the authorisation popup is dismissed or fails, the button resets to its original state without an error.

**Continue button:** Disabled until both accounts show as connected. On click, navigates to Step 3.

**Direction is preserved:** The `direction` query parameter carries forward through this step so Step 3 knows which platform is the source.

**Both accounts can remain connected between sessions.** If the user visits Step 2 and both are already connected, they can proceed immediately.

---

### Step 3 — Select Playlists

**URL:** `/migration/playlists`
**Access:** Must be logged in with both accounts connected
**Purpose:** The user selects which playlists (and optionally liked songs) to include in the migration.

#### ASCII Mockup — Spotify → Apple Music

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay   Find music      History   noah@... Sign out      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Select playlists to migrate                                   │
│   Migrating from Spotify → Apple Music                          │
│                                                                 │
│   [ Select all ]  [ Deselect all ]            3 selected        │
│                                                                 │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│   │ ✓        │ │ ✓        │ │          │ │ ✓        │          │
│   │ [cover]  │ │ [cover]  │ │ [cover]  │ │ [cover]  │          │
│   │          │ │          │ │          │ │          │          │
│   │ Chill    │ │ Road Trip│ │ Workout  │ │ Late     │          │
│   │ Vibes    │ │ 2024     │ │ Mix      │ │ Nights   │          │
│   │ 45 songs │ │ 82 songs │ │ 30 songs │ │ 12 songs │          │
│   └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ☐  Also migrate my liked songs (1,204 songs)           │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│                              [ Start migration → ]             │
│                              (enabled when ≥1 item selected)   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Prose Description

**Source label** — a subtitle confirms the migration direction so the user knows what they're looking at.

**Playlist grid** — fetched from the source platform. Each card shows:
- Playlist cover art (square thumbnail, rounded corners). Grey placeholder if none.
- Playlist name (truncated if too long).
- Track count ("N songs").
- A checkbox or selection state (selected = highlighted border + checkmark in corner).
- Clicking anywhere on the card toggles selection.

**Select all / Deselect all** — text buttons above the grid. "N selected" count updates in real time.

**Liked songs (v2)** — a row below the playlist grid with a checkbox. Label shows "Also migrate my liked songs (N songs)" where N comes from the source platform API. If the count is unavailable, show "Also migrate my liked songs". This checkbox is independent of the playlist selection.

**Start migration button** — disabled when nothing is selected (0 playlists and liked songs unchecked). Enabled as soon as at least one playlist or liked songs is selected. Shows `data-turbo-submits-with="Starting..."` to prevent double-submit. On click, POSTs to create the migration and redirects to Step 4.

**Empty state:** If the user has no playlists on the source platform, show: "No playlists found on Spotify." with a suggestion to check their account.

---

### Step 4 — Migration Status

**URL:** `/migration/:id`
**Access:** Must be logged in and own this migration
**Purpose:** Show live progress of the migration as it runs in the background.

#### ASCII Mockup — In Progress

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay   Find music      History   noah@... Sign out      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Migration in progress                      ● Running          │
│   Spotify → Apple Music                                         │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  Summary                                                 │  │
│   │  3 playlists  ·  137 songs  ·  89% matched               │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ✓  Chill Vibes                  45/45  ████████████ 100%│  │
│   │     45 matched  ·  0 unmatched                           │  │
│   └──────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ✓  Road Trip 2024               78/82  ██████████░░ 95% │  │
│   │     78 matched  ·  4 unmatched            ▾ Show 4 songs │  │
│   └──────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ◌  Workout Mix                  — pending               │  │
│   └──────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ◌  Late Nights                  — pending               │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### ASCII Mockup — Completed

```
│   Migration complete                         ✓ Done             │
│   Spotify → Apple Music                                         │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  Summary                                                 │  │
│   │  4 playlists  ·  169 songs  ·  92% matched               │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│   [ Start another migration ]                                   │
│                                                                 │
```

#### ASCII Mockup — Unmatched Tracks Expanded

```
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ✓  Road Trip 2024               78/82  ██████████░░ 95% │  │
│   │     78 matched  ·  4 unmatched            ▴ Hide songs   │  │
│   │                                                          │  │
│   │     Songs not found on Apple Music:                      │  │
│   │       • Midnight Drive — The Weekend Project             │  │
│   │       • Open Road — Indie Band Unreleased                │  │
│   │       • Coastal Highway — Lo-Fi Artist                   │  │
│   │       • Desert Song — Regional Only Release              │  │
│   └──────────────────────────────────────────────────────────┘  │
```

#### Prose Description

**Status badge** — top right. "● Running" (pulsing dot) while in progress; "✓ Done" (green) on completion; "✗ Failed" (red) if the job errors.

**Summary bar** — shows totals that update in real-time: number of playlists, total songs, and overall match percentage.

**Playlist result rows** — each playlist appears as a row as soon as it finishes processing. Rows appear via Turbo Stream — the user sees them appear one by one without a page reload.

Each completed playlist row shows:
- Checkmark icon
- Playlist name
- "X/Y" matched count
- A progress bar filling from left to right (green portion = matched, white/grey = unmatched)
- Percentage
- If any unmatched: "Show N songs" toggle link

Pending playlists are shown as placeholder rows with a spinner icon and "— pending".

**Unmatched tracks (collapsible):** Clicking "Show N songs" expands a list of track names + artists that couldn't be matched. Clicking again collapses it. Label toggles between "Show N songs" and "Hide songs".

**Live updates:** The page subscribes to a Turbo Stream channel. As each playlist finishes, the server pushes an update that appends the playlist result row and updates the summary. No polling.

**Completion state:** When the migration finishes, the status badge updates to "✓ Done", the summary shows final numbers, and a "Start another migration" button appears below the summary. Both platform credentials are automatically deleted from the database on successful completion (security measure — credentials aren't stored beyond what's needed).

**Failed state:** If the migration job encounters an unrecoverable error, the status badge shows "✗ Failed" and a brief failure reason is shown. The user can start a new migration.

**Access control:** Only the user who started the migration can view this page. Other users get a 404.

---

### Migration History (v2)

**URL:** `/history`
**Access:** Must be logged in
**Purpose:** Browse all past migrations for the current user.

#### ASCII Mockup

```
┌─────────────────────────────────────────────────────────────────┐
│  Relay   Find music      History   noah@... Sign out      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Migration history                                             │
│                                                                 │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ✓ Done     Spotify → Apple Music       Jun 11, 2026     │  │
│   │             4 playlists · 169 songs · 92% matched        │  │
│   │                                              [ View ]    │  │
│   └──────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ✓ Done     Apple Music → Spotify       May 3, 2026      │  │
│   │             2 playlists · 54 songs · 100% matched        │  │
│   │                                              [ View ]    │  │
│   └──────────────────────────────────────────────────────────┘  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ✗ Failed   Spotify → Apple Music       Apr 18, 2026     │  │
│   │             Apple Music account disconnected              │  │
│   │                                              [ View ]    │  │
│   └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│   [ Start a new migration ]                                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Prose Description

A chronological list (newest first) of all migrations for the logged-in user.

Each row shows:
- Status badge (Done / Running / Failed)
- Direction (e.g. "Spotify → Apple Music")
- Date completed (or started, if still running)
- Summary: "N playlists · N songs · N% matched"
- For failed migrations: the failure reason instead of match stats
- "View" link to the migration's detail page (`/migration/:id`)

**Empty state:** "No migrations yet. Ready to start?" with a link to `/` (Step 1).

**Running migration:** If a migration is currently in progress, it appears at the top with a pulsing status indicator. Clicking "View" takes the user to the live status page.

---

## 7. User Flows

### Flow A — First-Time Migration (Spotify → Apple Music)

```
1.  User visits streamshift.com
2.  Landing page — clicks "Get started — it's free"
3.  Sign-up page — enters email + password
4.  Step 1 — selects "Spotify → Apple Music" card, clicks Continue
5.  Step 2 — clicks "Connect Spotify", authorises on Spotify's OAuth screen, returns
6.  Step 2 — clicks "Connect Apple Music", approves MusicKit JS popup, card updates
7.  Step 2 — both connected → clicks Continue
8.  Step 3 — reviews playlists, checks "Also migrate my liked songs", clicks Start
9.  Step 4 — watches live progress as playlists complete one by one
10. Step 4 — migration complete; "Start another migration" button appears
```

### Flow B — Return User Migration

```
1.  User visits streamshift.com
2.  Step 1 shown immediately (already logged in)
    → if accounts still connected from last time, may skip to Step 3
3.  Selects direction, connects any missing accounts
4.  Picks playlists → migrates
```

### Flow C — Search Only (No Account)

```
1.  User visits streamshift.com or clicks "Find music" in nav
2.  Music search page — types query
3.  Results show availability on each platform with direct links
4.  User clicks a platform button → opens track on that platform in new tab
```

### Flow D — Share a Song (v2)

```
1.  User is on the search page, finds a track
2.  Clicks the share icon on the result
3.  Share URL is copied to clipboard (or user is taken to /share/:isrc)
4.  User pastes URL in a message to a friend
5.  Friend opens /share/:isrc — sees the track on both platforms
6.  Friend clicks "Open on Apple Music" (or Spotify)
→  No account required for either the sharer or the recipient
```

### Flow E — Disconnect an Account

```
1.  User is on Step 2 (connect accounts) with one or both accounts connected
2.  Clicks "Disconnect" on a connected account
3.  Credentials are deleted from the database
4.  Card resets to "Not connected" state
5.  Continue button disables if an account was disconnected
```

---

## 8. Track Matching Strategy

Relay matches tracks across platforms using ISRC codes (International Standard Recording Code) — a universal identifier embedded in most commercial tracks.

### v1: ISRC Exact Match

1. For each track on the source platform, extract its ISRC.
2. Look up that ISRC in the destination platform's catalog.
3. If found: mark as **matched** (`match_strategy: 'isrc'`), add to the new playlist.
4. If not found (or no ISRC available): mark as **unmatched** (`match_strategy: 'none'`), record it but skip adding it to the playlist.

Match outcomes are recorded per track in the database and surfaced in the migration status UI.

### v2: Fuzzy Matching (Fallback)

When ISRC matching fails, fall back to a title + artist text search on the destination platform.

1. Clean the track title: strip "feat.", "Remaster", "(Live)", common suffixes.
2. Search the destination catalog by `"{cleaned title}" "{artist}"`.
3. If a confident match is found: mark as **fuzzy matched** (`match_strategy: 'fuzzy'`).
4. If still not found: mark as **unmatched**.

Fuzzy matching improves match rates for tracks that exist on both platforms but with slightly different metadata (e.g. different ISRC per territory, re-releases).

---

## 9. Data Overview

Relay stores the minimum data necessary to run migrations:

| Data | Where | Notes |
|---|---|---|
| User email + password | `users` table | Password stored as bcrypt hash |
| Spotify access token, refresh token, token expiry | `spotify_accounts` | Encrypted at rest; deleted after successful migration |
| Apple Music user token, storefront | `apple_music_accounts` | Encrypted at rest; deleted after successful migration |
| Migration direction, status, totals | `migrations` | Retained for history |
| Per-playlist results | `migration_playlist_results` | Retained for history |
| Per-track results (title, artist, ISRC, match status) | `migration_track_results` | Retained for history |

**Token lifecycle:** OAuth tokens are stored only as long as needed to run a migration. After a successful migration, both platform credentials are deleted. Users can also manually disconnect at any time.

**Encryption:** All tokens are encrypted at rest using Rails Active Record Encryption.

---

## 10. Roadmap

### v1 (Current)

- [x] Song search (no auth required)
- [x] Spotify → Apple Music playlist migration
- [x] Apple Music → Spotify playlist migration
- [x] Account management (connect / disconnect)
- [x] Live migration status via WebSockets

### v2 (Planned)

- [ ] Album search alongside tracks in the same search bar
- [ ] Cross-platform share links (`/share/:isrc`)
- [ ] Liked songs migration (Spotify liked songs ↔ Apple Music library)
- [ ] Migration history page
- [ ] Fuzzy matching fallback (title + artist search when ISRC fails)

### Out of Scope

The following will not be built:

- Other platforms (YouTube Music, Tidal, Amazon Music, Deezer)
- Music playback
- Playlist editing after migration
- Scheduled or recurring sync
- Social features (sharing profiles, following users)
- Mobile app

---

*Last updated: June 2026*
