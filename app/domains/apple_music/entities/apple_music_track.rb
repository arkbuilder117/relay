module AppleMusic
  module Entities
    class AppleMusicTrack
      attr_reader :id, :title, :artist, :isrc, :album

      def initialize(id:, title:, artist:, isrc: nil, album: nil)
        @id     = id
        @title  = title
        @artist = artist
        @isrc   = isrc
        @album  = album
      end
    end
  end
end
