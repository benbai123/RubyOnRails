
require 'chunky_png'

images = [
  ChunkyPNG::Image.from_file('../assets/test1.png'),
  ChunkyPNG::Image.from_file('../assets/test2.png')
]
diff_arrays = []
# store minX, minY, maxX, maxY
diff = []
# distance for split diff array
# to small will cause weird result
split_dist = 30 # 30px
split_dist = split_dist*split_dist

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
        dx = [(x-diff[0]).abs, (x-diff[2]).abs].min
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
    images.last.rect(d[0], d[1], d[2], d[3], ChunkyPNG::Color.rgb(255,0,0), ChunkyPNG::Color.from_hex('#FF0000', 70))
  end
  images.last.save('result/diff2.png')
end

