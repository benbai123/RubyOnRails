require "test_helper"

class VisualTestingTest < ActionDispatch::IntegrationTest
  def doTest (driver)
    # It is suggested resize window to specific size
    # so the screenshot will not be changed
    # by window size
    #
    # NOTE:
    #   based on my test,
    #   resize window not works on chrome
    driver.manage.window.move_to(0, 0)
    driver.manage.window.resize_to(800, 600)
    # Need to call init_vt method once before call
    # shot method
    ActiveSupport::VisualTestingHelper.init_vt(driver)

    # go to www.google.com
    driver.navigate.to "http://www.google.com"
    sleep 0.2
    # get input field
    q = driver.find_element(:name, 'q')
    # send some char and take screenshot
    input_and_shot 'ab', q, driver
    input_and_shot 'cd', q, driver
    input_and_shot 'ef', q, driver
    # input_and_shot 'ab', q, driver
    # input_and_shot '34', q, driver
    # input_and_shot '56', q, driver
  end
  def input_and_shot str, q, driver
    # send str to input field
    q.send_keys str
    # you probably want blur the input first
    # or the cursor may cause issue
    driver.execute_script('arguments[0].blur()', q)
    # pause for human eye
    sleep 0.3
    ActiveSupport::VisualTestingHelper.shot(driver)
  end
end
