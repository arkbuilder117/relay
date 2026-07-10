# Relay

Relay makes it easy to move your music between Spotify and Apple Music. Migrate playlists, or just look up whether a song exists on both platforms — no account required for search.

---

## Features

### Song Search
Find any track and see which platforms it's on — no account needed.

- Search by song name, artist, or album
- Results show album artwork, artist, album name, duration, and explicit flag
- Each result shows Spotify and Apple Music availability with direct links
- Powered by Spotify's catalog and Apple Music's catalog APIs

**URL:** `/search`

---

### Playlist Migration
Migrate playlists between Spotify and Apple Music in either direction.

**Supported directions:**
- Spotify → Apple Music
- Apple Music → Spotify

**How it works:**
1. Pick a direction
2. Connect both accounts (Spotify via OAuth, Apple Music via MusicKit JS)
3. Select which playlists to migrate
4. Relay runs the migration in the background and shows live progress

**Matching strategy:** Tracks are matched by ISRC (International Standard Recording Code) — a universal identifier that works across platforms. Tracks without a valid ISRC, or not found on the destination platform, are marked as unmatched.

**Live updates:** Migration progress is streamed to the browser in real time via ActionCable and Turbo Streams. Each playlist result appears as it completes.

**After migration:** Both platform credentials are automatically removed from the database on successful completion.

---

### Account Management
Connect and disconnect streaming accounts from the `/migration/connect` page.

- **Spotify** — OAuth 2.0 authorization. Tokens are refreshed automatically before expiry.
- **Apple Music** — MusicKit JS authorization in the browser. Only the Music User Token is stored.
- Both accounts can be disconnected at any time via a Disconnect button on the connect page.

All tokens (`access_token`, `refresh_token`, `music_user_token`) are encrypted at rest.

---

## Stack

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails 8 |
| Database | PostgreSQL |
| Background jobs | Sidekiq + Redis |
| Real-time | ActionCable + Turbo Streams |
| Frontend | Hotwire (Turbo + Stimulus) |
| HTTP client | Faraday |
| Auth | bcrypt (accounts), omniauth-spotify (OAuth) |

---

## Running Locally

**Prerequisites:** Docker (for Postgres and Redis), Ruby 3.4+

```bash
# Install dependencies
bundle install

# Start Postgres and Redis
docker-compose up db redis

# Set up the database
rails db:create db:migrate

# Start the app
rails server

# Start background job processor (separate terminal)
bundle exec sidekiq
```

App runs at `http://localhost:3000`.

---

## Environment Variables

Copy `.env.example` to `.env` and fill in:

```bash
# Spotify — from developer.spotify.com
SPOTIFY_CLIENT_ID=
SPOTIFY_CLIENT_SECRET=

# Apple Music — from developer.apple.com
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=   # full contents of your .p8 file

# Redis (defaults work for local Docker setup)
REDIS_URL=redis://localhost:6379/1

# Rails
RAILS_MASTER_KEY=
```

`DATABASE_URL` is only needed in production. For local development the database name in `config/database.yml` is used directly.
