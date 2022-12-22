using Graphs
using Combinatorics

struct Valve
    name :: String
    flowrate :: Int
    tunnels :: Vector{String}
end

function parseinput(testcase = false)
    open(testcase ? "input.test2" : "input.txt") do f
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

function partcommon(testcase = false)
    global valves = parseinput(testcase)
    valverange = 1:length(valves)
    g = makegraph(valves)
    states = [dijkstra_shortest_paths(g, i) for i ∈ valverange]
    global mindists = [states[src].dists[dst] for src = valverange, dst = valverange]
end

function part1()
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
        
        if nextt <= 0 ||     #oops, one step too far, or
           isempty(nextvis)  #no point going anywhere, we now know our fate, so record it.
            lock(results_lock) do
                if nextt <= 0
                    results[opened] = p # could be redundant. oh well.
                else
                    results[nextOpened] = nextp
                end
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


function part2()
    vi = findfirst(isequal("AA"), getproperty.(valves, :name))
    return steptime((Int[], Int[]), (vi, vi), (0, 0), 0, 26)
end

let
    global steptime

    results = Dict{Tuple{Vector{Int},Vector{Int}},Int}()
    results_lock = ReentrantLock()

    function steptime(opened, vi :: Tuple{Int,Int}, d :: Tuple{Int,Int}, p :: Int, t :: Int)
        allnextvis = [i for i in 1:length(valves) if i ∉ vi &&
                                                     valves[i].flowrate != 0 &&
                                                     i ∉ opened[1] && i ∉ opened[2]]
        nextvis = [] # stay here by default
        nextds = []

        if t == 0 ||                                  # times up or #TODO remove isempty
           (all(i -> i<0, d) && isempty(allnextvis))  # no where to go means we're done, so record it.
            lock(results_lock) do
                results[opened] = p
                if length(results) % 1_000_000 == 0
                    @show length(results)
            end
        end
        else
            if any(isequal(0), d) # when d hits 0, we've arrived *and* opened the value.
                if d[1] == 0
                    p += valves[vi[1]].flowrate * t
                    push!(opened[1], vi[1])
                    nextvis = [(i, vi[2]) for i in allnextvis]
                    nextds  = [(i, d[2])  for i in mindists[vi[1], allnextvis]]
                end
                if d[2] == 0
                    p += valves[vi[2]].flowrate * t
                    push!(opened[2], vi[2])
                    nextvis = [(vi[1], i) for i in allnextvis]
                    nextds  = [(d[1],  i) for i in mindists[vi[2], allnextvis]]
                end
                if d[1] == 0 && d[2] == 0
                    #us and the elephant are equivalent, so we don't both need to take both paths
                    nextvis = [(c[1], c[2]) for c in combinations(allnextvis, 2)]
                    nextds  = [(mindists[vi[1], i], mindists[vi[2], j]) for (i,j) in nextvis]
                end
            end
            
            t -= 1

            if isempty(nextvis) # stay here
                steptime(opened, vi, d .- 1, p, t)
            else
                # if p == 0 # top level, so split into threads
                #     Threads.@threads for (nextvi, nextd) in collect(zip(nextvis, nextds))
                #         steptime(opened, nextvi, nextd, p, t)
                #     end
                # else
                    for (nextvi, nextd) in zip(nextvis, nextds)
                        steptime(opened, nextvi, nextd, p, t)
                    end
                # end
            end
        end

        return results
    end
end



partcommon(true)

# results = part1()
# println("Part 1: " * string(findmax(results)))

results = part2()
println("Part 2: " * string(findmax(results)))
