mutable struct Operation
    a :: String
    op :: String
    b :: String
end

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

function getexpr(monkeys, key)
    val = monkeys[key]
    if isa(val, Float64)
        return string(val)
    else
        return "(" * getexpr(monkeys, val.a) * val.op * getexpr(monkeys, val.b) * ")"
    end
end

function part1(testcase)
    exprStr = getexpr(parseinput(testcase), "root")
    @show exprStr
    return trunc(Int, eval(Meta.parse(exprStr)))
    #return eval(Meta.parse(exprStr))
end

function part2(testcase)
    monkeys = parseinput(testcase)
    monkeys["root"].op = "=="
    monkeys["humn"] = 0.0 # find intercept

    l0 = eval(Meta.parse(getexpr(monkeys, monkeys["root"].a)))
    r0 = eval(Meta.parse(getexpr(monkeys, monkeys["root"].b)))

    monkeys["humn"] = 1.0 # find slope

    l1 = eval(Meta.parse(getexpr(monkeys, monkeys["root"].a)))
    r1 = eval(Meta.parse(getexpr(monkeys, monkeys["root"].b)))

    # l0 = 0*m + b and l1 = 1*m + b OR r0 = 0*m + b and r1 = 1*m + b
    (b,m) = l0 == l1 ? (r0,r1) : (l0,l1) # the unknown is in the side that changes
    m -= b

    # Now solve a = m*x + b where a is the side that didn't change
    x = ((l0 == l1 ? l0 : r0) - b) / m

    # Check 
    monkeys["humn"] = x
    @show eval(Meta.parse(getexpr(monkeys, "root")))

    # Shockingly, even with Float64's, the result is numerically imprecise. I get:
    # b = 236694194244337.15625 = 18225452956813958 / 77 which is right, but
    # m = -38.28125 where in maxima I get -38.23376... = 2944/77
    # So maxima gives me the right answer and I'm done, expect the curiousity wont die.

    # No doubt the issue is that 2944/77 can't be precisely represented as a float.
    # So try find nicer numbers.
    monkeys["humn"] = 1117.0 # works for the example, so may work for us?
    x0 = eval(Meta.parse(getexpr(monkeys, monkeys["root"].a)))
    monkeys["humn"] = 69.0 # found by trial and error, checking x1 == trunc(x1)
    x1 = eval(Meta.parse(getexpr(monkeys, monkeys["root"].a)))
    # Finally, now x0 = 1117m + b and x1 = 69m + b, so
    m = (x0 - x1) / (1117.0 - 69.0)
    x = ((l0 == l1 ? l0 : r0) - b) / m

    # Right! Now m = -38.23378 and x = 3715798283781.1005859375.
    # Still not precise enough! Meh, no longer curious.

    return x
end

function simplifyleaves(monkeys, key)
    val = monkeys[key]
    if isa(val, Int)
        return # nothing more to do
    elseif isa(monkeys[val.a], Int) && isa(monkeys[val.b], Int)
        expr = string(monkeys[val.a]) * val.op * string(monkeys[val.b])
        monkeys[key] = trunc(Int, eval(Meta.parse(expr))) # simplify!
    else
        simplifyleaves(monkeys, val.a)
        simplifyleaves(monkeys, val.b)
    end
end

testcase = false
println("Part 1: " * string(part1(testcase)))
println("Part 2: " * string(part2(testcase)))
