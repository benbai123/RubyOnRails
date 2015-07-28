require "test_helper"

class ParameterizedWithEnvTest < ActionDispatch::IntegrationTest
  def test_sanity
    # pass instance as parameter
    ActiveSupport::TestCase.testWithEnvParam(self)
  end
  def doTest (driver)
    # do some action and quit
    driver.navigate.to "http://www.google.com"
    sleep 2
    driver.quit
  end
end
