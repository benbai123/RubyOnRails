require "test_helper"

class AutoretestTest < ActionDispatch::IntegrationTest
  def doTest (driver)
    # go to vendor/html/for_autoretest.html
    path = "file://" + File.join(Rails.root, "vendor", "html", "for_autoretest.html")
    driver.navigate.to path
    sleep 0.2
    # get box
    box = driver.find_element(:css, '.box')

    # click box
    box.click

    # check size
    # (just for demo, usually you do not need to)
    msg = 'width of the box should be 100'
    assert_equal 100, driver.execute_script('return $(arguments[0]).width()', box), msg
    msg = 'height of the box should be 100'
    assert_equal 100, driver.execute_script('return $(arguments[0]).height()', box), msg

    # pause for human eye
    sleep 0.2

    # check content
    msg = 'the box should display text "clicked" after it is clicked'
    cnt = driver.execute_script('return arguments[0].innerHTML', box)
    assert cnt.include?('clicked'), msg
  end
end
