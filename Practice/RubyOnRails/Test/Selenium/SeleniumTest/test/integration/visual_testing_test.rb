require "test_helper"

class VisualTestingTest < ActionDispatch::IntegrationTest
  def test_sanity
    driver = Selenium::WebDriver.for :firefox
    begin
      path = File.join(Rails.root, "vendor", "html", "auto_redo_test.html")

      ActiveSupport::VisualTestingHelper.init_vt(driver)

      driver.navigate.to "file://" + path
      div = driver.find_element(:class, "target")
      ActiveSupport::VisualTestingHelper.visual_testing(driver)
      div.click
      sleep 0.3
      ActiveSupport::VisualTestingHelper.visual_testing(driver)

      # just refresh page and do similar again to
      # fake visual testing second time
      # run javascript to make something wrong
      # so can get the diff result
      #
      driver.navigate.refresh
      sleep 1
      div = driver.find_element(:class, "target")
      ActiveSupport::VisualTestingHelper.init_vt(driver)
      driver.execute_script("$('.target').html('err')")
      ActiveSupport::VisualTestingHelper.visual_testing(driver)
      div.click
      sleep 0.3
      driver.execute_script("$('.inp').val('err')")
      ActiveSupport::VisualTestingHelper.visual_testing(driver)
    ensure
      driver.quit
      if ENV['checkvt']
        File.open(ENV['task_filename'],'wb') do |f|
          f.write Marshal.dump(ActiveSupport::VisualTestingHelper.getVtCnt)
        end
        ENV['checkvt'] = nil
      end
    end
  end
end
