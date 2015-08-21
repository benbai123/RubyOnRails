require "test_helper"

class ModalBoxTest < ActionDispatch::IntegrationTest
  def doTest (driver)
    driver.manage.window.move_to(0, 0)
    driver.manage.window.resize_to(800, 600)
    ActiveSupport::VisualTestingHelper.init_vt(driver)
    sleep 0.3
    driver.navigate.to "http://www.google.com"
    sleep 0.3
    # check init page
    # driver.find_element(:name, 'q').send_keys "Hello"
     driver.find_element(:name, 'q').send_keys "World"
    ActiveSupport::VisualTestingHelper.shot(driver)
  end
end
