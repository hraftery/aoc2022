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
    valverange = 1:length(valves)
    g = makegraph(valves)
    states = [dijkstra_shortest_paths(g, i) for i ∈ valverange]
    global mindists = [states[src].dists[dst] for src = valverange, dst = valverange]

    vi = findfirst(isequal("AA"), getproperty.(valves, :name))
    return moveandturn(Int[], vi, -1, 0, 30) #-1 to negate the turning on of AA.
end

let #this is a trick to create static local variables for moveandturn: https://stackoverflow.com/a/24546757/3697870
    global moveandturn

    results = Dict{Vector{Int},Int}()
    results_lock = ReentrantLock()

    function moveandturn(opened, vi :: Int, d :: Int, p :: Int, t :: Int)
        nextt = t - (d+1) # +1 to turn the valve on
        nextp = p + (valves[vi].flowrate * nextt) # total pressure until time's up
        nextOpened = [opened; vi]
        
        nextvis = [i for i in 1:length(valves) if i != vi &&
                                                valves[i].flowrate != 0 &&
                                                i ∉ opened]
        if(isempty(nextvis)) #no point going anywhere, we now know our fate, so record it.
            lock(results_lock) do
                results[nextOpened] = nextp
                if length(results) % 1_000_000 == 0
                    @show length(results)
                end
            end
        else
            if isempty(opened) # top level, so split into threads
                Threads.@threads for (nextvi, nextd) in collect(zip(nextvis, mindists[vi, nextvis]))
                    moveandturn(nextOpened, nextvi, nextd, nextp, nextt)
                end
            else
                for (nextvi, nextd) in zip(nextvis, mindists[vi, nextvis])
                    moveandturn(nextOpened, nextvi, nextd, nextp, nextt)
                end
            end
        end

        return results
    end
end

results = part1(true)
@show findmax(results)
