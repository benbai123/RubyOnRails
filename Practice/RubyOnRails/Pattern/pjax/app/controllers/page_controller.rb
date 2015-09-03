class PageController < ApplicationController
  def pageOne
    fixPjax
  end
  def pageTwo
    fixPjax
  end
  def fixPjax
    puts 'X-PJAX?'
    puts request.headers['X-PJAX']
    puts 'request.xhr?'
    puts request.xhr?
    if request.headers['X-PJAX']
      render :layout => false
    end
  end
end
