# need to store driver url (not page url)
# so just extend it to store self param
# as needed
#
# also store content for visual testing
class Selenium::WebDriver::Driver 
  attr_accessor :rake_env_params
end

# helper class for visual testing
class ActiveSupport::VisualTestingHelper
  # folder to store visual testing images
  @@visualTestingDir = File.join(Rails.root, "test", "visualTesting", ENV['runner'] || 'local')
  # hash to store info of each test cases
  # since each rake task (rake test) runs with different process
  # its safe to use class variable
  @@vt_cnt = {}
  def self.getVtCnt
    return @@vt_cnt
  end
  
  # preset image counter and accessing folders
  def self.init_vt (driver)
    # set folder path for each driver
    durlb = 'localhost_firefox'
    if driver
      rep = driver.rake_env_params || {};
      durlb = [rep['url'] || 'localhost', '_', rep['port'] || '', '_', rep['browser'] || 'firefox'].join()
    end
    case_name = caller[0].split('/').last.split('.')[0]
    vt_cnt = self.getVtCnt
    # reset image count
    # set folder path for case
    vt_cnt[case_name] = {
      'counter'=> 1,
      'base_dir'=> File.join(@@visualTestingDir, case_name, durlb, 'base_dir'),
      'new_dir'=> File.join(@@visualTestingDir, case_name, durlb, 'new_dir'),
      'diff_dir'=> File.join(@@visualTestingDir, case_name, durlb, 'diff_dir')
    }
    cnt = vt_cnt[case_name]

    # create folders if not exists
    FileUtils.mkdir_p(@@visualTestingDir) unless File.directory?(@@visualTestingDir)
    FileUtils.mkdir_p(cnt['base_dir']) unless File.directory?(cnt['base_dir'])
    FileUtils.mkdir_p(cnt['new_dir']) unless File.directory?(cnt['new_dir'])
    FileUtils.mkdir_p(cnt['diff_dir']) unless File.directory?(cnt['diff_dir'])
  end
  def self.visual_testing (driver)
    # mark as need to process vt
    ENV['checkvt'] = 'checkvt'
    case_name = caller[0].split('/').last.split('.')[0]
    # get cnt
    vt_cnt = self.getVtCnt
    cnt = vt_cnt[case_name]
    # get and increase counter
    counter = cnt['counter']
    cnt['counter'] = counter+1
    # tail of image file name, with leading zero
    imgTail = counter.to_s.rjust(5, "0")
    # base image to compare with
    baseImg = File.join(cnt['base_dir'], 'base_'+imgTail+ '.png')
    # current image to check
    newImg = File.join(cnt['new_dir'], 'new_'+imgTail+ '.png')
    # convert base image to rgba will speed up 1500% for chunky png
    # will do convert the first time of base image is captured
    cbaseImg = File.join(cnt['base_dir'], 'base_'+imgTail+'.rgba')
    # base image not exists
    if !File.file?(baseImg)
      # get base image
      driver.save_screenshot baseImg
      # store them to convert array
      # will do convert after all cases done
      vt_cnt = self.getVtCnt
      vt_cnt['to_conv'] = [] if !vt_cnt['to_conv']
      vt_cnt['to_conv'] << [baseImg, cbaseImg]
      # copy current image from base image
      FileUtils.copy_file(baseImg, newImg)
    else # base image exists
      # create path for diff image
      diffImg = File.join(cnt['diff_dir'], 'diff_'+imgTail+ '.png')
      # get current image
      driver.save_screenshot newImg
      # store them into diff array
      # will do real diff after all test cases done
      vt_cnt = self.getVtCnt
      vt_cnt['to_diff'] = [] if !vt_cnt['to_diff']
      vt_cnt['to_diff'] << [baseImg, newImg, cbaseImg, diffImg]
    end
  end
  def self.convert_rgba
  end
  def self.diff_img (baseImg, currImg, rgba, diffImg)
    return true if FileUtils.compare_file(baseImg, currImg)
    images = [
      ChunkyPNG::Image.from_file(rgba),
      ChunkyPNG::Image.from_file(currImg)
    ]
    diff_arrays = []
    # store minX, minY, maxX, maxY
    diff = []
    # distance for split diff array
    # to small will cause weird result
    split_dist = 30 # 30px
    split_dist = split_dist*split_dist
    # margin for rect
    margin = 2

    images.first.height.times do |y|
      images.first.row(y).each_with_index do |pixel, x|
        if pixel != images.last[x,y]
          if diff.length == 0
            diff += [x, y, x, y] # init
          else
            # distance from point to diff rect
            # dist to maxY
            dy = y - diff[3]
            # min dist of x
            dx = 0 # init
            # update
            dx = diff[0]-x if x < diff[0]
            dx = x-diff[2] if x > diff[2]
            # if larger than split distance
            if (dy*dy+dx*dx) > split_dist
              # store current diff
              diff_arrays << diff
              # create a new diff
              diff = [x, y, x, y] # init
            else
              diff[0] = x if x < diff[0] # update minX
              # no need to check minY
              diff[2] = x if x > diff[2] # update maxX
              diff[3] = y if y > diff[3] # update maxY
            end
          end
        end
      end
    end
    diff_arrays << diff if diff.length > 0

    x, y = diff.map{ |xy| xy[0] }, diff.map{ |xy| xy[1] }

    if diff_arrays.length > 0
      diff_arrays.each do |d|
        images.last.rect(d[0]-margin, d[1]-margin, d[2]+margin, d[3]+margin, ChunkyPNG::Color.rgb(255,0,0), ChunkyPNG::Color.from_hex('#FF0000', 70))
      end
      images.last.save(diffImg)
      return false
    end
    return true
  end
  # FileUtils.mkdir_p(dirname)
end