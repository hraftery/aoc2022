inp = open("input.txt") do f
    return map(l -> parse.(UInt8,collect(l)), eachline(f))
end

function visibletreesinline(line)
    ret = []
    maxfw = -1
    maxbw = -1
    for i in 1:lastindex(line)
        if line[i] > maxfw
            maxfw = line[i]
            push!(ret, i)
        end
        ibw = lastindex(line)+1-i
        if line[ibw] > maxbw
            maxbw = line[ibw]
            push!(ret, ibw)
        end
    end
    return ret
end

function part1(inp)
    visibletrees = Set{Tuple{Int,Int}}()
    w,h = (lastindex(inp[1]), lastindex(inp))

    for i in 1:h # left to right and right to left
        for j in visibletreesinline(inp[i])
            push!(visibletrees, (i, j))
#            println((i,j))
        end
    end

    for j in 1:w # top to bottom and bottom to top
        for i in visibletreesinline([row[j] for row in inp])
            push!(visibletrees, (i, j))
#            println((i,j))
        end
    end

    return visibletrees
end

println("Part 1: " * string(length(part1(inp))))


function viewingdistance(line)
    istop = findfirst(t -> t>=line[1], line[2:end])
    
    return (isnothing(istop) ? length(line)-1 : istop)
end

function part2(inp)
    w,h = (lastindex(inp[1]), lastindex(inp))
    bestscore = 0
    for i in 1:h
        for j in 1:w
            score = viewingdistance(inp[i][j:end]) *
                    viewingdistance(inp[i][j:-1:1]) *
                    viewingdistance([row[j] for row in inp][i:end]) *
                    viewingdistance([row[j] for row in inp][i:-1:1])
            bestscore = max(bestscore, score)
            println(string((i,j)) * " = " * string(score))
        end
    end
    return bestscore
end

println("Part 2: " * string(part2(inp)))
