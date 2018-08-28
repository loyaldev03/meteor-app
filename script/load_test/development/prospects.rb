require 'ruby-jmeter'

UNBOUNCE_LANDING_PAGE       = 'https://membertest.onmc.com/load-test'.freeze

PHOENIX_DOMAIN              = 'https://dev.affinitystop.com'.freeze
PHOENIX_AUTHENTICATION_KEY  = '9dZZenei6hUPyTboo7Kg'.freeze
PHOENIX_CAMPAIGN_ID         = 'd9140f62f73e2ff557c3dfa9f2f4e80c39'.freeze

PRODUCT_SKU                 = 'LOADTESTVARIANT1'.freeze

DRUPAL_DOMAIN               = 'https://dev-sac2.pantheonsite.io'.freeze

test do
  cache clear_each_iteration: true

  cookies

  threads count: 60, duration: 1200 do
    transaction 'prospects_creation' do
      visit name: 'Unbounce - Landing Page visit', url: UNBOUNCE_LANDING_PAGE

      header [name: 'Content-Type', value: 'application/json']
      post name: 'Unbounce - Load Campaign Data',
           url: PHOENIX_DOMAIN + '/api/v1/campaigns/' + PHOENIX_CAMPAIGN_ID + '/metadata',
           raw_body: format('{"api_key": "%s"}', PHOENIX_AUTHENTICATION_KEY) do
        assert contains: PRODUCT_SKU
      end
      think_time 5_000, 2_000

      header [name: 'Content-Type', value: 'application/json']
      post name: 'Phoenix - Landing submit',
           url: PHOENIX_DOMAIN + '/checkout/submit',
           raw_body: format('{"first_name": "SACTest ${__RandomString(5,abcdefghijklmnopqrstuvwxyz)}",
                              "last_name": "SACTest ${__RandomString(5,abcdefghijklmnopqrstuvwxyz)}",
                              "email": "load_test+${__RandomString(9,abcdefghijklmnopqrstuvwxyz)}@mailinator.com",
                              "address": "Fake Av ${__RandomString(10,abcdefghijklmnopqrstuvwxyz)}",
                              "city": "Fake",
                              "state": "North Carolina",
                              "zip": "12345",
                              "phone": "${__Random(100,999)}-${__Random(100,999)}-${__Random(1000,9999)}",
                              "landing_id": "%s",
                              "product_sku": "%s",
                              "api_key": "%s"}', PHOENIX_CAMPAIGN_ID, PRODUCT_SKU, PHOENIX_AUTHENTICATION_KEY) do
        extract name: 'prospectToken',
                xpath: '//input[@type="hidden"][@id="credit_card_prospect_token"]/@value',
                tolerant: true
      end

      visit name: 'Phoenix - Checkout page',
            url: PHOENIX_DOMAIN + format('/checkout/new/?campaign_id=%s&token=%s&api_key=%s', PHOENIX_CAMPAIGN_ID, '${prospectToken}', PHOENIX_AUTHENTICATION_KEY) do
        assert contains: 'Quick and Easy Checkout'
      end

      think_time 1_000, 2_000
    end
  end
end.jmx(file: 'prospects.jmx')
