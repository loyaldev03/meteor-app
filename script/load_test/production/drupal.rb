require 'ruby-jmeter'

DRUPAL_DOMAIN   = 'https://www.onmc.com'.freeze
USERNAME        = 'load_test+iklkbzork@mailinator.com'.freeze
PASSWORD        = 'user911'.freeze
USER_ID         = '181022'.freeze
AUTOLOGIN_TOKEN = '/l/i8WQCoBiRpEz'.freeze

test do
  cache clear_each_iteration: true

  cookies

  threads count: 50, duration: 1200 do
    transaction 'drupal_pages' do
      visit name: 'Drupal - Autologin', url: DRUPAL_DOMAIN + AUTOLOGIN_TOKEN

      visit name: 'Drupal - Home page', url: DRUPAL_DOMAIN do
        assert contains: 'Logout'
        assert contains: 'About ONMC'
      end
      think_time 1_000, 2_000

      visit name: 'Drupal - View User', url: DRUPAL_DOMAIN + '/user/' + USER_ID + '/edit' do
        assert contains: 'To change the current user password'
      end
      think_time 1_000, 2_000

      visit name: 'Drupal - Walled page - Tips', url: DRUPAL_DOMAIN + '/tips' do
        assert contains: 'Track Tips and Tricks'
      end
      think_time 1_000, 2_000

      visit name: 'Drupal - Walled page - Events', url: DRUPAL_DOMAIN + '/events' do
        assert contains: 'No Upcoming Events'
      end
      think_time 1_000, 2_000

      visit name: 'Drupal - News 1', url: DRUPAL_DOMAIN + '/content/nbcsn-presents-ride-victory-stories-kyle-petty-charity-ride' do
        assert contains: '60-minute Original Documentary Chronicles 2017'
      end
      think_time 1_000, 2_000

      visit name: 'Drupal - News 2', url: DRUPAL_DOMAIN + '/content/2017-ultimate-vip-experience' do
        assert contains: 'We are excited to announce the 2017 ONMC Ultimate VIP Experience!'
      end
      think_time 1_000, 2_000
    end
  end
end.jmx(file: 'drupal.jmx')
