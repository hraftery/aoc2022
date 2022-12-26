using LinearAlgebra

# The base collection for sets of resources or costs or robots. What's a good name for that?
const N = 4
const Lot = Tuple{Int, Int, Int, Int}
const LotOfLots = Tuple{Lot, Lot, Lot, Lot}

const Robots = Lot
const Resources = Lot
const Costs = Lot
const Blueprint = LotOfLots
const Singles = [Tuple(view(Matrix(1I, N, N), :, i)) for i in 1:N]

# Finally, going to rid myself of .+= not working for Tuples by redefining += instead!
Base.:+(a::Lot, b::Lot) = a .+ b
Base.:-(a::Lot, b::Lot) = a .- b
Base.:>=(a::Lot,b::Lot) = all(a .>= b)

toint(x :: Integer) = x
toint(x :: AbstractString) = parse(Int, x)

NewCosts(a, b, c) :: Costs = (toint(a), toint(b), toint(c), 0)

mutable struct Store
    resources :: Resources
    robots :: Robots
end
Base.:(==)(x::Store, y::Store) = x.resources == y.resources && x.robots == y.robots

struct Rules
    blueprint :: Blueprint
    limits :: Resources
    tlimit :: Int
end

mutable struct Results
    count :: Int
    maxgeodes :: Int
end

function parseinput(testcase = false)
    blueprints = Blueprint[]
    open(testcase ? "input.test" : "input.txt") do f
        for inp ∈ eachline(f) # split(read(f, String), "\n\n")
            tokens = split(inp)
            push!(blueprints, (NewCosts(tokens[7], 0, 0), # ore robot
                               NewCosts(tokens[13], 0, 0), # clay robot
                               NewCosts(tokens[19], tokens[22], 0), # obsidian robot
                               NewCosts(tokens[28], 0, tokens[31]))) # geode robot
        end
    end
    return blueprints
end

function part1(testcase)
    blueprints = parseinput(testcase)
    maxes = [-1 for _ in 1:length(blueprints)]
    maxes_lock = ReentrantLock()

    Threads.@threads for (bpi, bp) in collect(enumerate(blueprints))
        limits = (0,0,0,0)
        for r in bp
            limits = Tuple([maximum(z) for z in zip(limits, r)])
        end
        # Putting a limit on unnecessary hoarding makes a huge difference to run time.
        # But I had to go >3x max cost to get the right answer. 5x works.
        limits = Tuple([i==0 ? typemax(Int) : 5*i for i in limits])

        store = Store((0,0,0,0), (1,0,0,0))
        rules = Rules(bp, limits, 24)
        results = Results(0,0)

        #@show (bpi, rules)
        steptime(store, rules, results)

        lock(maxes_lock) do
            maxes[bpi] = results.maxgeodes
            @show maxes
        end
    end

    return maxes
end

function part2(testcase)
    blueprints = parseinput(testcase)
    maxes = [-1 for _ in 1:length(blueprints)]
    maxes_lock = ReentrantLock()

    Threads.@threads for (bpi, bp) in collect(Iterators.take(enumerate(blueprints), 3))
        limits = (0,0,0,0)
        for r in bp
            limits = Tuple([maximum(z) for z in zip(limits, r)])
        end
        # Putting a limit on unnecessary hoarding makes a huge difference to run time.
        # But I had to go >3x max cost to get the right answer. 5x works.
        limits = Tuple([i==0 ? typemax(Int) : 5*i for i in limits])

        store = Store((0,0,0,0), (1,0,0,0))
        rules = Rules(bp, limits, 32)
        results = Results(0,0)

        #@show (bpi, rules)
        steptime(t, store, rules, results)

        lock(maxes_lock) do
            maxes[bpi] = results.maxgeodes
            @show maxes
        end
    end

    return maxes
end

function steptime(store, rules, results, t = 0)
    store.resources += store.robots
    t += 1

    if any([r > l for (r,l) in zip(store.resources, rules.limits)])
        return # put a pin in it
    elseif t == rules.tlimit
        results.count += 1
        results.maxgeodes = max(results.maxgeodes, store.resources[4])
        # if results.count % 10_000_000 == 0
        #     @show results
        # end
    else
        for (rule, effect) in zip(rules.blueprint, Singles)
            newStore = Store(store.resources - rule - effect, store.robots + effect) # - effect to correct for the time to build the robot
            store.resources >= rule && steptime(newStore, rules, results, t)
        end
        steptime(deepcopy(store), rules, results, t) # or just sit tight
    end
end

testcase = true
println("Part 1: " * string(part1(testcase)))
println("Part 2: " * string(part2(testcase)))
