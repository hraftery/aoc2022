@enum Opcode noop addx

OpcodeSymbols = Dict(zip(Symbol.(instances(Opcode)), instances(Opcode)))

struct Instruction
    op :: Opcode
    val :: Union{Int, Nothing}
end

inp = open("input.txt") do f
    ret = Instruction[]
    for l in split.(eachline(f))
        op = OpcodeSymbols[Symbol(l[1])]
        push!(ret, Instruction(op, op == noop ? nothing
                                              : parse(Int, l[2])))
    end
    return ret
end

function run(instructions :: Vector{Instruction})
    X = 1
    Xs = [X]
    for i in instructions
        if i.op == noop

        elseif i.op == addx
            push!(Xs, X)
            X += i.val
        end
        push!(Xs, X)
    end
    return Xs
end

function part1(inp)
    Xs = run(inp)
    signalstrenghs = [i*Xs[i] for i in 20:40:lastindex(Xs)]
#    @show signalstrenghs
    return signalstrenghs
end

println("Part 1: " * string(sum(part1(inp))))


function part2(inp)
    Xs = run(inp)
    for (i,x) in enumerate(Xs)
        col = (i-1) % 40
        pix = col in x-1:x+1 ? "#" : "."
        col == 39 ? println(pix) : print(pix)
    end
end

println("Part 2:")
part2(inp)
