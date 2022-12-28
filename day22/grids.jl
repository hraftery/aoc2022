using SparseArrays

# The following definitions work well if you create your grid with something like:
#
#    ys = Vector{Int}(); xs = Vector{Int}(); cs = Vector{Cell}();
#    push!(ys, 1); push!(xs, 1); push!(cs, tile);
#    ...
#    push!(ys, 2); push!(xs, 3); push!(cs, wall);
#    board = sparse(ys, xs, cs)
#

# Make sure zero is empty to suit SparseArray which only stores non-zeros.
@enum Cell empty tile wall moveright movedown moveleft moveup
CellChar(cell) = " .#>v<^"[index(cell)]
# These three overrides are just to keep SparseArray happy. 
Base.zero(::Type{Cell}) = empty # Not sure why these need to be explicit.
Base.zero(::Cell) = empty       # Feel like I'm doing something wrong...

@enum Turn ccw cw
@enum Dir right down left up
index(e :: Enum) = Int(e) + 1
dirtocell(d :: Dir) = Cell(Int(d) + Int(moveright))

# Too confusing not to have named ords, and too cumbersome not to be mutable,
# so make our own coord type.
mutable struct Position
    row :: Int
    col :: Int
end
# Only thing lacking is ease of indexing with it... so fix that.
Base.getindex(a::SparseMatrixCSC, i::Position) = getindex(a, i.row, i.col)
Base.setindex!(a::SparseMatrixCSC, v, i::Position) = setindex!(a, v, i.row, i.col)
# Oh, and the silly default equality operation
Base.:(==)(x::Position, y::Position) = x.row == y.row && x.col == y.col

# Opt not to override Base.show because sparsearrays do clever things and it's hard not
# to make *something* worse by trying to improve on it. So keep this standalone.
function show(board :: AbstractArray{Cell, 2})
    rows, cols = axes(board)
    for row ∈ rows # aka "y", but sticking with "row" is much clearer
        println(String([CellChar(board[row,col]) for col in cols]))
    end
end

function turn(dir :: Dir, turn :: Turn)
    # yeah, so an enum constructor has different indexing to `instances`
    return Dir(mod(Int(dir) + (turn == cw ? 1 : -1), 0:length(instances(Dir))-1))
end

function move(pos :: Position, dir :: Dir)
    return Position(pos.row + [0, 1, 0, -1][index(dir)], pos.col + [1, 0, -1, 0][index(dir)])
end
