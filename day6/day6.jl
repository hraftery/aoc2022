datastream :: Array{Char} = open("input.txt") do f
    return collect(readline(f))
end

function solve(data, len)
    i=len
    while length(unique(data[i+1-len:i])) != len
        i+=1
    end
    i
end

println("Part 1: " * string(solve(datastream, 4)))
println("Part 2: " * string(solve(datastream, 14)))
