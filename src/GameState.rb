require 'gosu'
require 'matrix'

PLAYER_HEIGHT = 70
PLAYER_WIDTH = 95


module ZOrder
  BACKGROUND, STARS, PLAYER, UI = *0..3
end

class GameState
  def initialize(window)
    $lives =3
    @window = window

    @x = 0
    @difficulty_multiplier = 1.0

    @player = Player.new
    @player.warp(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
    #@background_image = Gosu::Image.new("assets/Backgrounds/purple.png", :tileable => true)
    @score_image = Gosu::Image.new("../assets/PNG/UI/playerLife1_blue.png", :tileable => true)
    @x_image = Gosu::Image.new("../assets/PNG/UI/numeralX.png", :tileable => true)
    @lives_image = Gosu::Image.new("../assets/PNG/UI/numeral#{$lives}.png", :tileable => true)
    @shield_image = Gosu::Image.new('../assets/PNG/Effects/shield3.png', :tileable => true)
    @invincible_text = Gosu::Font.new(180)

    @font = Gosu::Font.new(40)
    @time = Gosu.milliseconds
    @lastEnemySpawnTime = Gosu.milliseconds
    @lastShotTime = Gosu.milliseconds
    @lastPowerUp = Gosu.milliseconds
    @score = 0

    @paused = false
    @asteroids = []
    @enemies = []
    @friendly_projectiles = []
    @enemy_projectiles = []
    @powerups = []
  end

  #Added the WASD method of moving and removed the Gamepad buttons
  def update

    if (Gosu.milliseconds - @time) % 1000 <= 50 * @difficulty_multiplier && !isInvincible(@player)
      @asteroids << Asteroid.new
    end
    if  (Gosu.milliseconds - @lastEnemySpawnTime) / 1000 > 2  && !isInvincible(@player)

      @random = Random.new
      @randomNum = @random.rand(1...3)

      if @randomNum == 1
        @UFO = EnemyUFO.new(@player.playerPosition_x, @player.playerPosition_y)

        @enemies << @UFO
      else

        @Chaser = Chaser.new(@player.playerPosition_x, @player.playerPosition_y)
        @enemies << @Chaser
      end


      @lastEnemySpawnTime = Gosu.milliseconds
    end
    if Gosu.button_down? Gosu::KB_LEFT or Gosu::button_down? Gosu::KB_A #Gosu::button_down? Gosu::GP_LEFT
      @player.turn_left
    end
    if Gosu.button_down? Gosu::KB_RIGHT or Gosu::button_down? Gosu::KB_D #or Gosu::button_down? Gosu::GP_RIGHT
      @player.turn_right
    end
    if Gosu.button_down? Gosu::KB_UP or Gosu::button_down? Gosu::KB_W #or Gosu::button_down? Gosu::GP_BUTTON_0
      @player.accelerate
    end
    #added a reverse one
    if Gosu.button_down?  Gosu::KB_DOWN or Gosu::button_down? Gosu::KB_S
      @player.reverse
    end
      if Gosu::button_down? Gosu::KB_SPACE
      #@player.shoot
      playerShoot
    end

    @score = (Gosu.milliseconds - @time) / 1000
    @difficulty_multiplier = @score / 25.0
    @player.move

    if Gosu.milliseconds - @lastPowerUp > 5000 && !isInvincible(@player)
      @powerup = PowerUp.new
      @powerups << @powerup
      @lastPowerUp = Gosu.milliseconds
    end
    @enemies.each { |enemy|
      enemy.move

      if enemy.x > SCREEN_WIDTH + 150 || enemy.y > SCREEN_HEIGHT + 150|| enemy.x < -150 || enemy.y < -150
        @enemies.delete(enemy)
      end

      if enemy.is_a? EnemyUFO
        UFOShoot(enemy)
      else
        enemy.playerPosition_X = @player.x
        enemy.playerPosition_Y = @player.y
      end

      enemy.turn_left

      if(!isInvincible(@player) && checkCollision(enemy))
        if @player.isShielded
          @player.isShielded = false
          @enemies.delete(enemy)
        else

          $lives -= 1
          @asteroids = []
          @enemies = []
          @enemy_projectiles = []
          @powerups = []
          if $lives <= 0
            showEndScreen
          end
          @player.lastHitTime = Gosu.milliseconds
          @lives_image = Gosu::Image.new("../assets/PNG/UI/numeral#{$lives}.png", :tileable => true)
        end
      end


    }

    @enemy_projectiles.each { |projectile|
      projectile.move
      if projectile.x > SCREEN_WIDTH + 150 || projectile.y > SCREEN_HEIGHT + 150 || projectile.x < -150 || projectile.y < -150
        @enemy_projectiles.delete(projectile)
      end

      if(!isInvincible(@player) && checkCollision(projectile))
        if @player.isShielded
          @player.isShielded = false
          @enemy_projectiles.delete(projectile)
        else
        $lives -= 1
        @asteroids = []
        @enemies = []
        @enemy_projectiles = []
        @powerups = []
        if $lives <= 0
          exit
        end
        @player.lastHitTime = Gosu.milliseconds
        @lives_image = Gosu::Image.new("../assets/PNG/UI/numeral#{$lives}.png", :tileable => true)
        end
        end

    }

    @friendly_projectiles.each { |projectile|
      projectile.move
      if projectile.x > SCREEN_WIDTH + 150 || projectile.y > SCREEN_HEIGHT + 150 || projectile.x < -150 || projectile.y < -150
        @friendly_projectiles.delete(projectile)
      end
      @asteroids.each{ |asteroid|

        if checkProjectile(projectile, asteroid)
          @asteroids.delete(asteroid)
          @friendly_projectiles.delete(projectile)
        end
      }
      @enemies.each { |enemies|
        if checkProjectile(projectile, enemies)
          @enemies.delete(enemies)
          @friendly_projectiles.delete(projectile)
        end
      }
    }

    @powerups.each { |powerup|

      if checkCollision(powerup)
        @player.isShielded = true
        @powerups = []
      end

    }

    @asteroids.each { |asteroid|
      asteroid.move
      if asteroid.x > SCREEN_WIDTH + 150 || asteroid.y > SCREEN_HEIGHT + 150 || asteroid.x < -150 || asteroid.y < -150
        @asteroids.delete(asteroid)
      end
      if(!isInvincible(@player) && checkCollision(asteroid))
        if @player.isShielded
          @player.isShielded = false
          @asteroids.delete(asteroid)
        else
        $lives -= 1
        @asteroids = []
        @enemies = []
        @enemy_projectiles = []
        @powerups = []
        if $lives <= 0
          showEndScreen
        end
        @player.lastHitTime = Gosu.milliseconds
        @lives_image = Gosu::Image.new("../assets/PNG/UI/numeral#{$lives}.png", :tileable => true)
        end
      end
    }

  end

  def draw

    @player.draw
    if @player.isShielded
      @shield_image.draw_rot(@player.x, @player.y, 0, @player.angle)
    end

    #@background_image.draw(@x, 0, 0)

    for asteroid in @asteroids
      asteroid.draw
    end

    for enemy in @enemies
      enemy.draw
    end

    for projectile in @friendly_projectiles
      projectile.draw
    end

    for projectile in @enemy_projectiles
      projectile.draw
    end

    for powerup in @powerups
      powerup.draw
    end

    @font.draw("Time alive: #{@score}", 10, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)

    if isInvincible(@player)
      @invincible_text.draw(3 - ((Gosu.milliseconds - @player.lastHitTime) / 1000), SCREEN_WIDTH / 2 - 50, SCREEN_HEIGHT / 2 - 100, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    end

    @score_image.draw(10, @font.height + 20, 0)
    @x_image.draw(20 + @score_image.width, @font.height + 25, 0)
    @lives_image.draw(@x_image.width + @score_image.width + 30, @font.height + 24, 0)

  end


  def checkCollision(object)
    @object = object

    ((@object.x < @player.x + PLAYER_WIDTH) && (@object.x + @object.width > @player.x) && (@object.y < @player.y + PLAYER_HEIGHT) && (@object.height + @object.y > @player.y))

  end

  def checkProjectile(object, object2)
    @object = object
    @object2 = object2

    ((@object.x < @object2.x + @object2.width) && (@object.x + @object.width > @object2.x) && (@object.y < @object2.y + @object2.height) && (@object.height + @object.y > @object2.y))

  end

  def isInvincible(player)
    @player = player
    Gosu.milliseconds - @player.lastHitTime < 3000

  end

  def playerShoot()

    if Gosu.milliseconds - @lastShotTime > 300

      @projectile = Projectile.new(false)
      @projectile.x = @player.x
      @projectile.y = @player.y
      @projectile.vel_x = Math.cos((@player.angle - 90)* Math::PI / 180) * 2
      @projectile.vel_y = Math.sin((@player.angle - 90)* Math::PI / 180) * 2
      @projectile.angle = @player.angle

      @friendly_projectiles << @projectile
      @lastShotTime = Gosu.milliseconds
    end
  end

  def UFOShoot(ufo)
    @UFO = ufo

    if Gosu.milliseconds - @UFO.lastShootTime > 3000
      @projectile = Projectile.new(true)
      @projectile.x = @UFO.x
      @projectile.y = @UFO.y
      @projectile.vel_x = Math.cos((Gosu.angle(@UFO.x, @UFO.y, @player.x, @player.y) - 90) * Math::PI / 180) * 0.9
      @projectile.vel_y = Math.sin((Gosu.angle(@UFO.x, @UFO.y, @player.x, @player.y)- 90 ) * Math::PI / 180) * 0.9
      @projectile.angle = Gosu.angle(@UFO.x, @UFO.y, @player.x, @player.y)
      @UFO.lastShootTime = Gosu.milliseconds

      @enemy_projectiles << @projectile
    end
  end

  def showEndScreen
    StateMachine.set_state(:endgame,:restart)
  end
end





class Player

  attr_reader :x , :y, :angle
  attr_accessor :lastHitTime, :isShielded

  def initialize
    @image = Gosu::Image.new("../assets/PNG/playerShip1_blue.png")
    @x = @y = @vel_x = @vel_y = @angle = 0.0
    @lastHitTime = -3
    @isShielded = false
  end

  def warp(x, y)
    @x, @y = x, y
  end

  def turn_left
    @angle -= 4.5
  end

  def turn_right
    @angle += 4.5
  end

  def accelerate
    @vel_x += Gosu.offset_x(@angle, 0.5)
    @vel_y += Gosu.offset_y(@angle, 0.5)
  end

  def reverse
      @vel_x += Gosu.offset_x(@angle, -0.5)
      @vel_y += Gosu.offset_y(@angle, -0.5)
  end

  def move
    @x += @vel_x
    @y += @vel_y

    if @x > SCREEN_WIDTH
      @x = SCREEN_WIDTH
    elsif @x < 0
      @x = 0
    end
    if @y > SCREEN_HEIGHT
      @y = SCREEN_HEIGHT
    elsif @y < 0
      @y = 0
    end

    @vel_x *= 0.95
    @vel_y *= 0.95
  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end

  def playerPosition_x
    return @x
  end

  def playerPosition_y
    return @y
  end
end


class Asteroid

  attr_reader :x , :y, :height, :width
  def initialize
    @random = Random.new
    @randomNum = @random.rand(1...5)
    @image = Gosu::Image.new("../assets/PNG/Meteors/meteorBrown_big#{@randomNum}.png")
    @height = @image.height
    @width = @image.width

    if @randomNum == 1
      @x = -@width
      @y = @random.rand(0...SCREEN_HEIGHT)
      @vel_x = @random.rand(1...4)
      @vel_y = @random.rand(-3...3)
    elsif @randomNum == 2
      @x = SCREEN_WIDTH
      @y = @random.rand(0...SCREEN_HEIGHT)

      @vel_x = @random.rand(-4...-1)
      @vel_y = @random.rand(-3...3)
    elsif @randomNum == 3
      @x = @random.rand(0...SCREEN_WIDTH)
      @y = -@height

      @vel_x = @random.rand(-3...3)
      @vel_y = @random.rand(1...4)
    else
      @x = @random.rand(0...SCREEN_WIDTH)
      @y = SCREEN_HEIGHT

      @vel_x = @random.rand(-3...3)
      @vel_y = @random.rand(-4...-1)
    end

  end

  def warp(x, y)
    @x, @y = x, y
  end

  def move
    @x += @vel_x
    @y += @vel_y

    if @x > SCREEN_WIDTH || @x < 0
      #self = null
    end
    if @y > SCREEN_HEIGHT || @y < 0
      #self = null
    end

  end

    def draw
      @image.draw(@x, @y, 1)
    end
end


class EnemyUFO #initially targets you but doesn't chase you
  attr_reader :x , :y, :height, :width
  attr_accessor :angle, :vector, :lastShootTime

  def initialize(playerPosition_X, playerPosition_y)
    @random = Random.new
    @randomNum = @random.rand(1...5)
    @image = Gosu::Image.new('../assets/PNG/ufoBlue.png')
    @x = @y = @vel_x = @vel_y = @angle = 0.0
    @height = @image.height
    @width = @image.width
    @playerPosition_X = playerPosition_X
    @playerPosition_Y = playerPosition_y

    @lastShootTime = Gosu.milliseconds

    if @randomNum == 1
      @x = -@width
      @y = @random.rand(0...SCREEN_HEIGHT)
    elsif @randomNum == 2
      @x = SCREEN_WIDTH
      @y = @random.rand(0...SCREEN_HEIGHT)
    elsif @randomNum == 3
      @x = @random.rand(0...SCREEN_WIDTH)
      @y = -@height
    else
      @x = @random.rand(0...SCREEN_WIDTH)
      @y = SCREEN_HEIGHT
    end

    @vel_x = Math.cos((Gosu.angle(@x, @y, @playerPosition_X, @playerPosition_Y) - 90) * Math::PI / 180) * 2
    @vel_y = Math.sin((Gosu.angle(@x, @y, @playerPosition_X, @playerPosition_Y) - 90) * Math::PI / 180) * 2
  end

  def turn_left
    @angle -= 2.5
    @angle %= 360
  end

  def turn_right
    @angle += 2.5
    @angle %= 360
  end

  def move
   @x += @vel_x
   @y += @vel_y

  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end

end

class Chaser #initially targets you but doesn't chase you
  attr_reader :x , :y, :height, :width
  attr_accessor :angle, :vector, :playerPosition_X, :playerPosition_Y

  def initialize(playerPosition_X, playerPosition_y)
    @random = Random.new
    @randomNum = @random.rand(1...5)
    @image = Gosu::Image.new('../assets/PNG/ufoRed.png')
    @x = @y = @vel_x = @vel_y = @angle = 0.0
    @height = @image.height
    @width = @image.width
    @playerPosition_X = playerPosition_X
    @playerPosition_Y = playerPosition_y

    if @randomNum == 1
      @x = -@width
      @y = @random.rand(0...SCREEN_HEIGHT)
      @vel_x = 1
      @vel_y = @random.rand(-1...1)
    elsif @randomNum == 2
      @x = SCREEN_WIDTH
      @y = @random.rand(0...SCREEN_HEIGHT)

      @vel_x = -1
      @vel_y = @random.rand(-1...1)
    elsif @randomNum == 3
      @x = @random.rand(0...SCREEN_WIDTH)
      @y = -@height

      @vel_x = @random.rand(-1...1)
      @vel_y = 1
    else
      @x = @random.rand(0...SCREEN_WIDTH)
      @y = SCREEN_HEIGHT

      @vel_x = @random.rand(-1...1)
      @vel_y = -1
    end
  end

  def turn_left
    @angle -= 2.5
    @angle %= 360
  end

  def turn_right
    @angle += 2.5
    @angle %= 360
  end

  def move
    @x += @vel_x
    @y += @vel_y

    @vel_x = Math.cos((Gosu.angle(@x, @y, @playerPosition_X, @playerPosition_Y) - 90) * Math::PI / 180) * 2.5
    @vel_y = Math.sin((Gosu.angle(@x, @y, @playerPosition_X, @playerPosition_Y) - 90) * Math::PI / 180) * 2.5
  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end

end

class Enemy

  attr_reader :x , :y, :height, :width
  attr_accessor :angle, :vector

  def initialize
    @random = Random.new
    @randomNum = @random.rand(1...5)
    @image = Gosu::Image.new("../assets/PNG/Enemies/enemyRed#{@randomNum}.png")
    @x = @y = @vel_x = @vel_y = @angle = 0.0
    @height = @image.height
    @width = @image.width


    if @randomNum == 1
      @x = -@width
      @y = @random.rand(0...SCREEN_HEIGHT)
      @vel_x = 1
      @vel_y = @random.rand(-1...1)
    elsif @randomNum == 2
      @x = SCREEN_WIDTH
      @y = @random.rand(0...SCREEN_HEIGHT)

      @vel_x = -1
      @vel_y = @random.rand(-1...1)
    elsif @randomNum == 3
      @x = @random.rand(0...SCREEN_WIDTH)
      @y = -@height

      @vel_x = @random.rand(-1...1)
      @vel_y = 1
    else
      @x = @random.rand(0...SCREEN_WIDTH)
      @y = SCREEN_HEIGHT

      @vel_x = @random.rand(-1...1)
      @vel_y = -1
    end
  end


  def turn_left
    @angle -= 2.5
    @angle %= 360
  end

  def turn_right
    @angle += 2.5
    @angle %= 360
  end

  def move
    @x += @vel_x
    @y += @vel_y
  end

  def draw
    @image.draw_rot(@x, @y, 1, @angle)
  end
end

class PowerUp

  attr_reader :x , :y, :height, :width

  def initialize
    @image = Gosu::Image.new('../assets/PNG/Power-ups/shield_bronze.png')
    @height = @image.height
    @width = @image.width

    @random = Random.new

    @x = @random.rand(0...SCREEN_WIDTH - 50)
    @y = @random.rand(0...SCREEN_HEIGHT - 50)
  end

  def draw
    @image.draw(@x, @y, 1)
  end
end

class Projectile

  attr_accessor :x , :y, :height, :width, :vel_x, :vel_y, :angle

  def initialize(isEnemy)
    @isEnemy = isEnemy
    @random = Random.new
    @randomNum = @random.rand(1...5)
    if isEnemy
      @image = Gosu::Image.new('../assets/PNG/Lasers/laserRed03.png')
    else
      @image = Gosu::Image.new("../assets/PNG/Lasers/laserBlue01.png")
    end
    @height = @image.height
    @width = @image.width
    @angle

  end

  def warp(x, y)
    @x, @y = x, y
  end

  def move
    @x += (@vel_x*10)
    @y += (@vel_y*10)

  end

  def draw
    @image.draw_rot(@x, @y, ZOrder::BACKGROUND, @angle)
  end
end


