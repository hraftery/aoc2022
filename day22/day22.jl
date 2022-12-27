function parseinput(testcase = false)
    monkeys = Dict{String, Union{Float64, Operation}}()
    open(testcase ? "input.test" : "input.txt") do f
        for l in eachline(f)
            (key, value) = split(l, ": ")
            if isnumeric(value[1])
                monkeys[key] = parse(Float64, value)
            else
                tokens = split(value)
                # if tokens[2] == "/"
                #     tokens[2] =  "÷" # keep it to ints
                # end
                monkeys[key] = Operation(tokens...)
            end
        end
    end
    return monkeys
end

function part1(testcase)
    parseinput(testcase)
end

function part2(testcase)
end

testcase = false
println("Part 1: " * string(part1(testcase)))
#println("Part 2: " * string(part2(testcase)))
