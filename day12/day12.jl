using Graphs

cur, dst, heights = open("input.txt") do f
    heightchars = hcat(collect.(readlines(f))...)

    cur = findfirst(heightchars .== 'S')
    heightchars[cur] = 'a'

    dst = findfirst(heightchars .== 'E')
    heightchars[dst] = 'z'

    heights = map(c -> c - 'a', heightchars)

    return (cur, dst, heights)
end

function getneighbours(cidx, m)
    dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    allNeighbours = map(d -> cidx + CartesianIndex(d), dirs)
    return filter(n -> checkbounds(Bool, m, n), allNeighbours)
end

function makegraph(heights)
    g = SimpleDiGraph(length(heights))

    for (srcidx, h) in enumerate(heights)
        srccidx = CartesianIndices(heights)[srcidx]

        for dstcidx in getneighbours(srccidx, heights)
            if heights[dstcidx] <= h+1
                add_edge!(g, srcidx, LinearIndices(heights)[dstcidx])
            end
        end
    end

    return g
end

function part1(cur, dst, heights)
    g = makegraph(heights)
    state = dijkstra_shortest_paths(g, LinearIndices(heights)[cur])
    return state.dists[LinearIndices(heights)[dst]]
end

function part2(dst, heights)
    g = makegraph(heights)
    srcs = findall(heights .== 0)

    state = dijkstra_shortest_paths(g, map(s -> LinearIndices(heights)[s], srcs))
    return state.dists[LinearIndices(heights)[dst]]
end

println("Part 1: " * string(part1(cur, dst, heights)))
println("Part 2: " * string(part2(dst, heights)))
