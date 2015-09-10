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

    begin
      # call old invoke
      old_invoke(args)
    rescue => e
      # rescue error if runner is specified since runner
      # probably want to do more things rather than aborted
      raise e if !ENV['runner']
      puts 'ignore rake exception so runner job will not be interrupted in lib/test.rake, view exception here if needed'
    end
  end
end

# task 'test:fileset'
# can test all test cases under test/integration by default
# or test a set of test cases under test/integration with given 'cases' arg
#
# modify variable 'carr' below as needed to
# add more folders
namespace :test do
  Rake::TestTask.new(:fileset) do |t|
    t.libs << "test"
    # Environment variable from Jenkins Parameter
    cstr = ENV['cases']
    # case array
    # default all cases under test/integration
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
    # Note
    # from my test
    # the order will always
    # different with the order you specified in
    # parameter
    t.test_files = Rake::FileList.new(carr)

    # you can also use the line below
    # from my test
    # use the line below will test cases
    # with the same order as you specified
    # ---------------------
    # t.test_files = carr
    # ---------------------

    t.verbose = true
  end
end
