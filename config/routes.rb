Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "migrations#index"

  get "/search", to: "searches#index", as: :search

  resources :migrations, only: [ :index, :create, :show ] do
    member do
      post :retry
    end
    collection do
      get  :connect
      get  :playlists
      get  :history
    end
  end

  resource  :session,       only: [ :new, :create, :destroy ]
  resources :registrations, only: [ :new, :create ]

  get "/auth/failure", to: "auth/spotify#failure"

  namespace :auth do
    get    "/spotify/callback", to: "spotify#callback"
    delete "/spotify",          to: "spotify#destroy"
    post   "/apple_music",      to: "apple_music#create"
    delete "/apple_music",      to: "apple_music#destroy"
  end

  mount OmniAuth::Builder.new { provider :spotify, ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"], scope: "playlist-read-private playlist-read-collaborative playlist-modify-private playlist-modify-public user-library-read user-library-modify" } => "/auth"

  match "/404", to: "errors#not_found",            via: :all
  match "/422", to: "errors#unprocessable",         via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
