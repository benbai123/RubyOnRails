require "test_helper"

class SimpleTest < ActionDispatch::IntegrationTest
  def doTest (driver)
    driver.manage.window.move_to(0, 0)
    driver.manage.window.resize_to(800, 600)
    # initialize visual testing
    ActiveSupport::VisualTestingHelper.init_vt(driver)
    sleep 0.3
    driver.navigate.to "http://www.google.com"
    sleep 0.3
    # driver.find_element(:name, 'q').send_keys "Hello"
     driver.find_element(:name, 'q').send_keys "World"
    # take a screenshot
    # this will store base image if it doesn't exist
    # or save a new image and diff it with base image
    ActiveSupport::VisualTestingHelper.shot(driver)
  end
end
