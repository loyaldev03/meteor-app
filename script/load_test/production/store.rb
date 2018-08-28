require 'ruby-jmeter'

STORE_DOMAIN = 'https://dailydeals.onmc.com/'.freeze

test do
  cookies

  threads count: 5, duration: 1200 do
    visit name: 'Store - Home page', url: STORE_DOMAIN do
    end
    think_time 1_000, 2_000

    visit name: 'Store - Home page', url: STORE_DOMAIN do
    end
    think_time 1_000, 2_000

    visit name: 'Store - Home page', url: STORE_DOMAIN do
    end
    think_time 1_000, 2_000
  end
end.jmx(file: 'store.jmx')
