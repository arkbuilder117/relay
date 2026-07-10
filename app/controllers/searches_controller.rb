class SearchesController < ApplicationController
  def index
    @query   = params[:q].to_s.strip
    @results = @query.present? ? UseCases::SearchTracks.new.call(@query) : []
  end
end
