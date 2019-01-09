require 'ruby-jmeter'

UNBOUNCE_LANDING_PAGE = 'https://products.onmc.com/load-test/?utm_campaign=sloop&utm_source=nascar&utm_medium=referral&utm_content=loadtest&audience=loadtest&campaign_id=65c04a3a4hn4h4s2'.freeze

test do
  cache clear_each_iteration: true

  cookies

  threads count: 100, duration: 1200 do
    transaction 'landing_page' do
      visit name: 'Landing Page', url: UNBOUNCE_LANDING_PAGE
    end
  end
end.jmx(file: 'landing_page.jmx')
