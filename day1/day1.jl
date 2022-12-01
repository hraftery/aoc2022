using DelimitedFiles;

inp = Matrix{Int}[]

open("inputX10000.txt", "r") do io
    while !eof(io)
        str = readuntil(io, "\n\n")
        push!(inp, readdlm(IOBuffer(str)))
    end
end

println(maximum(sum.(inp)))

function part2(inp)
    s = sort(sum.(inp), rev=true)
    return sum(s[1:3])
end

@time part2(inp)

println(part2(inp))
