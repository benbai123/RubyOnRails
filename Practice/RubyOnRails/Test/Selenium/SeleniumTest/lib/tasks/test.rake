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
