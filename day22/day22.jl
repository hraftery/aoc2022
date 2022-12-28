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
# Oh, and the silly default equality operation
Base.:(==)(x::Position, y::Position) = x.row == y.row && x.col == y.col

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

function doit(testcase, wrap)
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
            for _ in 1:p
                newpos = move(pos, dir)
                newdir = dir # took hours and hours to find this bug - if we wrap and hit a wall, need to restore dir

                # bounds checking is so hard... apparently help is coming: https://github.com/JuliaLang/julia/issues/43392
                if newpos.row ∉ rows || newpos.col ∉ cols || board[newpos] == empty # then wrap first
                    newdir = wrap(newpos, newdir, board)
                end
                cell = board[newpos]
                if cell == wall
                    break # go no further
                elseif cell ∈ [tile, moveright, movedown, moveleft, moveup]
                    pos = newpos # move here and go again
                    dir = newdir
                end
                board[pos] = dirtocell(dir)
            end
        end
        # if testcase
            # @show (dir, pos)
            # show(board)
            # println("")
        # end
    end

    # @show (dir, pos)
    # show(board)
    # println("")

    return 1000 * pos.row + 4 * pos.col + Int(dir)
end

function wrap1(pos, dir, board)
    if     dir == up        pos.row = maximum(findnz(board[:,pos.col])[1]) # is it really this hard?
    elseif dir == down      pos.row = minimum(findnz(board[:,pos.col])[1])
    elseif dir == left      pos.col = maximum(findnz(board[pos.row,:])[1])
    elseif dir == right     pos.col = minimum(findnz(board[pos.row,:])[1])
    end
    return dir
end

function wrap2(pos, dir, _)
# 01234
#0  ab
#1 c..d
#2 e.f
#3g..h
#4i.j
#5 k
    
    # Implementation is different for different nets, so not going to bother
    # doing anything other than the input case, but this is how it would start.
    #N = minimum(size(board)) ÷ 3
    N = 50

    if pos.row == 0 # a or b
        if pos.col <= 2*N # a
            pos.row = pos.col + 2*N
            pos.col = 1
            dir = right
        else # b
            pos.row = 4*N
            pos.col = pos.col - 2*N
        end
    elseif pos.col == N && dir == left # c or e (going left)
        if pos.row <= N # c
            pos.row = 3*N - (pos.row - 1)
            pos.col = 1
            dir = right
        else # e (going left)
            pos.col = pos.row - N
            pos.row = 1 + 2*N
            dir = down
        end
    elseif pos.row == 100 && dir == up # e (going up)
        pos.row = pos.col + 1*N
        pos.col = 1*N + 1
        dir = right
    elseif pos.col == 0 # g or i
        if pos.row <= 3*N # g
            pos.row = N - (pos.row - 2*N - 1)
            pos.col = 1 + N
            dir = right
        else # i
            pos.col = N + pos.row - 3*N
            pos.row = 1
            dir = down
        end
    elseif pos.col == 1 + 3*N # d
        pos.col = 2*N
        pos.row = 3*N - (pos.row - 1)
        dir = left
    elseif pos.col == 1 + 2*N && dir == right # f (going right) or h
        if pos.row <= 2*N # f (going right)
            pos.col = 2*N + pos.row - N
            pos.row = N
            dir = up
        else # h
            pos.col = 3*N
            pos.row = N - (pos.row - 2*N - 1)
            dir = left
        end
    elseif pos.row == 1 + 1*N # f (going down)
        pos.row = 1*N + (pos.col - 2*N)
        pos.col = 2*N
        dir = left
    elseif pos.col == 1 + 1*N && dir == right # j (going right)
        pos.col = 1*N + (pos.row - 3*N)
        pos.row = 3*N
        dir = up
    elseif pos.row == 1 + 3*N # j (going down)
        pos.row = 3*N + (pos.col - 1*N)
        pos.col = 1*N
        dir = left
    elseif pos.row == 1 + 4*N # k
        pos.row = 1
        pos.col = pos.col + 2*N
    end

    return dir
end



function part1(testcase)
    return doit(testcase, wrap1)
end

function part2(testcase)
    return doit(testcase, wrap2)
end

testcase = false
println("Part 1: " * string(part1(testcase)))
println("Part 2: " * string(part2(testcase)))


function testwrap2()
    board, _ = parseinput(false)
    rows, cols = axes(board)
    tests = 0; fails = 0;

    for (i, v) in enumerate(board)
        if v == empty
            continue
        end
        tests += 1
        ci = CartesianIndices(board)[i]
        pos = Position(ci[1], ci[2])
        
        for ds ∈ instances(Dir)
            p = deepcopy(pos)
            d = ds
            for _ ∈ 1:200
                p = move(p, d)
                if p.row ∉ rows || p.col ∉ cols || board[p] == empty 
                    d = wrap2(p, d, board)
                end
            end
            if p != pos || d != ds
                fails += 1
                @show (pos, p, ds, d)
            end
        end
    end

    for (p0,d0,p1,d1) ∈ [(Position(0, 51), up, Position(151, 1), right),
                         (Position(0, 100), up, Position(200, 1), right),
                         (Position(0, 101), up, Position(200, 1), up),
                         (Position(0, 150), up, Position(200, 50), up),
                         (Position(1, 151), right, Position(150, 100), left),
                         (Position(50, 151), right, Position(101, 100), left),
                         (Position(51, 150), down, Position(100, 100), left),
                         (Position(51, 101), down, Position(51, 100), left),
                         (Position(51, 101), right, Position(50, 101), up),
                         (Position(100, 101), right, Position(50, 150), up),
                         (Position(101, 101), right, Position(50, 150), left),
                         (Position(150, 101), right, Position(1, 150), left),
                         (Position(151, 100), down, Position(200, 50), left),
                         (Position(151, 51), down, Position(151, 50), left),
                         (Position(151, 51), right, Position(150, 51), up),
                         (Position(200, 51), right, Position(150, 100), up),
                         (Position(201, 50), down, Position(1, 150), down),
                         (Position(201, 1), down, Position(1, 101), down),
                         (Position(200, 0), left, Position(1, 100), down),
                         (Position(151, 0), left, Position(1, 51), down),
                         (Position(150, 0), left, Position(1, 51), right),
                         (Position(101, 0), left, Position(50, 51), right),
                         (Position(100, 1), up, Position(51, 51), right),
                         (Position(100, 50), up, Position(100, 51), right),
                         (Position(100, 50), left, Position(101, 50), down),
                         (Position(51, 50), left, Position(101, 1), down),
                         (Position(50, 50), left, Position(101, 1), right),
                         (Position(1, 50), left, Position(150, 1), right)]
        tests += 1
        d0 = wrap2(p0, d0, board)
        if p0 != p1 || d0 != d1
            fails += 1
            @show (p0,d0,p1,d1)
        end
    end

    @show (tests, fails)
end

#testwrap2()
