module StateMachine
  @current_state = @window
  @states = {
      game: GameState,
      mainmenu: MainMenuState,
      endgame: EndGameState
      #highscores: HighScoresState,
      #playerselection: PlayerSelectionState
  }
  @instanciated_states = {}

  def self.window=(window)
    @window = window
  end

  def self.set_state (new_state, start_method, *args)
    @current_state = (start_method == :restart ? @states[new_state].new(@window, *args) : @instanciated_states[new_state])
    @instanciated_states[new_state] = @current_state
  end

  def self.state
    @current_state
  end
end
