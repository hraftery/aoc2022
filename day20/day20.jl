function parseinput(testcase = false)
    nums = Int[]
    open(testcase ? "input.test" : "input.txt") do f
        for l in eachline(f)
            push!(nums, parse(Int, l))
        end
    end
    return nums
end

function doit(testcase, times = 1, key = 1)
    nums = parseinput(testcase)
    nums .*= key

    mixed, N = mix(nums, times)

    izero = something(findfirst(isequal(0), mixed))
    coords = [mixed[mod(izero + offset, 1:N)] for offset ∈ [1000,2000,3000]]
    
    return sum(coords)
end

function mix(nums :: Vector{Int}, times :: Int = 1)
    N = length(nums)
    xs = collect(enumerate(nums))

    for t in 1:times
        for i in 1:N
            isrc = something(findfirst(x -> x[1] == i, xs))
            x = xs[isrc]
            # on the way forward, we use the end of the list, on the way back the start
            #idst = mod(isrc + x[2], x[2] > 0 ? (2:N) : (1:N-1))
            # No, according to the example we don't use the start
            idst = mod(isrc + x[2], 2:N)
            deleteat!(xs, isrc)
            insert!(xs, idst, x)
        end
    end

    return ([x[2] for x in xs], N)
end

function part1(testcase)
    return doit(testcase)
end

function part2(testcase)
    return doit(testcase, 10, 811589153)
end

testcase = false
println("Part 1: " * string(part1(testcase)))
println("Part 2: " * string(part2(testcase)))
