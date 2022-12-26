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
    bestscores :: Vector{Int}
    # Results(tlimit) = new(0, 0, fill(typemax(Int), tlimit))
    Results(tlimit) = new(0, 0, fill(0, tlimit))
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

    # Threads.@threads for (bpi, bp) in collect(enumerate(blueprints))
    for (bpi, bp) in collect(enumerate(blueprints))
            limits = (0,0,0,0)
        for r in bp
            limits = Tuple([maximum(z) for z in zip(limits, r)])
        end
        # Putting a limit on unnecessary hoarding makes a huge difference to run time.
        # But I had to go >3x max cost to get the right answer. 5x works.
        # Note: now we check "resourcesatend" this might not come into play.
        limits = Tuple([i==0 ? typemax(Int) : 5*i for i in limits])

        store = Store((0,0,0,0), (1,0,0,0))
        rules = Rules(bp, limits, 24)
        results = Results(rules.tlimit)

        #@show (bpi, rules)
        steptime(store, rules, results)

        # lock(maxes_lock) do
            maxes[bpi] = results.maxgeodes
            @show maxes
        # end
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
        branchestaken = 0
        for (rule, effect, i) in zip(rules.blueprint, Singles, 1:N)
            if store.resources >= rule # && resourcesatend <= mostwecanuse
                newStore = Store(store.resources - rule - effect, store.robots + effect) # - effect to correct for the time to build the robot
                # score = scorestore_basic(newStore, rules.blueprint)
                # if newStore.resources[N] > 0 || score + 1 >= results.bestscores[t]
                #     if score > results.bestscores[t]
                #         results.bestscores[t] = score
                #     end

                resourcesatend = newStore.resources[i] + newStore.robots[i] * (rules.tlimit - t - 1)
                mostwecanuse = maximum([r[i] for r in rules.blueprint]) * (rules.tlimit - t - 1)
                if i == N || resourcesatend <= mostwecanuse
                    branchestaken += 1
                    steptime(newStore, rules, results, t)
                end
            end
        end

        resourcesatend = store.resources .+ store.robots .* (rules.tlimit - t - 1)

        # or just sit tight (but never sit on a geode opportunity, # nor leave them all begging)
        store.resources >= rules.blueprint[N] ||
#            all([store.resources >= r for r in rules.blueprint]) ||
            !any([resourcesatend >= r for r in rules.blueprint]) || # if there's nothing to wait for, don't wait
            steptime(deepcopy(store), rules, results, t)
    end
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
        # Note: now we check "resourcesatend" this might not come into play.
        limits = Tuple([i==0 ? typemax(Int) : 8*i for i in limits])

        store = Store((0,0,0,0), (1,0,0,0))
        rules = Rules(bp, limits, 32)
        results = Results(rules.tlimit)

        #@show (bpi, rules)
        steptime(store, rules, results)

        lock(maxes_lock) do
            maxes[bpi] = results.maxgeodes
            @show maxes
        end
    end

    return maxes
end

function scorestore_fail(store :: Store, blueprint :: Blueprint)
    # Have decided a sufficient metric for how we're going at any point is is basically,
    # how long until we can make a geode robot? After the first is made it's less clear what
    # is best, so will leave it at that for now.

    if store.resources[N] > 0
        return 0
    # Geodes require ore and obsidian. We start with an ore robot so if we have an obsidian
    # robot we have an obvious path to the next geode.
    elseif store.robots[N-1] > 0
        # Time required (at current rate) to get enough resources for a geode. Take worst of ore and obsidian.
        return ceil(maximum([(blueprint[N][i]-store.resources[i])/store.robots[i] for i in [1, N-1]]))
    # Otherwise we need to look at the ingredients for an obsidian, which are ore and clay
    elseif store.robots[2] > 0
        return ceil(maximum([(blueprint[N-1][i]-store.resources[i])/store.robots[i] for i in [1, 2]]) +
               1 + blueprint[N][N-1]) # and add time for robot creation and finally, the geode creation
    else
        return typemax(Int)
    end
end

function scorestore_basic(store :: Store, _ :: Blueprint)
    # This performs much better than above! But still misses the best results.
    return store.robots[N-1]
end

function scorestore_fail2(store :: Store, blueprint :: Blueprint)
    # Let's try that again.
    # Try the time required to make enough ore and clay for the ore and obsidian in a geode.
    req = [0,0]
    req[1] = blueprint[N][N-1] * blueprint[N-1][1] + blueprint[N][1]
    req[2] = blueprint[N][N-1] * blueprint[N-1][2]
    return sum([ceil((req[i]-store.resources[i])/store.robots[i]) for i ∈ [1, 2]])
end


testcase = false
println("Part 1: " * string(part1(testcase)))
println("Part 2: " * string(part2(testcase)))
