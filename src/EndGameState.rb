require_relative 'menu.rb'

class EndGameState


  def initialize (window)
    @window = window
    @background = Gosu::Image.new(window, '../assets/MenuItems/gameover.jpg', false)
    #@background = Shared::background
    #@splash = Shared::title
    @time = Gosu.milliseconds
  end

  def update
    #@background.update
    if Gosu.milliseconds - @time > 4000
      close_game
    end
  end

  def draw
    #@background.draw
    #@splash.draw(0, 0, ZOrdinals::TITLE)
    @background.draw(300, 180, ZOrdinals::TITLE)
  end

  def button_down (id)
    if id == Gosu::KbEscape then
      @window.close
    end

  end

  def close_game
    @window.close
  end
end
