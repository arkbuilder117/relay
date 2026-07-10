module AppleMusic
  module Mappers
    class TrackMapper
      def self.from_api(item)
        attrs = item["attributes"] || {}
        AppleMusic::Entities::AppleMusicTrack.new(
          id:     item["id"],
          title:  attrs["name"],
          artist: attrs["artistName"],
          isrc:   attrs["isrc"],
          album:  attrs["albumName"]
        )
      end
    end
  end
end
