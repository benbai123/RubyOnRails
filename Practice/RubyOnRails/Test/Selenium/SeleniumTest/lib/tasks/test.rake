require File.expand_path('../../../test/visual_testing_helper.rb', __FILE__)
require 'fileutils'
# override Rake::Task.invoke to do something after
# all test cases finished
class Rake::Task
  # store old invoke method
  alias :old_invoke :invoke
  def invoke(*args)
    puts 'before task'
    # output process pid
    puts 'pid: ' + Process.pid.to_s
    # set file name for communicating with test cases
    ENV['task_filename'] = Process.pid.to_s if !ENV['task_filename']
    ENV['task_filename'] = 'test/visualTesting/'+(ENV['runner'] || 'local')+'/'+ENV['task_filename']+'.txt'
    # call old invoke
    old_invoke(args)
    puts 'after task'
    # return if file not exists
    File.exist?(ENV['task_filename'])
    # load content from file
    vt_cnt = Marshal.load (File.binread(ENV['task_filename']))
    # no content, return
    return if !vt_cnt
    # convert png to rgba for base images
    if vt_cnt['to_conv']
      vt_cnt['to_conv'].each do |tocs|
        puts 'convert ' + tocs[0].split('visualTesting/').last
        img = ChunkyPNG::Image.from_file(tocs[0])
        img.save(tocs[1], :fast_rgba)
      end
    end
    # diff base image with new image
    if vt_cnt['to_diff']
      vt_cnt['to_diff'].each do |tod|
        puts 'diff ' + tod[0].split('visualTesting/').last
        ActiveSupport::VisualTestingHelper.diff_img(tod[0], tod[1], tod[2], tod[3])
      end
    end
    # remove file
    FileUtils.remove_file(ENV['task_filename'])
  end
end
namespace :test do
  Rake::TestTask.new(:fileset) do |t|
    t.libs << "test"
    # Environment variable from Jenkins Parameter
    cstr = ENV['cases']
    # case array
    # default all cases under test/integration
    # the local cases will fail with Jenkins however
    carr = ['test/integration/*.rb']
    # if cases string exists
    if !cstr.nil? && !cstr.empty?
      # parse cases string to temp case array
      tarr = JSON.parse cstr.gsub("'", "\"")
      # reset case array
      carr = []
      # add prefix to each case 
      # then add it into case array
      tarr.each do |rbf|
        carr << 'test/integration/'+rbf.strip
      end
    end
    # set test_files
    # Note the order will always
    # different with the order you specified in
    # parameter
    t.test_files = Rake::FileList.new(carr)

    # you can also use the line below
    # from my test
    # use the line below will test cases
    # with the same order as you specified
    #
    # t.test_files = carr
    t.verbose = true
  end
end
