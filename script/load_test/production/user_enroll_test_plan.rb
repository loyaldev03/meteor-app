require 'ruby-jmeter'

UNBOUNCE_LANDING_PAGE       = 'http://products.onmc.com/load-test'.freeze

PHOENIX_DOMAIN              = 'https://checkout.onmc.com'.freeze
PHOENIX_AUTHENTICATION_KEY  = 'S6i8PVaB4WvW6R3n9z19'.freeze
PHOENIX_CAMPAIGN_ID         = '83e90b20c12f0d72d723010b80c59ee81'.freeze
PHOENIX_USER_ID             = '84226813de8c53703b1ca07d5b08c40e1'.freeze

PRODUCT_SKU                 = 'LOADTESTINGVARIANT1'.freeze

DRUPAL_DOMAIN               = 'https://www.onmc.com'.freeze

test do
  cache clear_each_iteration: true

  cookies

  threads count: 60, duration: 900 do
    transaction 'enroll' do
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

      header [name: 'Content-Type', value: 'application/json']
      post name: 'Phoenix - Checkout submit',
           url: PHOENIX_DOMAIN + '/checkout',
           raw_body: format('{"api_key": "%s",
                              "credit_card": {
                                  "prospect_token": "%s",
                                  "number": "4485677662213827",
                                  "expire_year": 2018,
                                  "expire_month": 10,
                                  "campaign_id": "%s"
                                }
                              }', PHOENIX_AUTHENTICATION_KEY, '${prospectToken}', PHOENIX_CAMPAIGN_ID) do
      end

      visit name: 'Phoenix - Thank you page',
            url: PHOENIX_DOMAIN + format('/checkout/thank_you/?campaign_id=%s&user_id=%s&api_key=%s', PHOENIX_CAMPAIGN_ID, PHOENIX_USER_ID, PHOENIX_AUTHENTICATION_KEY) do
        assert contains: 'Thank you for your orde'
      end
      think_time 1_000, 2_000
    end
  end
end.jmx(file: 'enroll.jmx')
