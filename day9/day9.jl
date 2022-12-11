MOVES = Dict("U" => (0, -1),    "R" => ( 1, 0),
             "D" => (0,  1),    "L" => (-1, 0))

inp = open("input.txt") do f
    ret = split.(eachline(f))
    return map(r -> (r[1], parse(Int, r[2])), ret)
end

function pp(h, ts, locs)
    for y = -4:0
        for x = 0:5
            if      h == (x,y)          print("H")
            elseif  isa(ts, Vector) && (x,y) in ts
                                        print(string(findfirst(t -> t==(x,y), ts)))
            elseif !isa(ts, Vector) && ts == (x,y)
                                        print("T")
            elseif  (x,y) in locs       print("#")
            else                        print(".")
            end
        end
        println("")
    end
    println("")
end

function part1(moves)
    h = (0,0)
    t = (0,0)
    locs = Set([t])

    for m in moves
        for i in 1:m[2]
            h = h .+ MOVES[m[1]]
            
            Δ = h.-t
            if any(abs.(Δ) .> 1) # not touching, time to move
                t = t .+ min.((max.(Δ, -1)), 1) # limit move to one step (including diagonal)
                push!(locs, t)
            end

#            pp(h, t, locs)
        end
    end

    return locs
end

println("Part 1: " * string(length(part1(inp))))

function part2(moves)
    h = (0,0)
    ts = fill((0,0), 9)
    locs = Set([last(ts)])

    for m in moves
        for i in 1:m[2]
            h = h .+ MOVES[m[1]]
#            @show h
            
            for it in 1:lastindex(ts)
                Δ = (it == 1 ? h : ts[it-1]) .- ts[it]
                if any(abs.(Δ) .> 1) # not touching, time to move
                    ts[it] = ts[it] .+ min.((max.(Δ, -1)), 1) # limit move to one step (including diagonal)
                    if it == lastindex(ts)
                        push!(locs, last(ts))
                    end
                end
            end

#            pp(h, ts, locs)
        end
    end

    return locs
end

println("Part 2: " * string(length(part2(inp))))