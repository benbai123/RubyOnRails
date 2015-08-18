require 'fileutils'
class VisualTestingController < ApplicationController

  # show folder content
  def show
    @path = get_path || 'visualTesting'
    fullpath = get_fullpath @path
    @files = get_files fullpath
    # call listimgs if looks like the
    # visual testing image folder
    if is_compare_folder @files
      listimgs fullpath
      return
    end
  end
  # list base, new and diff imgs
  def listimgs (path)
    @imgarrs = get_img_files path || []
    render 'listimgs'
  end
  # returns png file if exists
  def img
    fullpath = get_fullpath get_path
    # just send file back to client directly
    if File.exist?(fullpath) && !File.directory?(fullpath)
      send_file( fullpath,
        :disposition => 'inline',
        :type => 'image/png',
        :x_sendfile => true )
    else
      render nothing: true
    end
  end
  # delete base img or apply new img
  def act
    puts 'act'
    act = params[:act]
    fullpath = get_fullpath get_path
    begin
      File.delete(fullpath) if act.eql?('Delete')
      if act.eql?('Apply')
        arr = fullpath.split('new_dir')
        # remove anything after last 'new_dir'
        # and take tail file name of png file
        fname = arr.pop.split('new_').last
        case_folder = arr.join('new_dir')
        base_path = File.join(case_folder, 'base_dir', 'base_'+fname)
        diff_path = File.join(case_folder, 'diff_dir', 'diff_'+fname)
        puts fullpath
        puts base_path
        puts diff_path
        File.delete(diff_path) if File.exist?(diff_path)
        File.delete(base_path) if File.exist?(base_path)
        FileUtils.cp fullpath, base_path
      end
      render nothing: true
    rescue
      render nothing: true, status: 500
    end
  end
  ##
  # private methods
  ##
  def is_compare_folder (arr)
    # whether contains visual testing folders
    return arr.include?('base_dir') && arr.include?('new_dir') && arr.include?('diff_dir')
  end
  # get path from original url since
  # .xxx will be removed from param by default
  def get_path
    # full url
    url = request.original_url
    # string after first 'browse'
    url = url.partition('browse').last
    return nil if url.blank?
    # split by slash
    # remove empty element
    arr = url.split('/').reject { |c| c.empty? }
    # join with slash, now leading slash removed
    path = arr.join('/')
    return nil if path.blank?
    # avoid ..
    return 'visualTesting' if path.include? '..'
    return path
  end
  def get_fullpath (path)
    return File.join('test', path)
  end
  def get_files (path)
    files = []
    return files if (!File.exist?(path) || !File.directory?(path))
    tfiles = Dir.foreach(path)
    tfiles.each do |file|
      # no . or .., please use back button of browser :)
      if !(file.eql?('.') || file.eql?('..'))
        files << file
      end
    end
    return files
  end
  def get_img_files (path)
    # hash for group files
    imgs = []
    bstart = File.join( path, 'base_dir')
    nstart = File.join( path, 'new_dir')
    dstart = File.join( path, 'diff_dir')
    # only allow png files
    baseImgs = get_files(bstart).reject { |c| !c.end_with? '.png' }
    newImgs = get_files(nstart).reject { |c| !c.end_with? '.png' }
    diffImgs = get_files(dstart).reject { |c| !c.end_with? '.png' }
    # replace path to url path
    bstart = File.join('/vt/browse', bstart.partition('test').last)
    nstart = File.join('/vt/browse', nstart.partition('test').last)
    dstart = File.join('/vt/browse', dstart.partition('test').last)
    baseImgs.each do |f|
      # file name after 'base_'
      s = f.partition('_').last
      arr = []
      arr << File.join(bstart, f)
      nimg = 'new_'+s
      if newImgs.include?(nimg)
        arr << File.join(nstart, nimg)
        # only push diff image if new image exists
        dimg = 'diff_'+s
        arr << File.join(dstart, dimg) if diffImgs.include?(dimg)
      end
      imgs << arr
    end
    return imgs
  end
end