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
    m = [0,0,0]
    for i in inp
        s = sum(i)
        if s > m[1]
            if s > m[2]
                if s > m[3]
                    m=[m[2],m[3],s]
                else
                    m=[m[2],s,m[3]]
                end
            else
                m=[s,m[2],m[3]]
            end
        end
    end
    return sum(m)
end

@time part2(inp)

println(part2(inp))
