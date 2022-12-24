const COLS = 7

@enum Jet left right

mutable struct Rockloc
    rock :: Vector{String}
    x :: Int
    y :: Int
    Rockloc() = new([], 0, 0)
    Rockloc(rock, x, y) = new(rock, x, y)
end

isvalid(rock :: Rockloc) = rock.y > 0 && rock.x >= 1 && rock.x <= COLS

function bounds(rockloc :: Rockloc)
    rx0 = rockloc.x; rx1 = rx0 + length(rockloc.rock[1]) - 1
    ry0 = rockloc.y; ry1 = ry0 + length(rockloc.rock) - 1
    return (rx0, rx1, ry0, ry1)
end

function height(chamber)
    size(chamber)[1]
end

function parseinput(testcase = false)
    chamber = falses(0, 7)
    
    ROCKS = open("rocks.txt") do f
         reverse.(split.(split(read(f, String), "\n\n"), "\n"))
    end

    open(testcase ? "input.test" : "input.txt") do f
        jets = map(c -> c=='<' ? left : right, collect(readline(f)))

        return (chamber, ROCKS, jets)
    end
end

function isrockat(rockloc, x :: Int, y :: Int)
    rx0, rx1, ry0, ry1 = bounds(rockloc)
    return  y ∈ ry0:ry1 &&
            x ∈ rx0:rx1 &&
            rockloc.rock[1+y-ry0][1+x-rx0] == '#'
end

isrockat(rockloc, xs :: Vector{Int}, y) = any([isrockat(rockloc, x, y) for x ∈ xs])
isrockat(rockloc, x, ys :: Vector{Int}) = any([isrockat(rockloc, x, y) for y ∈ ys])

show(chamber) = show(chamber, nothing)

function show(chamber, rockloc :: Union{Rockloc, Nothing})
    if !isvalid(rockloc)
        rockloc = nothing
    end

    ry1 = isnothing(rockloc) ? height(chamber) : bounds(rockloc)[4]
    for y = ry1:-1:1
        print("|")
        for x = 1:COLS
            if !isnothing(rockloc) && isrockat(rockloc, x, y)
                print("@")
            elseif y<=height(chamber) && chamber[y,x]
                print("#")
            else
                print(".")
            end
        end
        println("|")
    end
    println("+-------+")
end

function addrock(rock, chamber)
    return Rockloc( rock,
                    3,
                    height(chamber)+4)
end

function stepchamber(chamber, rockloc :: Rockloc, jet :: Jet)
    rx0, rx1, ry0, ry1 = bounds(rockloc)
    if canblow(jet, rockloc, chamber)
        rockloc.x += (jet == left ? -1 : 1)
        rx0, rx1, _, _ = bounds(rockloc)
    end
    if canfall(rockloc, chamber)
        rockloc.y -= 1
    else # solidify
        for _ ∈ height(chamber):ry1-1
            chamber = [chamber; falses(1,COLS)]
        end
        for y ∈ ry0:ry1
            for x ∈ rx0:rx1
                if isrockat(rockloc, x, y)
                    chamber[y,x] = true
                end
            end
        end
        rockloc.y = 0 # crude way of letting caller know the rock has solidified
    end
    return chamber
end

function canblow(jet :: Jet, rockloc :: Rockloc, chamber)
    rx0, rx1, ry0, ry1 = bounds(rockloc)
    if jet == left
        rx0 == 1 && return false
        for y ∈ ry0:min(height(chamber),ry1)
            isrockat(rockloc, findall(chamber[y,:]).+1, y) && return false
        end
        return true
    else #jet == right
        rx1 == COLS && return false
        for y ∈ ry0:min(height(chamber),ry1)
            isrockat(rockloc, findall(chamber[y,:]).-1, y) && return false
        end
        return true
    end
end

function canfall(rockloc :: Rockloc, chamber)
    _, _, ry0, ry1 = bounds(rockloc)
    ry0 == 1 && return false
    for y in ry0-1:min(height(chamber),ry1-1)
        isrockat(rockloc, findall(chamber[y,:]), y+1) && return false
    end
    return true
end


function bruteforce(testcase, targetrocks)
    chamber, ROCKS, jets = parseinput(testcase)

    numrocks = 0
    rocks = Iterators.Stateful(Iterators.cycle(ROCKS)) # sheesh Julia, what gives?
    rockloc = Rockloc()
    for jet ∈ Iterators.cycle(jets)
        if !isvalid(rockloc)
            numrocks == targetrocks && return height(chamber)
            rockloc = addrock(popfirst!(rocks), chamber)
            numrocks += 1
            # show(chamber, rockloc)
            # println("")
        end
        chamber = stepchamber(chamber, rockloc, jet)
        # show(chamber, rockloc)
        # println("")
    end
end

mutable struct State
    irock :: Int #note zero-based to make modulo arithmetic easy
    ijet :: Int
    surface :: Vector{Int}
    height :: Int
    numrocks :: Int
end

function getsurface(chamber)
    # put a true at the bottom of the chamber to ensure findfirst finds something eventually
    return [something(findfirst(reverse([true; chamber[:,x]]))) for x in 1:COLS]
end

function findstate(state, history)
    return findfirst(s -> s.irock    == state.irock &&
                          s.ijet     == state.ijet &&
                          s.surface  == state.surface, history)
end

function notbruteforce(testcase, targetrocks)
    chamber, ROCKS, jets = parseinput(testcase)
    state = State(0, 0, ones(COLS), 0, 0)
    history = []

    numrocks = 0
    rocks = Iterators.Stateful(Iterators.cycle(ROCKS)) # sheesh Julia, what gives?
    rockloc = Rockloc()
    for jet ∈ Iterators.cycle(jets)
        state.ijet = (state.ijet + 1) % length(jets)

        if !isvalid(rockloc)
            state.irock = (state.irock + 1) % length(ROCKS)
            state.surface = getsurface(chamber)
            state.height = height(chamber)
            state.numrocks = numrocks

            pastidx = findstate(state, history)
            if isnothing(pastidx)
                push!(history, deepcopy(state))
            else # eureka it repeats! Just extrapolate from here.
                paststate = history[pastidx]
                rockpercycle    = state.numrocks - paststate.numrocks
                heightpercycle  = state.height   - paststate.height
                numcycles       = (targetrocks - paststate.numrocks) ÷ rockpercycle
                postcycles      = (targetrocks - paststate.numrocks) % rockpercycle
                postcyclesheight= history[pastidx+postcycles].height - paststate.height

                return paststate.height + (heightpercycle * numcycles) + postcyclesheight
            end

            rockloc = addrock(popfirst!(rocks), chamber)
            numrocks += 1
            # show(chamber, rockloc)
            # println("")
        end
        chamber = stepchamber(chamber, rockloc, jet)
        # show(chamber, rockloc)
        # println("")
    end
end

function part1(testcase = false)
    #return bruteforce(testcase, 2022) # much of a muchness
    return notbruteforce(testcase, 2022)
end

function part2(testcase = false)
    #return bruteforce(testcase, 1_000_000_000_000) # ain't gunna happen this lifetime
    return notbruteforce(testcase, 1_000_000_000_000)
end


println("Part 1: " * string(part1()))
println("Part 2: " * string(part2()))
