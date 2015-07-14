ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Capabilities for IE driver
  iecaps = Selenium::WebDriver::Remote::Capabilities.internet_explorer
  # need to ignore zoom or it will
  # complain zoom is 250% but it should be 100%
  # on IE11/Windows 8.1
  iecaps["ignoreZoomSetting"] = true;
  @@browsers = [:chrome, :firefox]
  @@remoteBrowsers = [
    { "url" => "http://192.168.31.169:4444/wd/hub",
      "desired_capabilities" =>  iecaps},
    # assume also want to test remote chrome
    { "url" => "http://192.168.31.169:4444/wd/hub",
      "desired_capabilities" =>  :chrome },
    
  ]
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all
  # Add more helper methods to be used by all tests here...
  def self.browsers
    @@browsers
  end
  def self.remoteBrowsers
    @@remoteBrowsers
  end
  def self.getDriverByBrowser (browser)
    if browser == :chrome
      # need to add --test-type for chrome switches
      # refer to http://stackoverflow.com/a/24875657
      driver = Selenium::WebDriver.for browser, :switches => %w[--ignore-certificate-errors --disable-popup-blocking --disable-translate --test-type]
      return driver
    else
      driver = Selenium::WebDriver.for browser
      return driver
    end
  end
end
