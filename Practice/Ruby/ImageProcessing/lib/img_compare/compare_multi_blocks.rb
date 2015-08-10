
require 'chunky_png'

images = [
  ChunkyPNG::Image.from_file(File.expand_path('../../assets/test1.png', __FILE__)),
  ChunkyPNG::Image.from_file(File.expand_path('../../assets/test2.png', __FILE__))
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
  images.last.save(File.expand_path('../result/diff2.png', __FILE__))
end

