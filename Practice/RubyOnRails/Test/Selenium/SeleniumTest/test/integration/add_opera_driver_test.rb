require "test_helper"

class AddOperaDriverTest < ActionDispatch::IntegrationTest
  def test_sanity
    # the way that use switches with desired_capabilities
    chrome_options = {"args" => ["--ignore-certificate-errors", "--disable-popup-blocking", "--disable-translate", "--test-type"]}
    # need to specify path manually for local driver,
    # probably I installed opera wrong?
    opera_options = {'binary' => "/usr/lib/x86_64-linux-gnu/opera/opera"}
    local_caps = Selenium::WebDriver::Remote::Capabilities.chrome({
            'chromeOptions' => chrome_options,
            'operaOptions' => opera_options
        })
    remote_caps = Selenium::WebDriver::Remote::Capabilities.chrome({
            'chromeOptions' => chrome_options
        })
    # default remote server port
    port = "4444"
    [:chrome, :opera].each do |browser|
        ###
        #
        # local driver
        #
        ###

        # if test opera
        if browser == :opera
            # replace chrome driver with opera driver
            %x(mv ~/Downloads/chromedriver ~/Downloads/cchromedriver)
            %x(mv ~/Downloads/operadriver ~/Downloads/chromedriver)
        end
        # create a chrome driver
        driver = Selenium::WebDriver.for(:chrome,
            :desired_capabilities => local_caps)
        # test
        doTest(driver)
        # if after test opera
        if browser == :opera
            # replace them back
            %x(mv ~/Downloads/chromedriver ~/Downloads/operadriver)
            %x(mv ~/Downloads/cchromedriver ~/Downloads/chromedriver)
        end
        ###
        #
        # remote driver works well
        #
        ###

        # remote driver works well
        # just replace
        # -Dwebdriver.chrome.driver="%~dp0chromedriver.exe"
        # with
        # -Dwebdriver.chrome.driver="%~dp0operadriver.exe"
        # then it works

        # if test opera
        if browser == :opera
            # change remote server port
            port = "5555"
        end
        # create remote driver and test
        driver = Selenium::WebDriver.for(:remote, :url => "http://192.168.31.169:"+port+"/wd/hub", :desired_capabilities => remote_caps)
        doTest(driver)

        # if after test opera
        if browser == :opera
            # change port back
            port = "4444"
        end
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
