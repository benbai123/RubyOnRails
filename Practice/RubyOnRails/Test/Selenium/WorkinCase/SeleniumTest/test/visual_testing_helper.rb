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
    case_name = caller[0].split('/').last.split('.')[0]
    if driver
      rep = driver.rake_env_params || {};
      durlb = [rep['url'] || 'localhost', '_', rep['port'] || '', '_', rep['browser'] || 'firefox'].join()
      rep['case_name'] = case_name
    end
    vt_cnt = self.getVtCnt
    # reset image count
    # set folder path for case

    # NOTE: since each task in different process
    # and each case runs one by one
    # so can use case name as key
    # 
    # need to add some more info if run them 
    # parallel
    vt_cnt[case_name] = {
      'counter'=> 1,
      'base_dir'=> File.join(@@visualTestingDir, case_name, durlb, 'base_dir'),
      'new_dir'=> File.join(@@visualTestingDir, case_name, durlb, 'new_dir'),
      'diff_dir'=> File.join(@@visualTestingDir, case_name, durlb, 'diff_dir'),
      'parent_dir'=> File.join(@@visualTestingDir, case_name, durlb)
    }
    cnt = vt_cnt[case_name]

    # create folders if not exists
    FileUtils.mkdir_p(@@visualTestingDir) unless File.directory?(@@visualTestingDir)
    FileUtils.mkdir_p(cnt['base_dir']) unless File.directory?(cnt['base_dir'])
    FileUtils.mkdir_p(cnt['new_dir']) unless File.directory?(cnt['new_dir'])
    FileUtils.mkdir_p(cnt['diff_dir']) unless File.directory?(cnt['diff_dir'])
  end
  def self.shot (driver)
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
    # create path for diff image
    diffImg = File.join(cnt['diff_dir'], 'diff_'+imgTail+ '.png')
    # base image not exists
    if !File.file?(baseImg)
      # get base image
      driver.save_screenshot baseImg
      # store them to convert array
      # will do convert after all cases done
      vt_cnt = self.getVtCnt
      vt_cnt['to_conv'] = [] if !vt_cnt['to_conv']
      vt_cnt['to_conv'] << [baseImg, cbaseImg, cnt['parent_dir']]
      File.delete newImg if File.exist?(newImg)
      File.delete diffImg if File.exist?(diffImg)
      # copy current image from base image
      FileUtils.copy_file(baseImg, newImg)
    else # base image exists
      # get current image
      driver.save_screenshot newImg
      # store them into diff array
      # will do real diff after all test cases done
      vt_cnt = self.getVtCnt
      vt_cnt['to_conv'] = [] if !vt_cnt['to_conv']
      vt_cnt['to_conv'] << [baseImg, cbaseImg, cnt['parent_dir']] if !File.exist?(cbaseImg)
      vt_cnt['to_diff'] = [] if !vt_cnt['to_diff']
      vt_cnt['to_diff'] << [baseImg, newImg, cbaseImg, diffImg, case_name, cnt['parent_dir']]
    end
  end
  def self.convert_rgba (src, dest)
    return if 'true'.eql?(ENV['skipRealDiff'])
    img = ChunkyPNG::Image.from_file(src)
    img.save(dest, :fast_rgba)
  end
  def self.diff_img (baseImg, currImg, rgba, diffImg)
    File.delete(diffImg) if File.exist?(diffImg)
    # much faster than load image to compare
    return true if FileUtils.compare_file(baseImg, currImg)
    if 'true'.eql?(ENV['skipRealDiff'])
      return false
    end
    # really want to load image to compare?
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

    ifw = images.first.width
    ifh = images.first.height
    ilw = images.last.width
    ilh = images.last.height
    ifh.times do |y|
      # since 'n.times' starts from 0 to n-1
      break if y >= ilh
      images.first.row(y).each_with_index do |pixel, x|
        # again, since 'n.times' starts from 0 to n-1
        break if x >= ilw
        if pixel != images.last[x,y]
          diff = self.append_diff_pixel x, y, diff, diff_arrays, split_dist
        end
      end
    end
    diff_arrays << diff if diff.length > 0

    # put all pixel out of range
    if ilw > ifw
      diff_arrays << [ifw, 0, ilw-1, ifh]
    end
    if ilh > ifh
      diff_arrays << [0, ifh, ilw-1, ilh-1]
    end



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
  # x: x value of different pixel
  # y: y value of different pixel
  # arr: current diff array (will be a rect)
  # arrs: array that hold many array (many rects)
  # split_dist: distance to split pixel to new array
  def self.append_diff_pixel x, y, arr, arrs, split_dist=50
    if arr.length == 0
      arr += [x, y, x, y] # init
    else
    found = false
    # if larger than split distance
    if self.get_dist(x, y, arr) > split_dist
      # try merge point to previous array
      arrs.each do |oarr|
        break if found
        if !found && self.get_dist(x, y, oarr) < split_dist
          found = true
          self.merge_point x, y, oarr
        end
      end
      if !found
        # store current diff
        arrs << arr
        # create a new diff
        arr = [x, y, x, y] # init
      end
    else
      self.merge_point x, y, arr
    end
    return arr
    end
  end
  def self.merge_point x, y, arr
    arr[0] = x if x < arr[0] # update minX
    # no need to check minY
    arr[2] = x if x > arr[2] # update maxX
    arr[3] = y if y > arr[3] # update maxY
  end
  def self.get_dist x, y, arr
    # distance from point to diff rect
    # dist to maxY
    dy = y - arr[3]
    # min dist of x
    dx = 0 # init
    # update
    dx = arr[0]-x if x < arr[0]
    dx = x-arr[2] if x > arr[2]
    return dy*dy+dx*dx
  end
end