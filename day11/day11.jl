struct Monkey
    startingitems :: Vector{Int64}
    operation :: Function
    divisibleby :: Int
    truemonkey :: Int
    falsemonkey :: Int
end

function applyoperation(old :: Int64, op :: AbstractString, arg :: Union{Int64, Nothing})
    if isnothing(arg)
        arg = old
    end
    if op == "+"
        return old + arg
    elseif op == "*"
        return old * arg
    elseif op == "-"
        return old - arg
    else
        return 0
    end
end

inp = open("input.txt") do f
    monkeys = []

    while(!eof(f))
        readline(f) # skip "Monkey i:"

        lines = [split(l, ": ")[2] for l in Iterators.take(eachline(f), 5)]
        lines = map(l -> split(l, [',',' '], keepempty=false), lines)

        startingitems   = parse.(Int, lines[1])
        @eval operation = old -> applyoperation(old, $lines[2][4], tryparse(Int, $lines[2][5]))
        divisibleby     = parse(Int, lines[3][3])
        truemonkey      = parse(Int, lines[4][4])
        falsemonkey     = parse(Int, lines[5][4])

        push!(monkeys, Monkey(startingitems, operation, divisibleby, truemonkey, falsemonkey))

        readline(f) # skip blankline
    end

    return monkeys
end


function turn(monkey, relief=true)
    ret = []
    while !isempty(monkey.startingitems)
        i = popfirst!(monkey.startingitems)
        i = monkey.operation(i)
        i ÷= relief ? 3 : 1
        push!(ret, (i, i % monkey.divisibleby == 0 ? monkey.truemonkey
                                                   : monkey.falsemonkey))
    end
    return ret
end

function round(monkeys, relief=true)
    inspections = []
    for m in monkeys
        throws = turn(m, relief)
        for (item, imonkey) in throws
            push!(monkeys[imonkey+1].startingitems, item)
        end
        push!(inspections, length(throws))
    end
    return inspections
end

function part1(inp)
    ms = deepcopy(inp)
    inspections = zeros(Int, length(ms))
    
    for i in 1:20
        inspections .+= round(ms)
    end

    maxinspections = sort(inspections, rev=true)[1:2]
    return prod(maxinspections)
end

function part2(inp)
    ms = deepcopy(inp)
    inspections = zeros(Int, length(ms))
    divisorproduct = prod([m.divisibleby for m in ms])
    
    for i in 1:10000
        inspections .+= round(ms, false)

        for m in ms
            m.startingitems .%= divisorproduct
        end

        if i in [1; 20; 1000:1000:10000]
            @show (i,inspections)
        end
    end

    maxinspections = sort(inspections, rev=true)[1:2]
    return prod(maxinspections)
end

println("Part 1: " * string(part1(inp)))
println("Part 2: " * string(part2(inp)))
