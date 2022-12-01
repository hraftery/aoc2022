using DelimitedFiles;

inp = Matrix{Int}[]

open("input.txt", "r") do io
    while !eof(io)
        str = readuntil(io, "\n\n")
        push!(inp, readdlm(IOBuffer(str)))
    end
end

println(maximum(sum.(inp)))

s = sort(sum.(inp), rev=true)
println(sum(s[1:3]))
