require "test_helper"

class SaveScreenshotTest < ActionDispatch::IntegrationTest
  def test_sanity
    @cnt = 1
    driver = Selenium::WebDriver.for :firefox
    doTest(driver)
    driver = Selenium::WebDriver.for :remote, :url => "http://192.168.31.169:4444/wd/hub", :desired_capabilities => :firefox
    doTest(driver)
  end
  def doTest(driver)
    begin
      driver.get "http://www.google.com"
      driver.save_screenshot ['google', @cnt.to_s, 'png'].join('')
      @cnt+=1
    ensure
      driver.quit
    end
  end
end
