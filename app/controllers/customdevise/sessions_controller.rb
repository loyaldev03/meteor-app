class Customdevise::SessionsController < Devise::SessionsController
  before_filter :skip_login_page, only: :new

  # https://www.pivotaltracker.com:/story/show/129702681/comments/161496975
  def skip_login_page
    return unless Rails.env.production?
    unless ['://cs.', '://api.'].any? { |subdomain| request.original_url.include?(subdomain) }
      Rails.logger.info "Customdevise::SkipLoginPage: Login page skipped - Original URL: #{request.original_url}"
      render file: "#{Rails.root}/public/401", status: 401, layout: false, formats: [:html]
    end
  end
end
