require "test_helper"

class FirefoxPortableTest < ActionDispatch::IntegrationTest
  def test_sanity
    #local default
    driver = Selenium::WebDriver.for :firefox
    doTest (driver)

    # local portable
    ffpath = File.join(Rails.root, "vendor", "portable_app", "firefox", "Firefox31.0-64bit")
      Selenium::WebDriver::Firefox.path = ffpath
    driver = Selenium::WebDriver.for :firefox
    doTest (driver)

    # remote
    driver = Selenium::WebDriver.for(:remote,
      :url => "http://192.168.31.169:4444/wd/hub",
      :desired_capabilities => :firefox)
    doTest(driver)

    # remote with another version
    driver = Selenium::WebDriver.for(:remote,
      :url => "http://192.168.31.169:5555/wd/hub",
      :desired_capabilities => :firefox)
    doTest(driver)
  end
  def doTest (driver)
    begin
      # alert firefox version
      driver.execute_script("arr = navigator.userAgent.match(/(opera|chrome|safari|firefox|msie|trident(?=\\/))\\/?\s*(\\d+)/i)")
      driver.execute_script("alert(arr[1] + ',  version: ' + arr[2])")
      sleep 2
      # click OK
      driver.switch_to.alert.accept
    ensure
      # quit driver, close browser window
      driver.quit
    end
  end
end
