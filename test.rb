require 'gosu'

module ZOrder
  Background, Stars, Player, UI = *0..3
end

class Window < Gosu::Window
  def initialize
    super(640, 480, false)
    self.caption = "Gosu Tutorial Game"

    @background = Gosu::Image.new(self, "art/white_bg.png", false)
    @star_anim = Gosu::Image::load_tiles(self, "art/animation_test.png", 25, 25, false)
    @stars = Array.new
  end

  def update
    if @stars.size < 25
      @stars.push(Star.new(@star_anim))
    end
  end

  def draw
    @background.draw(0, 0, 0)
    @stars.each { |star| star.draw }
  end
end


class Star
  attr_reader :x, :y

  def initialize(animation)
    @animation = animation
    @color = Gosu::Color.new(0xff000000)
    @color.red = rand(256 - 40) + 40
    @color.green = rand(256 - 40) + 40
    @color.blue = rand(256 - 40) + 40
    @x = rand * 640
    @y = rand * 480
  end

  def draw
    img = @animation[Gosu::milliseconds / 100 % @animation.size];
    img.draw(@x - img.width / 2.0, @y - img.height / 2.0, 1, 1, 1, @color, :add)
  end
end

window = Window.new
window.show
