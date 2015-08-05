require "test_helper"

class AutoRetestIfFailTest < ActionDispatch::IntegrationTest
  def test_sanity
    # pass instance as parameter
    ActiveSupport::TestCase.testWithEnvParam(self)
  end
  def doTest (driver)
    reTest = true
    path = File.join(Rails.root, "vendor", "html", "auto_redo_test.html")
    while reTest do
      # clear reTest
      reTest = false
      # do some action and quit
      begin
        driver.navigate.to "file://" + path
        div = driver.find_element(:class, "target")
        div.click
        inp = driver.find_element(:class, "inp")
        # wait until js done
        wait = Selenium::WebDriver::Wait.new(:timeout => 1) # seconds
        wait.until { !inp.attribute("value").empty? }
        assert_equal "clicked", inp.attribute("value")
      rescue => error
        ActiveSupport::TestCase.displayError(error, __FILE__)
        # set reTest
        reTest = true
        driver.navigate.refresh
        sleep 2
      ensure
        driver.quit unless reTest
      end
    end
  end
end
