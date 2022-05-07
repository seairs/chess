# frozen_string_literal: true

require_relative 'piece'

# Class determining King behavior
class King < ChessPiece
  def initialize(color, position)
    @moveset = [
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0]
    ]
    @icon = color ? '♚' : '♔'
    @possible_moves = []
    super
  end

  # King class needs a special find_possible_moves method because it cannot move itself into checkmate (and it can't travel infinitely like bishop/queen/rook)
  def find_possible_moves(positions)
    @possible_moves = []

    # Add each of the king's moves to the current position
    @moveset.each do |move|
      x = @x_position + move[0]
      y = @y_position + move[1]

      # If the hypothetical move stays within the confines of the board
      if (0..7).cover?(x) && (0..7).cover?(y)
        # Skip this process if the move is not onto a blank space or a piece of the opposite color
        # Need to use unless here, otherwise we'll get a bug when we try to find the .color attribute of a nil object
        next unless positions[x][y].nil? || positions[x][y].color != @color

        # Clone the current board positions
        test_positions = Board.clone(positions)
        # Pretend that we've moved the king from his current position ...
        test_positions[@x_position][@y_position] = nil
        # ... and moved him to the hypothetical move position 
        # Case/when to differentiate between white/black King
        case @color
        when 'white'
          test_king = King.new(true, [x, y])
        when 'black'
          test_king = King.new(false, [x, y])
        end
        test_positions[x][y] = test_king

        # We need to check if, after our cloned King's hypothetical move, he has moved himself into a position where pieces of the enemy color can capture him in their next move
        test_positions.flatten.select { |square| square !=  nil && square.color != @color }.each do |piece|
          if piece.instance_of?(King)
            piece.moveset.each do |test_move|
              a = piece.x_position + test_move[0]
              b = piece.y_position + test_move[1]

              if (0..7).cover?(x) && (0..7).cover?(y)
                piece.possible_moves << [a, b]
              end
            end
          else
            piece.find_possible_moves(test_positions)
          end
        end
        @possible_moves << [x, y] if !test_king.in_check?(test_positions) && (positions[x][y].nil? || positions[x][y].color != @color)
      end
    end
  end

  def in_check?(positions)
    in_check = false
    positions.flatten.select { |piece| !piece.nil? && piece.color != @color }.each do |piece|
      if piece.instance_of? Pawn
        piece.possible_moves.each do |move|
          in_check = true if move[1] != piece.y_position && move == [@x_position, @y_position]
        end
      else
        in_check = true if piece.possible_moves.include?([@x_position, @y_position])
      end
    end
    in_check
  end
end
