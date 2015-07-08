require "test_helper"
require "selenium-webdriver"

class CheckSeleniumWorkTest < ActionDispatch::IntegrationTest
  def test_sanity
    driver = Selenium::WebDriver.for :firefox
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
