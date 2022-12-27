using SparseArrays

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

function parseinput(testcase = false)
    ys = []; xs = []; cs = Vector{Cell}(); # types are so hard...
    path = Union{Int,Turn}[]

    open(testcase ? "input.test" : "input.txt") do f
        for (y, l) ∈ enumerate(eachline(f))
            # Break at the empty line, where it's just the path to go.
            isempty(l) && break
            # Otherwise, process another board row.
            for (x, c) ∈ enumerate(collect(l)) # look, I know, looping. But findall et al is so cumbersome!
                if c == '.'
                    push!(ys, y); push!(xs, x); push!(cs, tile);
                elseif c == '#'
                    push!(ys, y); push!(xs, x); push!(cs, wall);
                end
            end
        end

        parsingnum = false
        for c in collect(readline(f))
            if isnumeric(c)
                if !parsingnum
                    push!(path, c-'0')
                    parsingnum = true
                else
                    path[end] = 10*path[end] + (c-'0')
                end
            else
                parsingnum = false
                push!(path, c=='R' ? cw : ccw)
            end
        end
    end

    board = sparse(ys, xs, cs)
    return (board, path)
end

function show(board)
    rows, cols = axes(board)
    for y ∈ rows
        println(String([CellChar(board[y,x]) for x in cols]))
    end
end

function turn(dir, turn)
    # yeah, so an enum constructor has different indexing to `instances`
    return Dir(mod(Int(dir) + (turn == cw ? 1 : -1), 0:length(instances(Dir))-1))
end

function move(pos :: Position, dir :: Dir)
    return Position(pos.row + [0, 1, 0, -1][index(dir)], pos.col + [1, 0, -1, 0][index(dir)])
end

function part1(testcase)
    board, path = parseinput(testcase)
    rows, cols = axes(board)

    # let's standardise on (row, col), not (x,y), to match matrices
    pos = Position(1, something(findfirst(isequal(tile), board[1,:])))
    dir = right
    board[pos] = dirtocell(dir)
    
    for p in path
        if isa(p, Turn)
            dir = turn(dir, p)
            board[pos] = dirtocell(dir)
        else
            for i in 1:p
                newpos = move(pos, dir)
                
                # bounds checking is so hard... apparently help is coming: https://github.com/JuliaLang/julia/issues/43392
                if newpos.row ∉ rows || newpos.col ∉ cols || board[newpos] == empty # then wrap first
                    if dir == up
                        newpos.row = maximum(findnz(board[:,pos.col])[1]) # is it really this hard?
                    elseif dir == down
                        newpos.row = minimum(findnz(board[:,pos.col])[1])
                    elseif dir == left
                        newpos.col = maximum(findnz(board[pos.row,:])[1])
                    elseif dir == right
                        newpos.col = minimum(findnz(board[pos.row,:])[1])
                    end
                end
                cell = board[newpos]
                if cell == wall
                    break # go no further
                elseif cell ∈ [tile, moveright, movedown, moveleft, moveup]
                    pos = newpos # move here and go again
                end
                board[pos] = dirtocell(dir)
            end
        end
        if testcase
            @show (dir, pos)
            show(board)
            println("")
        end
    end

    @show (dir, pos)
    show(board)
    println("")

    return 1000 * pos.row + 4 * pos.col + Int(dir)
end

function part2(testcase)
end

testcase = false
println("Part 1: " * string(part1(testcase)))
#println("Part 2: " * string(part2(testcase)))
