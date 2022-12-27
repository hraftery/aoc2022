@enum Turn ccw cw
@enum Dir up right down left

function parseinput(testcase = false)
    board = Vector{Bool}[] # Why even both with a matrix? So much harder, benefit not yet seen.
    path = Union{Int,Turn}[]

    open(testcase ? "input.test" : "input.txt") do f
        for l in eachline(f)
            isempty(l) && break # empty, so just the path to go            
            push!(board, [c == '.' for c in collect(l)]) # otherwise, another board row
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

    return (board, path)
end

function show(board)
    for row in board
        println(String([c ? '.' : '#' for c in row]))
    end
end

function turn(dir, turn)
    return Dir(mod(Int(dir) + (turn == right ? 1 : -1), 1:length(instances(Dir))))
end

function part1(testcase)
    board, path = parseinput(testcase)

    pos = (something(findfirst(board[1])), 1)
    dir = right

    for p in path
        if isa(p, Turn)
            turn(dir, p)
        else


end

function part2(testcase)
end

testcase = false
println("Part 1: " * string(part1(testcase)))
#println("Part 2: " * string(part2(testcase)))
