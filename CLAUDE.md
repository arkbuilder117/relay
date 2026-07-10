# CLAUDE.md

---

## Development Commands

```bash
# Setup
bundle install
rails db:create db:migrate

# Run the app (requires Docker for Postgres + Redis)
docker-compose up db redis      # start dependencies
rails server                    # http://localhost:3000
bundle exec sidekiq             # background job processor

# Or run everything via Docker
docker-compose up

# Tests
rails test                      # all tests
rails test test/path/to/test.rb # single file
rails test test/path/to/test.rb:42 # single test by line number

# Linting / type checks (add rubocop to Gemfile if desired)
bundle exec rubocop

# Console
rails console

# Database
rails db:migrate
rails db:rollback
```

---

## Project Overview

Relay lets users migrate their playlists and liked songs between Spotify and Apple Music
in both directions. A user connects both accounts, selects which playlists to move, and the
service matches tracks via ISRC codes (universal song identifiers) and recreates the playlists
on the destination platform. Results are shown live in the browser as the migration runs.

**Stack**
- Ruby on Rails (latest stable)
- PostgreSQL
- Sidekiq + Redis (background jobs)
- Hotwire: Turbo + Stimulus (frontend)
- ActionCable (real-time status via WebSockets)
- Faraday (HTTP client)
- bcrypt (authentication)
- jwt gem (Apple Music developer token generation)
- omniauth-spotify (Spotify OAuth)

---

## Architecture — Domain-Driven Design

Organise all code under `app/domains/` with five bounded contexts.
Do NOT use the default Rails `app/models` + `app/services` flat structure.

```
app/
├── domains/
│   ├── identity/         # users, auth, sessions
│   ├── spotify/          # everything Spotify-specific
│   ├── apple_music/      # everything Apple Music-specific
│   ├── catalog/          # platform-agnostic track/ISRC concepts
│   └── migration/        # core domain — orchestrating migrations
├── application/
│   ├── use_cases/        # entry points called from controllers
│   └── presenters/
├── infrastructure/
│   ├── http/             # raw Faraday wrappers
│   └── persistence/      # ActiveRecord records + mappers
└── interfaces/
    ├── controllers/
    └── serializers/
```

Each layer only knows about the layer below it. Controllers never touch Faraday.
Domain services never touch ActiveRecord directly.

---

## Full Directory Structure

```
app/
├── domains/
│   ├── identity/
│   │   └── services/
│   │       └── authentication_service.rb
│   │
│   ├── spotify/
│   │   ├── entities/
│   │   │   ├── spotify_playlist.rb
│   │   │   └── spotify_track.rb
│   │   ├── services/
│   │   │   ├── auth_service.rb           # OAuth token exchange + refresh
│   │   │   ├── playlist_creator.rb       # create playlist + add tracks
│   │   │   ├── playlist_fetcher.rb       # fetch user playlists
│   │   │   ├── track_fetcher.rb          # fetch tracks within a playlist
│   │   │   └── track_searcher.rb         # search tracks by ISRC
│   │   └── mappers/
│   │       └── track_mapper.rb           # raw API response → SpotifyTrack entity
│   │
│   ├── apple_music/
│   │   ├── entities/
│   │   │   ├── apple_music_playlist.rb
│   │   │   └── apple_music_track.rb
│   │   ├── services/
│   │   │   ├── developer_token_service.rb  # generates JWT from Apple private key
│   │   │   ├── playlist_creator.rb         # creates playlist + adds tracks
│   │   │   ├── playlist_fetcher.rb         # fetch user playlists
│   │   │   ├── track_fetcher.rb            # fetch tracks within a playlist
│   │   │   └── track_searcher.rb           # find tracks by ISRC
│   │   └── mappers/
│   │       └── track_mapper.rb
│   │
│   ├── catalog/
│   │   ├── services/
│   │   │   ├── isrc_matcher.rb           # ISRC validation
│   │   │   └── fuzzy_matcher.rb          # title cleaning (v2 — not used in matching yet)
│   │   └── value_objects/
│   │       └── isrc.rb                   # validated ISRC value object
│   │
│   └── migration/
│       └── services/
│           ├── migration_orchestrator.rb      # coordinates full migration
│           └── playlist_migration_service.rb  # handles one playlist at a time
│
├── application/
│   ├── use_cases/
│   │   ├── start_migration.rb
│   │   └── fetch_user_playlists.rb
│   └── presenters/
│       ├── migration_presenter.rb
│       └── playlist_presenter.rb
│
├── infrastructure/
│   └── http/
│       ├── spotify_client.rb
│       └── apple_music_client.rb
│
├── models/                          # ActiveRecord models (Rails convention)
│   ├── user.rb
│   ├── spotify_account.rb
│   ├── apple_music_account.rb
│   ├── migration.rb
│   ├── migration_playlist_result.rb
│   └── migration_track_result.rb
│
├── controllers/
│   ├── auth/
│   │   ├── spotify_controller.rb
│   │   └── apple_music_controller.rb
│   ├── migrations_controller.rb
│   ├── registrations_controller.rb
│   └── sessions_controller.rb
│
├── jobs/
│   └── migration_job.rb
│
├── views/
│   ├── layouts/
│   │   └── application.html.erb
│   ├── migrations/
│   │   ├── index.html.erb           # Step 1 — pick direction
│   │   ├── connect.html.erb         # Step 2 — connect accounts
│   │   ├── playlists.html.erb       # Step 3 — select playlists
│   │   ├── show.html.erb            # Step 4 — live migration status
│   │   ├── _playlist_result.html.erb
│   │   ├── _summary.html.erb
│   │   ├── _status_badge.html.erb
│   │   └── _actions.html.erb
│   ├── sessions/
│   │   └── new.html.erb             # Login
│   ├── registrations/
│   │   └── new.html.erb             # Sign up
│   └── shared/
│       ├── _nav.html.erb
│       └── _flash.html.erb
│
└── javascript/
    └── controllers/
        ├── application.js
        ├── direction_controller.js   # card selection on step 1
        ├── apple_music_controller.js # MusicKit JS auth on step 2
        └── playlist_controller.js    # select all / deselect all on step 3
```

---

## Database Schema

Generate migrations for the following tables in this order.

### users
```ruby
create_table :users do |t|
  t.string  :email,           null: false
  t.string  :password_digest, null: false
  t.timestamps
end
add_index :users, :email, unique: true
```

### spotify_accounts
```ruby
create_table :spotify_accounts do |t|
  t.references :user,             null: false, foreign_key: true
  t.string     :spotify_id,       null: false
  t.string     :display_name
  t.string     :access_token,     null: false
  t.string     :refresh_token,    null: false
  t.datetime   :token_expires_at, null: false
  t.timestamps
end
add_index :spotify_accounts, :user_id, unique: true
add_index :spotify_accounts, :spotify_id, unique: true
```

### apple_music_accounts
```ruby
create_table :apple_music_accounts do |t|
  t.references :user,             null: false, foreign_key: true
  t.string     :music_user_token, null: false
  t.string     :storefront,       null: false, default: 'us'
  t.timestamps
end
add_index :apple_music_accounts, :user_id, unique: true
```

### migrations
```ruby
create_table :migrations do |t|
  t.references :user,      null: false, foreign_key: true
  t.string     :direction, null: false   # 'spotify_to_apple' | 'apple_to_spotify'
  t.string     :status,    null: false, default: 'pending'
  t.integer    :total_playlists,   default: 0
  t.integer    :total_tracks,      default: 0
  t.integer    :matched_tracks,    default: 0
  t.integer    :unmatched_tracks,  default: 0
  t.text       :failure_reason
  t.datetime   :started_at
  t.datetime   :completed_at
  t.timestamps
end
add_index :migrations, :user_id
add_index :migrations, :status
```

### migration_playlist_results
```ruby
create_table :migration_playlist_results do |t|
  t.references :migration,   null: false, foreign_key: true
  t.string     :source_id,   null: false
  t.string     :dest_id
  t.string     :name,        null: false
  t.string     :status,      null: false, default: 'pending'
  t.integer    :total_tracks,    default: 0
  t.integer    :matched_count,   default: 0
  t.integer    :unmatched_count, default: 0
  t.timestamps
end
add_index :migration_playlist_results, :migration_id
```

### migration_track_results
```ruby
create_table :migration_track_results do |t|
  t.references :migration_playlist_result, null: false, foreign_key: true
  t.string  :isrc
  t.string  :title,          null: false
  t.string  :artist,         null: false
  t.string  :source_id,      null: false
  t.string  :dest_id
  t.string  :match_status,   null: false   # 'matched' | 'unmatched' | 'fuzzy_matched'
  t.string  :match_strategy                # 'isrc' | 'fuzzy' | 'none'
  t.timestamps
end
add_index :migration_track_results, :migration_playlist_result_id
add_index :migration_track_results, :isrc
add_index :migration_track_results, :match_status
```

**Token encryption** — add to the two account models:
```ruby
# spotify_account.rb (ActiveRecord model)
encrypts :access_token
encrypts :refresh_token

# apple_music_account.rb (ActiveRecord model)
encrypts :music_user_token
```

---

## External APIs

### Spotify
- API Reference: `https://developer.spotify.com/documentation/web-api`
- Auth: OAuth 2.0 Authorization Code flow via `omniauth-spotify` gem
- Required scopes: `playlist-read-private playlist-read-collaborative`
- Base URL: `https://api.spotify.com/v1`
- ISRC location in response: `track.external_ids.isrc`
- Token expiry: 1 hour — must refresh using the refresh token before expiry
- Pagination: playlists use `limit=50`, tracks use `limit=100`, follow `next` URL

Token refresh logic — call this before every Spotify API request:
```ruby
def self.fresh_token(spotify_account)
  return spotify_account.access_token unless spotify_account.token_expires_at <= 5.minutes.from_now
  response = exchange_refresh_token(spotify_account.refresh_token)
  spotify_account.update!(
    access_token:     response['access_token'],
    token_expires_at: Time.current + response['expires_in'].seconds
  )
  spotify_account.access_token
end
```

### Apple Music
- API Reference: `https://developer.apple.com/documentation/applemusicapi`
- Requires an Apple Developer account ($99/yr) — credentials from env vars
- Two tokens required on every API call:
  - **Developer Token**: JWT you generate server-side from your Apple private key (.p8 file). Expires every 12 hours. Regenerate on demand, do NOT store in DB.
  - **Music User Token**: obtained client-side via MusicKit JS, stored in `apple_music_accounts`. Doesn't expire on a schedule but can be revoked — handle 401s by prompting reconnect.
- Base URL: `https://api.music.apple.com/v1`
- ISRC search endpoint: `GET /v1/catalog/{storefront}/songs?filter[isrc]={isrc}`
- Batch ISRC lookup: comma-separated ISRCs, max 25 per request
- Rate limit: ~3 requests/sec — add `sleep 0.34` between requests or use retry with backoff
- Playlist track add limit: 100 tracks per call — batch additions accordingly

Developer token generation:
```ruby
require 'jwt'
private_key = OpenSSL::PKey::EC.new(ENV['APPLE_PRIVATE_KEY'])
headers = { kid: ENV['APPLE_KEY_ID'], alg: 'ES256' }
payload = { iss: ENV['APPLE_TEAM_ID'], iat: Time.now.to_i, exp: Time.now.to_i + 43200 }
JWT.encode(payload, private_key, 'ES256', headers)
```

---

## Track Matching Strategy

ISRC exact match only (v1). Tracks without a valid ISRC, or whose ISRC doesn't exist on the destination platform, are marked `unmatched`.

Track results record which strategy succeeded (`match_strategy` column): `'isrc'` or `'none'`.

---

## Migration Flow

1. User picks direction (Spotify → Apple Music or reverse)
2. User connects both accounts (Spotify via OAuth, Apple Music via MusicKit JS)
3. Source playlists are fetched and displayed — user selects which ones to migrate
4. `POST /migration` triggers `StartMigration` use case → enqueues `MigrationJob`
5. User is redirected to `/migration/:id/status`
6. `MigrationJob` runs in background via Sidekiq:
   - Fetches tracks from source playlists
   - Batches ISRC lookups against destination API (25 at a time)
   - Creates playlists on destination and adds matched tracks (unmatched tracks are recorded but skipped)
   - After each playlist completes, broadcasts a Turbo Stream update
   - On completion, broadcasts final status + summary
   - On successful completion, deletes both Spotify and Apple Music credentials from the DB
7. Status page receives live updates via ActionCable
8. User can manually disconnect either account at any time via `DELETE /auth/spotify` or `DELETE /auth/apple_music`

---

## Background Job

```ruby
# app/jobs/migration_job.rb
class MigrationJob < ApplicationJob
  queue_as :default

  def perform(migration_id, playlist_ids)
    migration    = Migrations::Repositories::MigrationRepository.new.find(migration_id)
    user         = Identity::Repositories::UserRepository.new.find(migration.user_id)
    orchestrator = Migrations::Services::MigrationOrchestrator.new(migration, user)

    orchestrator.on(:playlist_completed) do |result|
      Turbo::StreamsChannel.broadcast_append_to(
        "migration_#{migration.id}",
        target:  "playlist-results-list",
        partial: "migrations/playlist_result",
        locals:  { result: result }
      )
      migration.reload
      Turbo::StreamsChannel.broadcast_replace_to(
        "migration_#{migration.id}",
        target:  "migration-summary",
        partial: "migrations/summary",
        locals:  { migration: migration }
      )
    end

    orchestrator.run(playlist_ids)

    migration.reload
    Turbo::StreamsChannel.broadcast_replace_to(
      "migration_#{migration.id}",
      target:  "migration-status",
      partial: "migrations/status_badge",
      locals:  { migration: migration }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "migration_#{migration.id}",
      target:  "migration-actions",
      partial: "migrations/actions",
      locals:  { migration: migration }
    )
  end
end
```

---

## Frontend — Hotwire (Turbo + Stimulus)

**4-step wizard — all rendered server-side with Turbo Frames**

### Step 1: Pick Direction (`migration/index.html.erb`)
- Two clickable cards: "Spotify → Apple Music" and "Apple Music → Spotify"
- Stimulus `direction_controller` updates a hidden field and enables the Continue button
- On submit: `GET /migration/connect?direction=...`

### Step 2: Connect Accounts (`migration/connect.html.erb`)
- Wrapped in a `turbo_frame_tag "account-connections"`
- Spotify card: standard OAuth link with `data-turbo="false"` (full page redirect)
- Apple Music card: Stimulus `apple_music_controller` calls MusicKit JS `authorize()`, injects the returned Music User Token into a hidden field, and submits a form to `POST /auth/apple_music`
- Continue button is disabled until both accounts show as connected

### Step 3: Select Playlists (`migration/playlists.html.erb`)
- Grid of playlist cards with checkboxes
- Stimulus `playlist_controller` handles select all / deselect all / count display
- Submit button disabled when 0 playlists selected
- `data-turbo-submits-with="Starting..."` on the submit button

### Step 4: Live Status (`migration/status.html.erb`)
- `<%= turbo_stream_from "migration_#{@migration.id}" %>` at the top
- `turbo_frame_tag "migration-status"` — replaced when status changes
- `turbo_frame_tag "migration-summary"` — replaced after each playlist completes
- `turbo_frame_tag "playlist-results-list"` — rows appended as each playlist finishes
- `turbo_frame_tag "migration-actions"` — "Start another migration" button appears on completion
- Each playlist result shows: name, progress bar (match %), matched/total count, collapsible list of unmatched tracks

### Stimulus Controllers

**direction_controller.js**
```javascript
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["card", "input", "submit"]
  select(event) {
    this.cardTargets.forEach(card => card.classList.remove("selected"))
    event.currentTarget.classList.add("selected")
    this.inputTarget.value = event.currentTarget.dataset.value
    this.submitTarget.disabled = false
  }
}
```

**apple_music_controller.js**
```javascript
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["button", "form", "tokenField"]
  static values  = { developerToken: String }
  async authorize() {
    this.buttonTarget.textContent = "Connecting..."
    this.buttonTarget.disabled = true
    try {
      await MusicKit.configure({
        developerToken: this.developerTokenValue,
        app: { name: "Relay", build: "1.0" }
      })
      const music     = MusicKit.getInstance()
      const userToken = await music.authorize()
      this.tokenFieldTarget.value = userToken
      this.formTarget.requestSubmit()
    } catch (err) {
      this.buttonTarget.textContent = "Connect Apple Music"
      this.buttonTarget.disabled = false
    }
  }
}
```

**playlist_controller.js**
```javascript
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["checkbox", "count", "submit", "card"]
  selectAll()   { this.checkboxTargets.forEach(cb => cb.checked = true);  this.updateCount() }
  deselectAll() { this.checkboxTargets.forEach(cb => cb.checked = false); this.updateCount() }
  updateCount() {
    const checked = this.checkboxTargets.filter(cb => cb.checked).length
    this.countTarget.textContent = `${checked} selected`
    this.submitTarget.disabled = (checked === 0)
    this.checkboxTargets.forEach(cb => {
      cb.closest("[data-playlist-target='card']").classList.toggle("selected", cb.checked)
    })
  }
}
```

---

## Routes

```ruby
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "migrations#index"

  resources :migrations, only: [:index, :create, :show] do
    collection do
      get :connect
      get :playlists
    end
  end

  resource  :session,       only: [:new, :create, :destroy]
  resources :registrations, only: [:new, :create]

  namespace :auth do
    get    "/spotify/callback", to: "spotify#callback"
    delete "/spotify",          to: "spotify#destroy"
    post   "/apple_music",      to: "apple_music#create"
    delete "/apple_music",      to: "apple_music#destroy"
  end

  mount OmniAuth::Builder.new { provider :spotify, ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"], scope: "playlist-read-private playlist-read-collaborative" } => "/auth"
end
```

---

## Environment Variables

```bash
# Spotify
SPOTIFY_CLIENT_ID=
SPOTIFY_CLIENT_SECRET=

# Apple Music
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY=      # full contents of your .p8 file

# Rails
DATABASE_URL=
REDIS_URL=
RAILS_MASTER_KEY=
SECRET_KEY_BASE=
```

---

## Gemfile

```ruby
gem 'pg'
gem 'puma'
gem 'sidekiq'
gem 'redis'
gem 'faraday'
gem 'faraday-retry'
gem 'jwt'
gem 'bcrypt'
gem 'omniauth-spotify'
gem 'omniauth-rails_csrf_protection'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'hotwire-rails'
```

---

## Docker Setup

### Dockerfile
```dockerfile
FROM ruby:3.3.0
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client build-essential libpq-dev
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
```

### docker-compose.yml
```yaml
version: "3.8"
services:
  db:
    image: postgres:16
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  web:
    build: .
    command: rails server -b 0.0.0.0
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/streamshift_development
      REDIS_URL: redis://redis:6379/1

  sidekiq:
    build: .
    command: bundle exec sidekiq
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:password@db:5432/streamshift_development
      REDIS_URL: redis://redis:6379/1

volumes:
  postgres_data:
```

---

## Key Business Rules

- A user can only have one Spotify account and one Apple Music account connected at a time
- A migration can only be started if both accounts are connected
- Migrations run fully asynchronously — the HTTP request returns immediately with a 202
- If a Spotify token is expired or within 5 minutes of expiry, refresh it before any API call
- If an Apple Music API call returns 401, mark the account as disconnected and notify the user
- ISRC matching is the only matching strategy (v1) — tracks without a valid ISRC or not found on the destination are marked unmatched
- Apple Music ISRC batch lookups are capped at 25 ISRCs per request
- Apple Music playlist track additions are batched at 100 tracks per request
- Track results with `match_status: 'unmatched'` are shown in the UI under a collapsible section
- The developer token for Apple Music is never stored in the database — always generated fresh
- All OAuth tokens (`access_token`, `refresh_token`, `music_user_token`) are encrypted at rest using Rails `encrypts`
- Credentials are deleted from the DB on successful migration completion; users can also disconnect manually via the status page
- Use cases are stateless — all arguments are passed to `call`, nothing stored in `initialize`

---

## What NOT to Build (Out of Scope)

- No support for YouTube Music, Amazon Music, Deezer, Tidal, or any other platform
- No music playback
- No playlist editing after migration
- No scheduled / recurring sync between platforms
- No social features
- No mobile app — web only

---

## Potential v2 Improvements

- **Fuzzy matching** — fall back to title + artist search when ISRC matching fails. `Catalog::Services::FuzzyMatcher` already exists with `searchable_title` that strips "feat.", "Remaster", etc. Hook it into `resolve_track` in `PlaylistMigrationService` as a second tier before returning `[nil, nil]`. Also needs `search_by_title_artist` on both `Spotify::Services::TrackSearcher` and `AppleMusic::Services::TrackSearcher`.
- **Liked songs migration** — Spotify and Apple Music both expose a "library" / "liked songs" endpoint separate from playlists
- **Migration history** — let users view past migrations and their results
