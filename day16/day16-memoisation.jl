using Graphs

struct Valve
    name :: String
    flowrate :: Int
    tunnels :: Vector{String}
end

function parseinput(testcase = false)
    open(testcase ? "input.test" : "input.txt") do f
        valves = Valve[]

        for l in eachline(f)
            tokens = filter(!isempty, split(l, [' ','=',';',',']))
            push!(valves, Valve(tokens[2], parse(Int, tokens[6]), tokens[11:end]))
        end

        return valves
    end
end

function makegraph(valves)
    g = SimpleDiGraph(length(valves))

    for (srcidx, v) in enumerate(valves)
        for t in v.tunnels
            add_edge!(g, srcidx, something(findfirst(isequal(t), getproperty.(valves, :name))))
        end
    end

    return g
end

function part1(testcase = false)
    global valves = parseinput(testcase)
    global valverange = 1:length(valves)
    g = makegraph(valves)
    states = [dijkstra_shortest_paths(g, i) for i ∈ valverange]
    global mindists = [states[src].dists[dst] for src = valverange, dst = valverange]

    vi = findfirst(isequal("AA"), getproperty.(valves, :name))
    maxtails = moveandturn(Int[], vi)
    return [vi; maxtails[(Set(), vi)]]
end

let #create static local variables for moveandturn: https://stackoverflow.com/a/24546757/3697870
    global moveandturn

    # Map from a set of already opened valves and the current valve, to the order
    # of the remaining valves from the current valve that maximises pressure.
    maxtails = Dict{Tuple{Set{Int}, Int}, Vector{Int}}()
    maxtails_lock = ReentrantLock()

    function moveandturn(opened, vi :: Int)
        cached = lock(maxtails_lock) do
            haskey(maxtails, (Set(opened), vi)) # use the cache, Luke!
        end
        if(cached)
            return
        end

        nextOpened = [opened; vi]
        
        nextvis = filter(i -> i != vi && valves[i].flowrate != 0 && i ∉ opened, valverange)

        if(length(nextvis) == 1) # then there's only one possibility for the tail, so we're done
            maxtails[(Set(opened), vi)] = nextvis
        else
            if isempty(opened) # top level, so split into threads
                Threads.@threads for nextvi ∈ nextvis
                    moveandturn(nextOpened, nextvi)
                end
            else
                for nextvi ∈ nextvis
                    moveandturn(nextOpened, nextvi)
                end
            end

            # Every time we complete all moveandturns for a certain opened, create a tail.
            tails = [maxtails[(Set(nextOpened), nextvi)] for nextvi in nextvis]
            tailscores = [scorepath([vi; nextvi; tail]) for (nextvi, tail) in zip(nextvis, tails)]
            maxIdx = findmax(tailscores)[2]
            lock(maxtails_lock) do
                maxtails[(Set(opened), vi)] = [nextvis[maxIdx]; tails[maxIdx]]
            end
        end

        return maxtails
    end
end

function scorepath(path :: Vector{Int})
    #To give the path a fair score, it turns out we need to set a fixed value for all
    #paths of the same length, which gives enough time for each valve to count. So we
    #could simply pick an arbitrary high number and use that across the board. But it
    #turns out the value of the part of the path we can *never* get to is meaningless,
    #so numbers higher than 30 don't add any extra information[1]. So lets make this
    #function the same as calculating the pressure of a path under the standard
    #conditions of 30 minute time limit.
    #
    # [1] And you know what I just realised... we can probably just brute force it.
    t = 30

    return scorepath(path, t)
end

function scorepath(path :: Vector{Int}, timeleft :: Int)
    dists = [mindists[src, dst] for (src, dst) in zip(path[1:end-1], path[2:end])]

    pressure = 0
    for (v, d) in zip(path[2:end], dists)
        timeleft -= d+1 # +1 to turn the valve on
        if timeleft <= 0
            break
        end
        pressure += valves[v].flowrate * timeleft # total pressure until time's up
    end
    return pressure
end

results = part1()
@show results
@show scorepath(results)
