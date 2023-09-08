SLEEP_SECS = 0.01
WIN_IN_A_ROW = 4
PLAYER_1_MARKER = "🔵"
PLAYER_2_MARKER = "🔴"



# Nouns + Verbs:
# board
# -achieve four in a row
# square
# chip
# player
# -takes a turn


class Board
  attr_accessor :column_count, :row_count, :squares
  
  def initialize (column_count, row_count)
    self.column_count = column_count
    self.row_count = row_count
    initiate_squares
  end


  def initiate_squares
    @squares = {}
    (1..column_count).each do |column_num|
      (1..row_count).each do |row_num|
        @squares[[column_num,row_num]] = Square.new
      end
    end
  end


  def draw_board
    drawing = ""
    #Draw squares
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
    #Draw column numbers
    (0..column_count + 1).each do |column_num|
      if column_num == 0 || column_num > column_count
        drawing << "  "
      else
        drawing << column_num.to_s + " "
      end
    end
    puts drawing

    puts "----- debug---"
  end

  def get_available_columns
    list = @squares.reject { |_, square_object| square_object.occupied }
    list = list.map { |coordinate_key, _| coordinate_key[0] }.uniq.sort
    list
  end


  def drop_chip(column_number, chip)
    list = @squares.select do |coordinate_key, square_object|
      square_object.occupied == false && coordinate_key[0] == column_number
    end
    coordinates = list.keys.sort[0]
    chosen_square = @squares[coordinates]
    chosen_square.display = chip
    chosen_square.occupied = true
  end

  def full
    get_available_columns.empty?
  end

  def winner
    winning_player = nil
    [ ["player1", PLAYER_1_MARKER] ,  ["player2", PLAYER_2_MARKER] ].each do |player_array|
      player_squares = @squares.select { |_coordinates, square| square.display == player_array[1] }
      
      player_squares.each do |coordinates, _square|
        # check vertical win condition
        if player_squares.keys.include?([coordinates[0], coordinates[1] + 1]) &&
          player_squares.keys.include?([coordinates[0], coordinates[1] + 2]) && 
          player_squares.keys.include?([coordinates[0], coordinates[1] + 3])
          winning_player = player_array[0] 
        
        #check horizontal win condition
        elsif player_squares.keys.include?([coordinates[0] + 1, coordinates[1]]) &&
          player_squares.keys.include?([coordinates[0] + 2, coordinates[1]]) && 
          player_squares.keys.include?([coordinates[0] + 3, coordinates[1]])
          winning_player = player_array[0] 

        #check diagonal up win condition
        elsif player_squares.keys.include?([coordinates[0] + 1, coordinates[1] + 1]) &&
          player_squares.keys.include?([coordinates[0] + 2, coordinates[1] + 2]) && 
          player_squares.keys.include?([coordinates[0] + 3, coordinates[1] + 3])
          winning_player = player_array[0] 

        #check diagonal down win condition
        elsif player_squares.keys.include?([coordinates[0] + 1, coordinates[1] - 1]) &&
          player_squares.keys.include?([coordinates[0] + 2, coordinates[1] - 2]) && 
          player_squares.keys.include?([coordinates[0] + 3, coordinates[1] - 3])
          winning_player = player_array[0] 
        end
      end
    end
    
  
    # select every non-empty square
    #   start in bottom left, and move across row, then up to next column
    #   for each non-empty square
    #     Get its color
    #       check and see if the next three above it are same color
    #       check and see if three diagonal (up and right) are same color)
    #       Check and see if three to the right are same color
    #     If any above are true, then mark them as winner
    #   else go to the next non-empty square

    winning_player
  end





end


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



class Player
  attr_accessor :name, :chip

  def initialize(name, chip)
    self.name = name
    self.chip = chip
  end

  def execute_turn(board)
    column_number = choose_column(board)
    board.drop_chip(column_number, self.chip) # board update backend squares
    # determine winner (move outside)
  end
end


class Human < Player
end

class Computer < Player
  def choose_column(board)
    puts "#{name} (#{chip})- make a selection:"
    selected_column = board.get_available_columns.sample
    puts "#{name} (#{chip}) selected column #{selected_column}"
    selected_column
  end
end



class ConnectFour
  def initialize
    @board = Board.new(7,6)
    @player1 = Computer.new("Bluebee", PLAYER_1_MARKER)
    @player2 = Computer.new("Red Rover", PLAYER_2_MARKER)

  end

  def play_game
    system("clear")
    @board.draw_board
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
      @board.draw_board
      sleep(SLEEP_SECS)

      
      winning_player = @board.winner
      if winning_player
        puts "We have a winner! #{winning_player}"
        break
      end

      break if @board.full

    end
    

    #   prompt_turn_input
    #   update_board
    #   determine winner or tie
    #   break if win or tie
    # display goodbye
  end


end


ConnectFour.new.play_game
