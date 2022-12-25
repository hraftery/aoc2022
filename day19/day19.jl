toint(x :: Integer) = x
toint(x :: AbstractString) = parse(Int, x)

struct Robots
    ore :: Int
    clay :: Int
    obsidian :: Int
    geode :: Int
end

struct Resources
    ore :: Int
    clay :: Int
    obsidian :: Int
    geode :: Int
    Resources(a, b, c) = new(toint(a), toint(b), toint(c), 0)
    Resources(a, b, c, d) = new(a, b, c, d)
end

function Base.:>=(x :: Resources, y :: Resources)
    x.ore >= y.ore && x.clay >= y.clay && x.obsidian >= y.obsidian && x.geode >= y.geode
end

function Base.:-(x::Resources, y::Resources)
    Resources(x.ore-y.ore, x.clay-y.clay, x.obsidian-y.obsidian, x.geode-y.geode)
end

struct Blueprint
    oreRobotCost :: Resources
    clayRobotCost :: Resources
    obsidianRobotCost :: Resources
    geodeRobotCost :: Resources
end

mutable struct Store
    resources :: Resources
    robots :: Robots
end


function parseinput(testcase = false)
    blueprints = Blueprint[]
    open(testcase ? "input.test" : "input.txt") do f
        for inp ∈ split(read(f, String), "\n\n")
            tokens = split(inp)
            push!(blueprints, Blueprint(Resources(tokens[7], 0, 0), # ore robot
                                        Resources(tokens[13], 0, 0), # clay robot
                                        Resources(tokens[19], tokens[22], 0), # obsidian robot
                                        Resources(tokens[28], 0, tokens[31]))) # geode robot
        end
    end
    return blueprints
end

function part1(testcase)
    blueprints = parseinput(testcase)

    bp = blueprints[1]
    store = Store(Resources(0,0,0,0), Robots(1,0,0,0))
    t = 0
    results = Resources[]

    steptime(t, store, bp, results)

    return findmax([r -> r.geode for r ∈ results])
end

function steptime(t, store, bp, results)
    store.resources.ore      += store.robots.ore
    store.resources.clay     += store.robots.clay
    store.resources.obsidian += store.robots.obsidian
    store.resources.geode    += store.robots.geode
    t += 1

    if t == 24 || !any([store >= c for c ∈ [bp.oreRobot, bp.clayRobot, bp.obsidianRobot, bp.geodeRobot]])
        push!(results, store)
    else
        store >= bp.oreRobot      && steptime(t, Resources(1,0,0,0) + store - bp.oreRobot, bp, results)
        store >= bp.clayRobot     && steptime(t, Resources(0,1,0,0) + store - bp.clayRobot, bp, results)
        store >= bp.obsidianRobot && steptime(t, Resources(0,0,1,0) + store - bp.obsidianRobot, bp, results)
        store >= bp.geodeRobot    && steptime(t, Resources(0,0,0,1) + store - bp.geodeRobot, bp, results)
    end
end
