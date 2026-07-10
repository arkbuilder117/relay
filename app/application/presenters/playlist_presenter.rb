module Presenters
  class PlaylistPresenter
    attr_reader :playlist

    def initialize(playlist)
      @playlist = playlist
    end

    def match_percentage_label = "#{playlist.match_percentage}%"

    def unmatched_tracks
      playlist.track_results.select(&:unmatched?)
    end
  end
end
