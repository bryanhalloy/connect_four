# ==================================================================
module Configs
  SLEEP_SECS = 0.5
  COMPUTER_THINK_SECS = SLEEP_SECS * 2.0
  WIN_IN_A_ROW = 4
  PLAYER_1_MARKER = "🔵"
  PLAYER_2_MARKER = "🔴"
  BOARD_COLUMNS = 7
  BOARD_ROWS = 6
end


# ==================================================================
class Board
  include Configs
  
  def initialize (column_count, row_count)
    @column_count = column_count
    @row_count = row_count
    initiate_squares
  end


  def render_ui
    draw_header
    draw_board
  end


  def get_available_columns
    list = squares.reject { |_, square_object| square_object.occupied }
    list = list.map { |coordinate_key, _| coordinate_key[0] }.uniq.sort
    list
  end


  def drop_chip(column_number_chosen, chip_dropped)
    #Determine what square will be taken (e.g. chip drops to the bottom of the column)
    square_taken_coordinates = squares.select do |coordinate_key, square_object|
      square_object.occupied == false && coordinate_key[0] == column_number_chosen
    end.keys.sort.first
    chosen_square = squares[square_taken_coordinates]
    #Assign dropped chip to that square
    chosen_square.display = chip_dropped
    chosen_square.occupied = true
  end


  def full?
    get_available_columns.empty?
  end


  def winner
    winning_player = nil
    [ ["player1", PLAYER_1_MARKER] ,  ["player2", PLAYER_2_MARKER] ].each do |player_array|
      player_squares = @squares.select { |_coordinates, square| square.display == player_array[1] }
      
      player_squares.each do |coordinates, _square|
        # Build win conditions (four different directions)
        vertical_win_squares = []
        1.upto(WIN_IN_A_ROW - 1) do |num|
          vertical_win_squares << player_squares.keys.include?([coordinates[0], coordinates[1] + num])
        end
        
        horizontal_win_squares = []
        1.upto(WIN_IN_A_ROW - 1) do |num|
          horizontal_win_squares << player_squares.keys.include?([coordinates[0] + num, coordinates[1]])
        end

        diagonal_up_win_squares = []
        1.upto(WIN_IN_A_ROW - 1) do |num|
          diagonal_up_win_squares << player_squares.keys.include?([coordinates[0] + num, coordinates[1] + num])
        end
        
        diagonal_down_win_squares = []
        1.upto(WIN_IN_A_ROW - 1) do |num|
          diagonal_down_win_squares << player_squares.keys.include?([coordinates[0] + num, coordinates[1] - num])
        end

        # Check if a winner in any direction
        is_winner = [vertical_win_squares.all?,
                      horizontal_win_squares.all?, 
                      diagonal_up_win_squares.all?, 
                      diagonal_down_win_squares.all?].any?
        winning_player = player_array[0] if is_winner 
      end
    end
    winning_player
  end

  private

  attr_accessor :column_count, :row_count, :squares

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
    puts "- CONNECT FOUR -"
    puts "\n"
  end

  def draw_board
    drawing = ""
    # Draw squares
    (0.. row_count + 1).each do |row_num|
      (0..column_count + 1).each do |column_num|
        if row_num == 0 || row_num >  row_count
          if column_num == 0 || column_num > column_count
            drawing << "+"
          else
            drawing << "--"
          end
        else
          if column_num == 0 || column_num > column_count
            drawing << "|"
          else
            drawing << @squares[[column_num,row_count - row_num + 1]].to_s
          end
        end
      end
      drawing << "\n"
    end
    # Draw column numbers
    (0..column_count + 1).each do |column_num|
      if column_num == 0 || column_num > column_count
        drawing << "  "
      else
        drawing << column_num.to_s + " "
      end
    end
    # Display
    puts drawing
    puts "\n"
  end

end


# ==================================================================
class Square
  attr_accessor :occupied, :display

  def initialize
    @occupied = false
    @display = "⚫"
  end

  def to_s
    @display
  end
end


# ==================================================================
class Player
  include Configs
  attr_accessor :chip
  attr_reader :name

  def initialize(name, chip)
    @name = name
    @chip = chip
  end

  def execute_turn(board)
    column_number = choose_column(board)
    board.drop_chip(column_number, chip)
  end

  def choose_column(board)
    puts "#{name} (#{chip}) choose a column number:"
  end
end


class Human < Player
end


class Computer < Player
  def choose_column(board)
    super
    sleep(COMPUTER_THINK_SECS)
    selected_column = board.get_available_columns.sample
    puts "#{name} (#{chip}) selected column #{selected_column}."
    selected_column
  end
end


# ==================================================================
class ConnectFour
  include Configs

  def initialize
    @board = Board.new(BOARD_COLUMNS,BOARD_ROWS)
    @player1 = Computer.new("Bluebee", PLAYER_1_MARKER)
    @player2 = Computer.new("Red Rover", PLAYER_2_MARKER)
  end

  def play_game
    system("clear")
    @board.render_ui
    sleep(SLEEP_SECS)

    player1_turn = true
    loop do
      if player1_turn
        @player1.execute_turn(@board)
        player1_turn = false
      else
        @player2.execute_turn(@board)
        player1_turn = true
      end

      sleep(SLEEP_SECS)
      system("clear")

      @board.render_ui
      sleep(SLEEP_SECS)

      winning_player = @board.winner
      if winning_player
        puts "#{winning_player} wins!!"
        break
      end

      break if @board.full?
    end
    display_goodbye
  end

  private

  def display_goodbye
    puts "\n\n"
    puts "----------------------"
    puts "Thank you for playing. Goodbye."
  end

end

# ==================================================================
ConnectFour.new.play_game
