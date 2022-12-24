using Graphs

struct Point3D
    x :: Int
    y :: Int
    z :: Int
end

function faceneighbours(p :: Point3D)
    return [[Point3D(  x, p.y, p.z) for x in [p.x-1, p.x+1]];
            [Point3D(p.x,   y, p.z) for y in [p.y-1, p.y+1]];
            [Point3D(p.x, p.y,   z) for z in [p.z-1, p.z+1]]]
end

function parseinput(testcase = false)
    cubes = Set{Point3D}()
    open(testcase ? "input.test" : "input.txt") do f
        for l in eachline(f)
            x,y,z = parse.(Int, split(l, ","))
            push!(cubes, Point3D(x,y,z))
        end
    end
    return cubes
end

function makegraph(cubes :: Set{Point3D})
    g = SimpleGraph(length(cubes))
    d = Dict{Point3D, Int}()

    for (i, c) in enumerate(cubes)
        d[c] = i
        for n in faceneighbours(c)
            if n ∈ keys(d)
                add_edge!(g, i, d[n])
            end
        end
    end

    return g
end

function part1(testcase = false)
    g = makegraph(parseinput(testcase))

    sa = 0
    for v in vertices(g)
        sa += 6 - length(neighbors(g, v))
    end
    return sa
end

function expandexterior(c :: Point3D, minc :: Point3D, maxc :: Point3D,
                        droplet :: Set{Point3D}, exterior :: Set{Point3D}, surface :: Set{Point3D})
    for n in filter(n -> n.x >= minc.x && n.y >= minc.y && n.z >= minc.z &&
                         n.x <= maxc.x && n.y <= maxc.y && n.z <= maxc.z &&
                         n ∉ exterior, faceneighbours(c))
        if n ∈ droplet
            push!(surface, n)
        else
            push!(exterior, n)
            expandexterior(n, minc, maxc, droplet, exterior, surface)
        end
    end
end

function surfacecubes(cubes :: Set{Point3D})
    extc = (extrema([c.x for c in cubes]),
            extrema([c.y for c in cubes]),
            extrema([c.z for c in cubes]))
    minc = Point3D(extc[1][1]-1, extc[2][1]-1, extc[3][1]-1)
    maxc = Point3D(extc[1][2]+1, extc[2][2]+1, extc[3][2]+1)
    
    exterior = Set([minc])    # start from min corner and expand from there
    surface  = Set{Point3D}() # every cube we run into gets added to the result

    expandexterior(minc, minc, maxc, cubes, exterior, surface)

    return (surface, exterior)
end

function part2(testcase = false)
    surface, exterior = surfacecubes(parseinput(testcase))

    # Now just add up the number of adjoining cubes in exterior for each surface cube
    sa = 0
    for c ∈ surface
        sa += length(filter(n -> n ∈ exterior, faceneighbours(c)))
    end
    return sa
end


testcase = false
println("Part 1: " * string(part1(testcase)))
println("Part 2: " * string(part2(testcase)))


#
# Below turns out to be unnecessary. For posterity only
#
@enum Direction up down left right forward backward

findfirstel(f, A) = isnothing((idx = findfirst(f, A);)) ? nothing : A[idx] # I'm doing it wrong, aren't I?

function findneighbour(p :: Point3D, ps :: Vector{Point3D}, dir :: Direction)
    dir == up       && return findfirst(n -> n.x == p.x && n.y == p.y && n.z  > p.z, ps)
    dir == down     && return findfirst(n -> n.x == p.x && n.y == p.y && n.z  < p.z, ps)
    dir == left     && return findfirst(n -> n.x  < p.x && n.y == p.y && n.z == p.z, ps)
    dir == right    && return findfirst(n -> n.x  > p.x && n.y == p.y && n.z == p.z, ps)
    dir == forward  && return findfirst(n -> n.x == p.x && n.y  > p.y && n.z == p.z, ps)
    dir == backward && return findfirst(n -> n.x == p.x && n.y  < p.y && n.z == p.z, ps)
end