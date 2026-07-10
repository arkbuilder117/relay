class ErrorsController < ApplicationController
  def not_found
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end

  def unprocessable
    render file: Rails.root.join("public/422.html"), status: :unprocessable_entity, layout: false
  end

  def internal_server_error
    render file: Rails.root.join("public/500.html"), status: :internal_server_error, layout: false
  end
end
