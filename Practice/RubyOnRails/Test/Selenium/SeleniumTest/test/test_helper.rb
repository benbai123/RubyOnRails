ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require File.expand_path('../visual_testing_helper.rb', __FILE__)
require 'rails/test_help'
require 'fileutils'
require 'chunky_png'

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
  # for parameterized test case
  # usage:
  # browsers=[{'url' => 'remote url', 'port' => 'port number', 'browser' => 'browser name', 'caps' => capabilities_hash}, ...]

  # url: required, url of remote selnium server
  # port: optional, default '4444'
  # browser: optional, default 'firefox'
  # caps: optional, will override desired capabilities if provided

  # e.g.
  # browsers="[{'url' => '192.168.31.169'}]" rake test test/integration/parameterized_with_env_test.rb
  # 
  # browsers="[{'url' => '192.168.31.169'}, {'url' => '192.168.31.169', 'port' => '5555', 'browser' => 'opera'}]" rake test test/integration/parameterized_with_env_test.rb
  # 
  # browsers="[{'url' => '192.168.31.169','browser' => 'chrome'}, {'url' => '192.168.31.169', 'port' => '5555', 'browser' => 'opera'}]" rake test
  # 
  # browsers="[{'url' => '192.168.31.169','browser' => 'chrome', 'caps' => {'chromeOptions' => {'args' => ['--ignore-certificate-errors', '--disable-popup-blocking', '--disable-translate']}}}, {'url' => '192.168.31.169', 'browser' => 'internet_explorer'}]" rake test test/integration/parameterized_with_env_test.rb

  def self.testWithEnvParam (test_case)
    # iterate param array
    paramsFromEnv.each do |param|
      # get driver with param
      driver = ActiveSupport::TestCase.getRemoteDriverFromEnvParam(param)
      test_case.doTest(driver)
    end
  end
  def self.paramsFromEnv
    # skip if no given browsers
    if !ENV['browsers']
      return []
    end
    # parse parameters
    return JSON.parse ENV['browsers'].gsub('=>', ':').gsub("'", "\"")
  end
  def self.getRemoteDriverFromEnvParam (param)
    driverparam = {}
    # port, default '4444'
    port = param['port'] || '4444'
    # build url from url and port of param
    url = ['http://', param['url'], ':', port, '/wd/hub'].join('')
    # browser, default 'firefox'
    browser = param['browser'] || 'firefox'
    caps = getBrowserCapabilities(browser)
    # also can pass capabilities from param
    if (param['caps'])
      caps.merge!(param['caps'])
    end
    driver = Selenium::WebDriver.for(:remote, :url => url, :desired_capabilities => caps)
    driverparam['url'] = param['url']
    driverparam['port'] = port
    driverparam['browser'] = browser
    driverparam['caps'] = caps
    # store param for later usage
    driver.rake_env_params = driverparam
    return driver
  end
  def self.getBrowserCapabilities (browser)
    if browser.eql? 'opera'
      # use chrome driver for opera
      return Selenium::WebDriver::Remote::Capabilities.send('chrome')
    else
      # call method by string
      caps = Selenium::WebDriver::Remote::Capabilities.send(browser)
      if browser.eql? 'internet_explorer'
        # Capabilities for IE driver
        # need to ignore zoom or it will
        # complain zoom is 250% but it should be 100%
        # on IE11/Windows 8.1
        caps.merge!({'ignoreZoomSetting' => true})
      elsif browser.eql? 'chrome'
        # the way that use switches with desired_capabilities
        caps.merge!({
              'chromeOptions' => {"args" => ["--ignore-certificate-errors",
            "--disable-popup-blocking",
            "--disable-translate", "--test-type"]}
          })
      end
      return caps
    end
  end
  def self.displayError (error, file)
    puts "Error: " + error.message
    errArray = error.backtrace.map{ |x|
      x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
      [$1,$2,$4]
    }
    errArray.each do |err|
      if err[0].end_with? File.basename(file)
        puts "Line: "+err[1]+", "+err[2]+", File: "+File.basename(file)
        puts ""
      end
    end
  end
end
