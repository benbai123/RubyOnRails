ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require File.expand_path('../visual_testing_helper.rb', __FILE__)
require 'rails/test_help'
require 'pathname'
require 'fileutils'
require 'chunky_png'


class ActiveSupport::TestCase
  @@convertedImgs = []
  @@failedCases = []
  @@failedCasesVtFolder = {}
  def self.converted_images
    return @@convertedImgs
  end
  def self.faled_cases
    return @@failedCases
  end
  def self.faled_vt_folder
    return @@failedCasesVtFolder
  end
  def self.doTest (test_case, driver)
    reTest = true
    while reTest do
      reTest = false
      begin
        test_case.doTest(driver)
      rescue Assertion => e
        reTest = self.handle_error test_case, driver, e
      rescue => error
        reTest = self.handle_error test_case, driver, error
      ensure
        test_case.finish(driver) unless reTest
      end
    end
  end
  def self.handle_error test_case, driver, error
    if ENV['autoretest']
      test_case.reset(driver, error)
      return true
    else
      # remove last '.rb'
      filename = test_case.get_filename.split('.rb').join('.rb')
      # put it into failed cases
      @@failedCases << filename if !@@failedCases.include? filename
      raise error
    end
  end
  def self.seleniumTest (test_case)
    if !ENV['browsers']
      # no param, test local firefox
      driver = Selenium::WebDriver.for :firefox
      self.doTest(test_case, driver)
    else
      self.testWithEnvParam(test_case)
    end
  end
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all
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
      self.doTest(test_case, driver)
    end
  end
  def self.paramsFromEnv
    # parse parameters
    return JSON.parse ENV['browsers'].gsub('=>', ':').gsub("'", "\"")
  end
  # create driver with given param
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
  # get base capabilities by given browser
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
  # display errors only from given filename
  def self.displayFilteredError (error, filename)
    puts "Error: " + error.message
    errArray = error.backtrace.map{ |x|
      x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
      [$1,$2,$4]
    }
    errArray.each do |err|
      if err[0].end_with? File.basename(filename)
        puts "Line: "+err[1]+", "+err[2]+", File: "+File.basename(filename)
        puts ""
      end
    end
  end
  def self.get_visualtesting_link path
    # split and join to remove first
    return 'http://192.168.31.218:3000/vt/browse/visualTesting'+path.split('visualTesting').from(1).join('visualTesting')
  end
end
##
# default methods for test cases
##
class ActionDispatch::IntegrationTest
  def test_sanity
    if !self.class.name.eql? "ActionDispatch::IntegrationTest"
      # pass instance as parameter
      ActiveSupport::TestCase.seleniumTest(self)
    end
  end
  def reset (driver, error)
    output_filtered_error error
    driver.navigate.refresh
    sleep 2
  end
  def output_filtered_error error
    filename = get_filename
    ActiveSupport::TestCase.displayFilteredError(error, filename)
  end
  def get_filename
    return Pathname.new(self.method(:doTest).source_location[0]).basename.to_s
  end
  def finish (driver)
    driver.quit
  end
  def getPageURL
    pageurl = ENV['pageurl']
    if pageurl.nil? || pageurl.empty? || pageurl.blank?
      pageurl = "http://192.168.31.169:8080"
    end
    return pageurl;
  end
end
##
# intercept report
##
class MiniTest::CompositeReporter
  alias :oreport :report
  def report
    oreport
    # load content from file
    vt_cnt = ActiveSupport::VisualTestingHelper.getVtCnt
    # no content, return
    return if !vt_cnt
    cimgs = ActiveSupport::TestCase.converted_images
    # convert png to rgba for base images
    if vt_cnt['to_conv']
      vt_cnt['to_conv'].each do |tocs|
        # puts 'convert ' + tocs[0]
        cimgs << tocs[0]
        ActiveSupport::VisualTestingHelper.convert_rgba(tocs[0], tocs[1])
      end
    end
    # diff base image with new image
    if vt_cnt['to_diff']
      vt_cnt['to_diff'].each do |tod|
        # puts 'diff ' + tod[0].split('visualTesting/').last
        same = ActiveSupport::VisualTestingHelper.diff_img(tod[0], tod[1], tod[2], tod[3])
        if !same
          ActiveSupport::TestCase.faled_cases << tod[4] if !ActiveSupport::TestCase.faled_cases.include?(tod[4])

          ActiveSupport::TestCase.faled_vt_folder[tod[4]] = [] if !ActiveSupport::TestCase.faled_vt_folder[tod[4]]
          ActiveSupport::TestCase.faled_vt_folder[tod[4]] << tod[5] if !ActiveSupport::TestCase.faled_vt_folder[tod[4]].include?(tod[5])
        end
      end
    end
    if cimgs.size > 0
      puts ''
      puts 'all base images to convert this run: '
      cimgs.each do |cimg|
        puts ActiveSupport::TestCase.get_visualtesting_link cimg
      end
      puts ''
      puts ''
    end
    puts ''
    puts 'Failed Cases: (assertion error / exception above, or visual testing failed)' if (ActiveSupport::TestCase.faled_cases.size > 0)
    ActiveSupport::TestCase.faled_cases.each do |failed_case|
      puts ''
      puts 'case: ' + failed_case
      failed_vt = ActiveSupport::TestCase.faled_vt_folder[failed_case]
      if failed_vt
        puts 'including failed visual testing, view imgs at:'
        failed_vt.each do |fvt|
          puts ActiveSupport::TestCase.get_visualtesting_link fvt
        end
      end
    end
    puts ''
    puts ''
    if (ActiveSupport::TestCase.faled_cases.size > 0 && ENV['failedmark'])
      File.open(File.join(Rails.root, "test", "failed", ENV['failedmark']+'.txt'), 'w')
    end
    # chmod if run by local
    # or runner should take care of it
    begin FileUtils.chmod_R 0777, File.join(Rails.root, "test", "visualTesting", "local") if !ENV['runner'] rescue puts 'ignored chmod err @test_hleper.rb' end
  end
end