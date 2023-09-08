require "pry"

# ==================================================================
module Configs
  SLEEP_SECS = 1.0
  COMPUTER_THINK_SECS = SLEEP_SECS * 2.0
  WIN_IN_A_ROW = 4
  PLAYER_1_MARKER = {normal: "🔵", win: "🌀"}
  PLAYER_2_MARKER = {normal: "🔴", win: "❌"}
  EMPTY_MARKER = "⚫"
  BOARD_COLUMNS = 7
  BOARD_ROWS = 6
  START_PLAYER_NUMBER = [1,2].sample

  MARGIN_SPACES = 20

  UI_WIDTH = 3 + MARGIN_SPACES * 2 + BOARD_COLUMNS * 2

  SHOW_MOVE_HISTORY = true
  MESSAGE_BOX_MIN_LINES = 4

  
  
  COMPUTER_NAMES = [
    "HAL 9000",          # From "2001: A Space Odyssey"
    "R2-D2",             # From "Star Wars"
    "C-3PO",             # From "Star Wars"
    "WALL-E",            # From "WALL-E"
    "T-800",             # From "Terminator"
    "Bender",            # From "Futurama"
    "Ava",               # From "Ex Machina"
    "Mother",            # From "Alien"
    "TARS",              # From "Interstellar"
    "Samantha",          # From "Her"
    "Chappie",           # From "Chappie"
    "RoboCop",           # From "RoboCop"
    "Eve",               # From "WALL-E"
    "Alexa",             # From Amazon
    "Siri"              # From Apple
  ]
end


# ==================================================================
class Board
  attr_accessor :current_message, :turn_player
  include Configs
  
  def initialize (column_count, row_count)
    @column_count = column_count
    @row_count = row_count
    initiate_squares
    @move_history = '-- Game start --'
    @current_message = 'Welcome to Connect Four! Created by Bryan Halloy'
    @turn_player = nil
  end

  def setup_players(player1, player2)
    @player1 = player1
    @player2 = player2
  end

  def render_ui
    system("clear")
    draw_header
    draw_board
    draw_chip_legend
    draw_message_box
    draw_move_history
    sleep(SLEEP_SECS)
  end


  def get_available_columns
    list = squares.reject { |_, square_object| square_object.occupied }
    list = list.map { |coordinate_key, _| coordinate_key[0] }.uniq.sort
    list
  end


  def drop_chip(column_number_chosen, player_object)
    #Determine what square will be taken (e.g. chip drops to the bottom of the column)
    square_taken_coordinates = squares.select do |coordinate_key, square_object|
      square_object.occupied == false && coordinate_key[0] == column_number_chosen
    end.keys.sort.first
    chosen_square = squares[square_taken_coordinates]
    #Assign dropped chip to that square
    chosen_square.display = player_object.chip_normal
    chosen_square.occupied = true
    chosen_square.occupied_by = player_object
    self.move_history =  "#{player_object.chip_normal}#{square_taken_coordinates} - #{player_object.name}\n" + move_history
  end


  def full?
    get_available_columns.empty?
  end


  def winner
    winning_player = nil
    
    [@player1, @player2].each do |player_object|
      player_squares = @squares.select { |_coordinates, square| square.occupied_by == player_object }
      win_check_hash = {any_win: {achieved_bool: false, winning_squares: []}, 
                        vertical_win: {}, 
                        horizontal_win: {}, 
                        diagonal_up_win: {}, 
                        diagonal_down_win: {}}

      player_squares.each do |coordinates, _square|
        
        # Build win conditions (four different directions)
        #Check for vertical win
        win_check_hash[:vertical_win][:squares_needed] = []
        win_check_hash[:vertical_win][:squares_occupied_bool] = []
        win_check_hash[:vertical_win][:achieved_bool] = false
        1.upto(WIN_IN_A_ROW - 1) do |num|
          square_needed = ([coordinates[0], coordinates[1] + num])
          win_check_hash[:vertical_win][:squares_needed] << square_needed
          win_check_hash[:vertical_win][:squares_occupied_bool] << player_squares.keys.include?(square_needed)
        end
        win_check_hash[:vertical_win][:achieved_bool] = true if win_check_hash[:vertical_win][:squares_occupied_bool].all?
        
        #Check for horizontal win
        win_check_hash[:horizontal_win][:squares_needed] = []
        win_check_hash[:horizontal_win][:squares_occupied_bool] = []
        win_check_hash[:horizontal_win][:achieved_bool] = false
        1.upto(WIN_IN_A_ROW - 1) do |num|
          square_needed = ([coordinates[0] + num, coordinates[1]])
          win_check_hash[:horizontal_win][:squares_needed] << square_needed
          win_check_hash[:horizontal_win][:squares_occupied_bool] << player_squares.keys.include?(square_needed)
        end
        win_check_hash[:horizontal_win][:achieved_bool] = true if win_check_hash[:horizontal_win][:squares_occupied_bool].all?

        #Check for diagonal_up win
        win_check_hash[:diagonal_up_win][:squares_needed] = []
        win_check_hash[:diagonal_up_win][:squares_occupied_bool] = []
        win_check_hash[:diagonal_up_win][:achieved_bool] = false
        1.upto(WIN_IN_A_ROW - 1) do |num|
          square_needed = ([coordinates[0] + num, coordinates[1] + num])
          win_check_hash[:diagonal_up_win][:squares_needed] << square_needed
          win_check_hash[:diagonal_up_win][:squares_occupied_bool] << player_squares.keys.include?(square_needed)
        end
        win_check_hash[:diagonal_up_win][:achieved_bool] = true if win_check_hash[:diagonal_up_win][:squares_occupied_bool].all?

        #Check for diagonal_down win
        win_check_hash[:diagonal_down_win][:squares_needed] = []
        win_check_hash[:diagonal_down_win][:squares_occupied_bool] = []
        win_check_hash[:diagonal_down_win][:achieved_bool] = false
        1.upto(WIN_IN_A_ROW - 1) do |num|
          square_needed = ([coordinates[0] - num, coordinates[1] - num])
          win_check_hash[:diagonal_down_win][:squares_needed] << square_needed
          win_check_hash[:diagonal_down_win][:squares_occupied_bool] << player_squares.keys.include?(square_needed)
        end
        win_check_hash[:diagonal_down_win][:achieved_bool] = true if win_check_hash[:diagonal_down_win][:squares_occupied_bool].all?

        # Check if a winner in any direction
        [:vertical_win, :horizontal_win, :diagonal_up_win, :diagonal_down_win].each do |win_condition|
          if win_check_hash[win_condition][:achieved_bool] == true
            win_check_hash[:any_win][:achieved_bool] = true

            win_check_hash[:any_win][:winning_squares] << coordinates
            win_check_hash[win_condition][:squares_needed].each do |winning_coordinate|
              win_check_hash[:any_win][:winning_squares] << winning_coordinate
            end
            win_check_hash[:any_win][:winning_squares].uniq!
          end
        end

        if win_check_hash[:any_win][:achieved_bool] == true
          winning_player = player_object
          #change winning squares to winning markers
          p win_check_hash[:any_win][:winning_squares]
          win_check_hash[:any_win][:winning_squares].each do |winning_square|
            squares[winning_square].display = player_object.chip_win
          end
        end
      end
    end
    winning_player
  end

  private

  attr_accessor :column_count, :row_count, :squares, :move_history

  def initiate_squares
    @squares = {}
    (1..column_count).each do |column_num|
      (1..row_count).each do |row_num|
        @squares[[column_num,row_num]] = Square.new
      end
    end
  end

  def draw_header
    puts "\n"
    puts "=" * UI_WIDTH
    puts "-" + "CONNECT FOUR".center(UI_WIDTH-2) + "-"
    puts "=" * UI_WIDTH
    puts "\n"
  end


  def draw_chip_legend
    case @turn_player
    when 1
      player_1_pointer = " <-"
      player_2_pointer = ""
    when 2
      player_1_pointer = ""
      player_2_pointer = " <-"
    end
    puts "#{@player1.chip_normal}: #{@player1.name}#{player_1_pointer}"
    puts "#{@player2.chip_normal}: #{@player2.name}#{player_2_pointer}"
    puts "\n"
  end


  def draw_message_box
    puts "-" * UI_WIDTH
    formatted_message = line_wrap(current_message,UI_WIDTH).center(UI_WIDTH)
    formatted_message << "\n" * [MESSAGE_BOX_MIN_LINES - formatted_message.split("\n").size, 0].max 
    puts formatted_message
    puts "-" * UI_WIDTH
  end


  def line_wrap(text, width)
    lines = []
    current_line = ''
    text.split(' ').each do |word|
      if current_line.length + word.length + 1 <= width
        space = current_line.length == 0 ? '' : ' '
        current_line = current_line + space + word
      else
        lines << current_line
        current_line = word
      end
    end
    lines << current_line unless current_line.empty?
    lines.join("\n")
  end

  def draw_board
    drawing = ""
    # Draw squares
    (0.. row_count + 1).each do |row_num|
      (0..column_count + 1).each do |column_num|
        scribble_to_add = ""
        if row_num == 0 || row_num >  row_count
          if column_num == 0
            scribble_to_add << " +"
          elsif column_num > column_count
            scribble_to_add << "+"
          else
            scribble_to_add << "--"
          end
        else
          scribble_to_add << (row_count - row_num + 1).to_s if column_num == 0 # Display row number
          if column_num == 0 || column_num > column_count
            scribble_to_add << "|"
          else
            scribble_to_add << @squares[[column_num,row_count - row_num + 1]].to_s
          end
        end
        #Prepend margin if applicable
        scribble_to_add.prepend(" " * MARGIN_SPACES) if column_num == 0
        scribble_to_add << (" " * MARGIN_SPACES) if column_num == column_count + 1
        
        drawing << scribble_to_add
      end
      drawing << "\n"
    end
    # Draw column numbers
    available_columns = get_available_columns
    drawing << (" " * MARGIN_SPACES)
    (0..column_count + 1).each do |column_num|
      if column_num == 0 || column_num > column_count
        drawing << "  "
      else
        if available_columns.include?(column_num)
          drawing << column_num.to_s + " "
        else
          drawing << "  "
        end
      end
    end
    drawing << (" " * MARGIN_SPACES)

    # Display
    puts drawing
    puts "\n"
  end


  def draw_move_history
    if SHOW_MOVE_HISTORY
      puts "\n-- Recent moves --"
      puts move_history 
    end
  end
end


# ==================================================================
class Square
  attr_accessor :occupied, :display, :occupied_by
  include Configs

  def initialize
    @occupied = false
    @display = EMPTY_MARKER
    @occupied_by = nil
  end

  def to_s
    @display
  end
end


# ==================================================================
class Player
  include Configs
  attr_accessor :chip_normal, :chip_win
  attr_reader :name

  def initialize(name, chip)
    @name = name
    @chip_normal = chip[:normal]
    @chip_win = chip[:win]
  end

  def execute_turn(board)
    column_number = choose_column(board)
    board.drop_chip(column_number, self)
  end

  def choose_column(board)
    board.current_message = "#{name} (#{chip_normal}) please choose a column number.."
  end
end


class Human < Player
end


class Computer < Player
  def choose_column(board)
    super
    board.render_ui
    # sleep(COMPUTER_THINK_SECS)
    selected_column = board.get_available_columns.sample
    board.current_message = "#{name} (#{chip_normal}) selected column #{selected_column}."
    selected_column
  end
end


# ==================================================================
class ConnectFour
  include Configs


  def initialize
    @board = Board.new(BOARD_COLUMNS,BOARD_ROWS)
    @player1 = Computer.new(COMPUTER_NAMES.sample + ' (AI)', PLAYER_1_MARKER)
    @player2 = Computer.new(COMPUTER_NAMES.sample + ' (AI)', PLAYER_2_MARKER)
    @board.setup_players(@player1,@player2)
    @turn_player = START_PLAYER_NUMBER
    @board.turn_player = @turn_player
  end

  def play_game
    @board.render_ui

    loop do
      if @turn_player == 1
        @player1.execute_turn(@board)
        @turn_player = 2
      else
        @player2.execute_turn(@board)
        @turn_player = 1
      end
      @board.turn_player = @turn_player

      @board.render_ui

      winning_player = @board.winner
      if winning_player
        @board.current_message = "#{winning_player.name} wins!!"
        @board.current_message << "\n(#{winning_player.chip_normal} -> #{winning_player.chip_win})"
        @board.render_ui
        break
      end

      break if @board.full?
    end
    display_goodbye
  end

  private

  def display_goodbye
    puts "\n\n"
    puts "-" * UI_WIDTH
    puts "\n"
    puts "Game over. Goodbye."
  end

end

# ==================================================================
1.times do 
  ConnectFour.new.play_game
end
