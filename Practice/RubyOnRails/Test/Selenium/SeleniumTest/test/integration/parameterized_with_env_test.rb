require "test_helper"

class ParameterizedWithEnvTest < ActionDispatch::IntegrationTest
  def test_sanity
    # iterate param array
    ActiveSupport::TestCase.paramsFromEnv.each do |param|
      # get driver with param
      driver = ActiveSupport::TestCase.getRemoteDriverFromEnvParam(param)
      # do some action and quit
      driver.navigate.to "http://www.google.com"
      sleep 2
      driver.quit
    end
  end
end
