require 'gosu'

class Game_Window < Gosu::Window
  attr_accessor :board, :mat_locations, :enemies

  def initialize
    super(600, 600, false)
    self.caption = "untitled rpg"

    initialize_board
    place_materials
    remember_material_locations

    @background = Gosu::Image.new(self, "art/simple_background.png", true)
    @player = Player.new(self)
    @player.warp(300, 300)
    @materials = Materials.new(self, @board)
    @points_hud = Gosu::Font.new(self, 'Arial', 30)

    @points = 0
    @updated = false

    @enemies = Array.new
    @towers = Array.new

    @max_enemies = 100


    @spawn_time = 3.0
    @spawn_timer = Time.now

    @time = Time.now
    @enemy_timer = Time.now
    @check_hit_time = Time.now
    @tower_fire_time = Time.now
  end

  def update
    if @player.player_health > 1
      update_all
    elsif @player.player_health < 1 && @updated == false
      high_scores = File.open("high_scores.txt", "a")
      high_scores.puts("Player ---- #{@points}")
      @updated = true
    end
  end

  def update_all
    if button_down? Gosu::KbLeft or button_down? Gosu::KbA then
      @player.move_left
    end
    if button_down? Gosu::KbRight or button_down? Gosu::KbD then
      @player.move_right
    end
    if button_down? Gosu::KbUp or button_down? Gosu::KbW then
      @player.move_up
    end
    if button_down? Gosu::KbDown or button_down? Gosu::KbS then
      @player.move_down
    end
    if button_down? Gosu::KbZ or button_down? Gosu::KbO then
      @player.activate
    end
    if button_down? Gosu::KbI
      @player.build
    end
    if (button_down? Gosu::KbX or button_down? Gosu::KbP) and Time.now > @time + 0.2 then
      @player.attack
      @time = Time.now
    end

    if @enemies.count < @max_enemies
      spawn_enemies
    end

    if Time.now - 1 > @tower_fire_time
      @tower_fire_time = Time.now
      @towers.each { |tower| tower.arrow = nil}
      fire_towers
    end


    if @towers.count > 0
      @towers.each do |tower|
        tower.arrow.fly unless tower.arrow == nil
      end
    end

    @enemies.each do |enemy|
      enemy.chase(@player.x, @player.y)
      enemy.swarm
    end

    remember_material_locations
    remove_enemies_and_rocks
    check_hits
    @player.update
  end

  def spawn_enemies
    if Time.now - 2 > @enemy_timer
      @enemy_timer = Time.now
      unless @spawn_time < 0.5
        @spawn_time -= 0.1
      end
      puts(@spawn_time)
    end

    if Time.now - @spawn_time > @spawn_timer
      @spawn_timer = Time.now
      @enemies << Swarmer.new(self)
    end
  end

  def check_hits
    @enemies.each do |enemy|
      if Time.now - 0.25 > @check_hit_time
        if enemy.x.between?(@player.x, @player.x + 10) &&
           enemy.y.between?(@player.y, @player.y + 10)
          @player.player_health -= 5
          @check_hit_time = Time.now
        end
      end
      @player.rocks.each do |rock|
        if enemy.x.between?(rock.x, rock.x + 5) &&
           enemy.y.between?(rock.y, rock.y + 5)
          @points += 100
          enemy.alive = false
          rock.hit = true
        end
      end
      @towers.each do |tower|
        unless tower.arrow == nil || tower.arrow.hit == true
          if enemy.x.between?(tower.arrow.x, tower.arrow.x + 5) &&
             enemy.y.between?(tower.arrow.y, tower.arrow.y + 5)
            @points += 100
            enemy.alive = false
            tower.arrow.hit = true
          end
        end
      end
    end
  end

  def remove_enemies_and_rocks
    ## remove dead enemies
    delete_indicies = []
    @enemies.each_with_index do |enemy, index|
      if enemy.alive == false
        delete_indicies << index
      end
    end
    delete_indicies.each {|index| @enemies.delete_at(index)}

    ## remove hit rocks
    delete_indicies = []
    @player.rocks.each_with_index do |rock, index|
      if rock.hit == true
        delete_indicies << index
      end
    end
    delete_indicies.each {|index| @player.rocks.delete_at(index)}
  end

  def initialize_board
    @board = Array.new(20) { Array.new(20, :empty)}
  end

  def place_materials
    20.times {@board[(rand * 19).to_i][(rand * 19).to_i] = Tree.new(self)}
    20.times {@board[(rand * 19).to_i][(rand * 19).to_i] = Stone.new(self)}
  end

  def fire_towers
    @towers.each { |tower| tower.shoot(@enemies) }
  end

  def remember_material_locations
    @mat_locations = []
    @towers = []

    i = 0
    while i < 20
      q = 0
      while q < 20
        if @board[i][q].class == Stone || @board[i][q].class == Tree ||
                                          @board[i][q].class == Tower
          @mat_locations << [i, q]
          if @board[i][q].class == Tower
            @towers << @board[i][q]
          end
        end
        q += 1
      end
      i += 1
    end
  end

  def draw()
    @background.draw(0, 0, 0)
    @player.draw
    @materials.draw
    @enemies.each {|enemy| enemy.draw}
    @towers.each do |tower|
      tower.arrow.draw unless tower.arrow == nil
    end
    @points_hud.draw("Points: #{@points}", 250, 25, 3)
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end

  class Materials
    def initialize(window, board)
      @board = board
    end

    def draw()
      row = 0
      while row < 20
        column = 0
          while column < 20
            if @board[row][column].class == Tree
              @board[row][column].tree.draw(row * 30, column * 30, 1, 1, 1,
                                       @board[row][column].color, :default)
            elsif @board[row][column].class == Stone
              @board[row][column].stone.draw(row * 30, column * 30, 1, 1, 1,
                                       @board[row][column].color, :default)
            elsif @board[row][column].class == Tower
              @board[row][column].tower.draw(row * 30, column * 30, 1)
            end
            column += 1
          end
        row += 1
      end
    end
  end

  class Tree
    attr_accessor :health, :color, :tree
    def initialize(window)
      @color = Gosu::Color.new(0xffffffff)
      @tree = Gosu::Image.new(window, "art/tree.png", true)
      @health = 75
    end

  end

  class Stone
    attr_accessor :health, :color, :stone
    def initialize(window)
      @color = Gosu::Color.new(0xffffffff)
      @stone = Gosu::Image.new(window, "art/stone.png", true)
      @health = 100
    end
  end

end


class Player
  attr_accessor :x, :y, :player_health, :rocks
  def initialize(window)
    @window = window
    @hud = Gosu::Font.new(@window, 'Arial', 16)
    @inventory = Hash.new(0)
    @inventory[:sticks] = 0
    @inventory[:rocks] = 0

    @player_direction = :North
    @player_health = 100

    @simple_player = Gosu::Image.new(window, "art/simple_player.png", true)
    @x = @y = 0

    @rocks = Array.new
  end

  def warp(x, y)
    @x, @y = x, y
  end

  def activate
    if harvestable_location?(@window) != false
      x = harvestable_location?(@window)[0]
      y = harvestable_location?(@window)[1]
      if @window.board[x][y].class == Game_Window::Tree
        if @window.board[x][y].health > 1
          @window.board[x][y].health -= 1
          @window.board[x][y].color.alpha -= 2
        else
          @window.board[x][y] = :empty
        end
        @inventory[:sticks] += 1
      elsif @window.board[x][y].class == Game_Window::Stone
        if @window.board[x][y].health > 1
          @window.board[x][y].health -= 1
          @window.board[x][y].color.alpha -= 2
        else
          @window.board[x][y] = :empty
        end
        @inventory[:rocks] += 1
      end
    else
      return false
    end
  end

  def build
    if harvestable_location?(@window) == false && @inventory[:sticks] >= 150
      @inventory[:sticks] -= 150
      @window.board[@x/30][@y/30] = Tower.new(@x, @y, @window)
      return true
    else
      return false
    end
  end

  def attack
    if @inventory[:rocks] > 9
      @inventory[:rocks] -= 10
      @rocks << Rock.new(@window, @x, @y, @player_direction)
    end
  end

  def move_right
    @x %= 600
    @x += 2
    @player_direction = :East

    if impassable?
      @x -= 6
    end
  end

  def move_left
    @x %= 600
    @x -= 2
    @player_direction = :West

    if impassable?
      @x += 6
    end
  end

  def move_up
    @y %= 600
    @y -= 2
    @player_direction = :North

    if impassable?
      @y += 6
    end
  end

  def move_down
    @y %= 600
    @y += 2
    @player_direction = :South

    if impassable?
      @y -= 6
    end
  end

  def impassable?
    @window.mat_locations.each do |location|
      if @x.between?((location[0] * 30), (location[0] * 30 + 25)) &&
         @y.between?((location[1] * 30), (location[1] * 30 + 25))
        return true
      end
    end
    return false
  end

  def harvestable_location?(game_window)
    game_window.mat_locations.each do |location|
      if @x.between?((location[0] * 30 - 8), (location[0] * 30 + 33)) &&
         @y.between?((location[1] * 30 - 8), (location[1] * 30 + 33))
        return location
      end
    end
    return false
  end

  def update()
    @rocks.each { |rock| if rock.delete == true then @rocks.shift end}

    @rocks.each {|rock| rock.update}
  end

  def draw()
    @rocks.each {|rock| rock.draw}

    @hud.draw("Inventory:", 5, 580, 3)
    @hud.draw("Sticks: #{@inventory[:sticks]}", 85, 580, 3)
    @hud.draw("Rocks: #{@inventory[:rocks] / 10}", 170, 580, 3)
    @hud.draw("Health: #{@player_health}", 5, 564, 3)

    if @player_health > 0
      @simple_player.draw(@x, @y, 2)
    end
  end

  class Rock
    attr_accessor :x, :y, :delete, :hit
    def initialize(window, player_x, player_y, direction)
      @direction = direction

      @x = player_x
      @y = player_y

      @time = Time.now

      @hit = false
      @delete = false
      @Life_span = 1
      @rock = Gosu::Image.new(window, 'art/rock.png', false)
    end

    def update
      if @direction == :North
        @y -= 3
      elsif @direction == :South
        @y += 3
      elsif @direction == :East
        @x += 3
      elsif @direction == :West
        @x -= 3
      end
      if Time.now - @Life_span > @time
        @delete = true
      end
    end

    def draw
      @rock.draw(@x, @y, 2)
    end
  end
end

class Swarmer
  attr_accessor :x, :y, :alive
  def initialize(window)
    @window = window
    @swarmer = Gosu::Image.new(@window, "art/swarmer.png", false)
    @health = 100
    @x = 0
    @y = (rand * 600).to_i
    @alive = true
  end

  def chase(player_x, player_y)
    if @alive == true
      if @x < player_x
        @x += 0.5
        if impassable?
          @x -= 3
        end
      elsif @x > player_x
        @x -= 0.5
        if impassable?
          @x += 3
        end
      end

      if @y < player_y
        @y += 0.5
        if impassable?
          @y -= 3
        end
      elsif @y > player_y
        @y -= 0.5
        if impassable?
          @y += 3
        end
      end
    end
  end

  def impassable?
    @window.mat_locations.each do |location|
      if @x.between?((location[0] * 30), (location[0] * 30 + 25)) && \
         @y.between?((location[1] * 30), (location[1] * 30 + 25))
        return true
      end
    end
    return false
  end

  def swarm
    @window.enemies.each do |enemy|
      if @x.between?(enemy.x , enemy.x + 20) &&
         @y.between?(enemy.y, enemy.y + 20) &&
         enemy != self
        flip = (rand * 4).to_i
        if flip == 0
          @x -= 3
          @y -= 3
        elsif flip == 1
          @x += 3
          @y -= 3
        elsif flip == 2
          @x -= 3
          @y += 3
        elsif flip == 3
          @x += 3
          @y += 3
        end
      end
    end
  end

  def spawn_swarmer(x, y)
    @x = x ;@y = y
  end

  def draw
    @swarmer.draw(@x, @y, 2)
  end
end

class Tower
  attr_accessor :tower, :arrow
  def initialize(x, y, window)
    @Tower_range = 150
    @x = x
    @y = y
    @window = window
    @tower = Gosu::Image.new(@window, "art/tower.png", false)
    @arrow = nil
  end

  def shoot(enimies)
    enimies.each do |enemy|
      if ((enemy.x - @x).abs + (enemy.y - @y).abs) < @Tower_range
        return @arrow = Arrow.new(@x, @y, enemy.x, enemy.y, @window)
      end
    end
  end

  class Arrow
    attr_accessor :x, :y, :hit
    def initialize(x, y, enemy_x, enemy_y, window)
      @hit = false
      @x = x
      @y = y
      @enemy_x = enemy_x
      @enemy_y = enemy_y
      @arrow = Gosu::Image.new(window, "art/bolder.png", false)
    end

    def fly
      if (@x - @enemy_x).abs < 3 && (@y - @enemy_y).abs < 3
        @x < @enemy_x ? @x += 1 : @x -= 1
        @y < @enemy_y ? @y += 1 : @y -= 1
      else
        @x < @enemy_x ? @x += 3 : @x -= 3
        @y < @enemy_y ? @y += 3 : @y -= 3
      end

      if @x == @enemy_x && @y == @enemy_y
        @hit = true
      end
    end

    def draw
      unless @arrow == nil
        @arrow.draw(@x, @y, 1)
      end
    end
  end
end



game_window = Game_Window.new
game_window.show
