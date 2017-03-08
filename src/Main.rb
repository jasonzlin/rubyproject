require 'gosu'

require './GameState.rb'
#require_relative 'highscoresstate.rb'
require_relative '../src/MenuState'

require_relative 'StateMachine'
require_relative 'Z_ordinals'

SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

class Main < Gosu::Window

  def initialize
    super(SCREEN_WIDTH, SCREEN_HEIGHT, false)
    #Shared::init(self)
    #HighScoresFile::set_window(self)
    StateMachine.window = self
    StateMachine.set_state :mainmenu, :restart# initial state
    self.caption = "The Lost Battle"
  end

  def update
    current_state.update if current_state.respond_to? 'update'
  end

  def draw
    current_state.draw if current_state.respond_to? 'draw'
  end

  def button_down (id)
    current_state.button_down id if current_state.respond_to? 'button_down'
  end

  def button_up (id)
    current_state.button_up id if current_state.respond_to? 'button_up'
  end

  def current_state
    StateMachine.state
  end
end

Main.new.show
