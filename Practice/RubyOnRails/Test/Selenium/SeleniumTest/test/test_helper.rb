ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
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
class ActiveSupport::VisualTestingHelper
  @@visualTestingDir = File.join(Rails.root, "test", "visualTesting")
  # store current image number and folders for each case (caller)
  @@callerCnt = {}
  @@output = true
  def self.init_vt
    case_name = caller[0].split('/').last.split('.')[0]
    # reset image count
    @@callerCnt[case_name] = {
      'counter'=> 1,
      'base_dir'=> File.join(@@visualTestingDir, case_name, 'base_dir'),
      'new_dir'=> File.join(@@visualTestingDir, case_name, 'new_dir'),
      'diff_dir'=> File.join(@@visualTestingDir, case_name, 'diff_dir')
    }
    cnt = @@callerCnt[case_name]

    FileUtils.mkdir_p(@@visualTestingDir) unless File.directory?(@@visualTestingDir)
    FileUtils.mkdir_p(cnt['base_dir']) unless File.directory?(cnt['base_dir'])
    FileUtils.mkdir_p(cnt['new_dir']) unless File.directory?(cnt['new_dir'])
    FileUtils.mkdir_p(cnt['diff_dir']) unless File.directory?(cnt['diff_dir'])
  end
  def self.visual_testing (driver)
    case_name = caller[0].split('/').last.split('.')[0]
    cnt = @@callerCnt[case_name]
    counter = cnt['counter']
    cnt['counter'] = counter+1
    # tail of image file name, with leading zero
    imgTail = counter.to_s.rjust(5, "0") + '.png'
    baseImg = File.join(cnt['base_dir'], 'base_'+imgTail)
    if !File.file?(baseImg)
      driver.save_screenshot baseImg
    else
      newImg = File.join(cnt['new_dir'], 'new_'+imgTail)
      diffImg = File.join(cnt['diff_dir'], 'diff_'+imgTail)
      driver.save_screenshot newImg
      self.diff_img(baseImg, newImg, diffImg)
    end
  end
  def self.diff_img (baseImg, currImg, diffImg)
    images = [
      ChunkyPNG::Image.from_file(baseImg),
      ChunkyPNG::Image.from_file(currImg)
    ]
    diff_arrays = []
    # store minX, minY, maxX, maxY
    diff = []
    # distance for split diff array
    # to small will cause weird result
    split_dist = 30 # 30px
    split_dist = split_dist*split_dist
    # margin for rect
    margin = 2

    images.first.height.times do |y|
      images.first.row(y).each_with_index do |pixel, x|
        if pixel != images.last[x,y]
          if diff.length == 0
            diff += [x, y, x, y] # init
          else
            # distance from point to diff rect
            # dist to maxY
            dy = y - diff[3]
            # min dist of x
            dx = 0 # init
            # update
            dx = diff[0]-x if x < diff[0]
            dx = x-diff[2] if x > diff[2]
            # if larger than split distance
            if (dy*dy+dx*dx) > split_dist
              # store current diff
              diff_arrays << diff
              # create a new diff
              diff = [x, y, x, y] # init
            else
              diff[0] = x if x < diff[0] # update minX
              # no need to check minY
              diff[2] = x if x > diff[2] # update maxX
              diff[3] = y if y > diff[3] # update maxY
            end
          end
        end
      end
    end
    diff_arrays << diff if diff.length > 0

    x, y = diff.map{ |xy| xy[0] }, diff.map{ |xy| xy[1] }

    if diff_arrays.length > 0
      diff_arrays.each do |d|
        images.last.rect(d[0]-margin, d[1]-margin, d[2]+margin, d[3]+margin, ChunkyPNG::Color.rgb(255,0,0), ChunkyPNG::Color.from_hex('#FF0000', 70))
      end
      images.last.save(diffImg)
    end
  end
  # FileUtils.mkdir_p(dirname)
end