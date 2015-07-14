require "test_helper"

class SeleniumMethodsTest < ActionDispatch::IntegrationTest
  def test_sanity
    path = File.join(Rails.root, "vendor", "html", "test.html")
    ActiveSupport::TestCase.browsers.each do |browser|
      driver = Selenium::WebDriver.for browser
      driver.navigate.to "file://" + path
      # move browser window
      driver.manage.window.move_to(1000, 50)
      # resize browser window
      driver.manage.window.resize_to(350, 250)
      # get element by id
      btn = driver.find_element(:id, "btn")
      # get element by css class
      inp = driver.find_elements(:class, "inp")[0]
      # get element by xpath
      latLngInp = driver.find_elements(:xpath, "//body/input[@class = 'latLngInp']")[0]
      sleep 0.3
      
      testClickAndGetCssValue( inp, btn )

      testAlertBox( driver, btn )
      # test confirm box calcel
      testConfirmChange( driver, inp, btn, false )
      # test confirm box confirm
      testConfirmChange( driver, inp, btn, true )
      # test iframe
      testInteractElementInIframe( driver )

      testClearAndSetInputValue(driver, latLngInp)
      testAjaxCall( driver, inp )
      sleep 1
      driver.quit
      break
    end
  end
  def testClickAndGetCssValue (inp, btn)
    # click an element
    btn.click
    # get element css style
    borderColor = inp.css_value("border-color")
    # border color of .inp should be red now
    assert_equal "red", borderColor
    sleep 0.3
  end
  def testClearAndSetInputValue (driver, latLngInp)
    # get current value of input latLngInp
    # you can get any property of an dom element
    # (such like scrollLeft) in this way
    latlng = driver.execute_script("return arguments[0].value;", latLngInp)
    assert_equal "0.0,0.0", latlng
    # can also get value by attribute method
    assert_equal "0.0,0.0", latLngInp.attribute("value")
    # clear value
    # select all content
    driver.action.click(latLngInp) # focus
      .key_down(:control) # left control down
      .send_keys('a')  # Ctrl + A to select all content
      .key_up(:control).perform # left control up
    sleep 0.3
    # delete selected content
    latLngInp.send_keys(:delete)
    sleep 0.3
    # set new value by send keys
    latLngInp.send_keys "40.70594140,-74.0088760"
    assert_equal "40.70594140,-74.0088760", latLngInp.attribute("value")
  end
  def testAjaxCall (driver, inp)
    # call js function
    # use ajax call google geocode service
    driver.execute_script("useGeoService();")
    # wait until ajax call finished and input value updated
    wait = Selenium::WebDriver::Wait.new(:timeout => 3) # seconds
    wait.until { !inp.attribute("value").empty? }
    # check address value
    addr = inp.attribute("value")
    assert_equal "2 Hanover Street, New York, NY 10005, USA", addr
  end
  def testAlertBox (driver, btn)
    # trigger event with js code
    driver.execute_script("return $(arguments[0]).trigger('some-custom-event');", btn)
    sleep 0.5
    # check text in alert box
    alert = driver.switch_to.alert
    assert_equal "some custom event happend on #btn", alert.text
    # click OK
    alert.accept    
  end
  def testConfirmChange (driver, inp, btn, confirm)
    # trigger event with js code
    driver.execute_script("return $(arguments[0]).trigger('change-to-green-border');", btn)
    confirmBox = driver.switch_to.alert
    sleep 0.5
    assert_equal "change to green border?", confirmBox.text
    if confirm
      confirmBox.accept
      # check class has applied
      assert_equal true, driver.execute_script("return $(arguments[0]).hasClass('green-border');", inp)
      assert_not_equal "red", inp.css_value("border-color")
    else
      confirmBox.dismiss
      # check style not changed
      assert_equal "red", inp.css_value("border-color")
    end
    sleep 0.5
  end
  def testInteractElementInIframe (driver)
    # find the iframe element
    iframe = driver.find_elements(:xpath, "//body/iframe")[0]
    # switch driver to the iframe element
    driver.switch_to.frame iframe
    # do some operation as usual
    driver.find_element(:id, "btn").click
    assert_equal "test_inp", driver.find_elements(:class, "inp")[0].attribute("value")
    # need to switch back to default content
    # you will see error if the line below is removed
    driver.switch_to.default_content
    sleep 0.5
  end
end
