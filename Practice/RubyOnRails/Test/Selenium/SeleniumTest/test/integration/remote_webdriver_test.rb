require "test_helper"

class RemoteWebdriverTest < ActionDispatch::IntegrationTest
  def test_sanity
    ActiveSupport::TestCase.remoteBrowsers.each do |remoteBrowser|
      driver = Selenium::WebDriver.for(:remote, :url => remoteBrowser["url"], :desired_capabilities => remoteBrowser["desired_capabilities"])
      doTest(driver)
    end
  end
  def doTest (driver)
    driver.navigate.to "http://google.com"
    element = driver.find_element(:name, 'q')
    element.send_keys "Hello WebDriver!"
    element.submit

    puts driver.title

    sleep 2
    # quit driver, close browser window
    driver.quit
  end
end
