include("grids.jl")

function parseinput(testcase = false)
    open(testcase ? "input.test" : "input.txt") do f
        sensors = Set{Point}()
        beacons = Set{Point}()
        ranges  = Set{Point}()
        for l in eachline(f)
            sxsybxby = parse.(Int, last.(split.(split(l, [',', ':']), '=')))
            #SparseArray's can't handle negative indices, which is a bit of a bummer.
            #So just shift everything by a fixed amount to ensure +ve indices.
            sxsybxby .+= 1000000
            sx, sy, bx, by = sxsybxby
            d = dist(sx, sy, bx, by)
            @show d
            push!(sensors, Point(sx, sy))
            push!(beacons, Point(bx, by))
            union!(ranges, testcase ? [Point(x,y) for x = sx-d:sx+d, y = sy-d:sy+d if dist(x, y, sx, sy) <= d]
                                    : [Point(x,y) for x = sx-d:sx+d, y = 3000000   if dist(x, y, sx, sy) <= d])
        end

        # If there's already a sensor or beacon at a range coord, remove it from ranges
        setdiff!(ranges, sensors, beacons)
        ls, lb, lr = length.([sensors, beacons, ranges])

        return sparse([[s.y for s in sensors] ; [b.y for b in beacons] ; [r.y for r in ranges]],
                      [[s.x for s in sensors] ; [b.x for b in beacons] ; [r.x for r in ranges]],
                       [fill(sensor, ls)      ; fill(beacon, lb)       ; fill(range, lr)])
    end
end


function part1(zone, testcase = false)
    I,_,V = findnz(zone)

    xs = filter(x -> V[x] != beacon, findall(isequal(1000000 + (testcase ? 10 : 2000000)), I))
    return length(xs)
end



struct Report
    sensor::Point
    beacon::Point
    distance::Int
end

include("rects.jl")

function parseinput2(testcase = false)
    open(testcase ? "input.test" : "input.txt") do f
        scan = Report[]
        for l in eachline(f)
            sx, sy, bx, by = parse.(Int, last.(split.(split(l, [',', ':']), '=')))
            push!(scan, Report(Point(sx, sy), Point(bx, by), dist(sx, sy, bx, by)))
        end

        return scan
    end
end

function isoutsidebounds(limit :: Int, r :: Rect)
    return r.bl.y >  r.tr.x           || # top left quadrant: above line y=x
           r.bl.y > -r.bl.x + 2*limit || # top right quadrant: above line y=-x+B
           r.tr.y <  r.bl.x - 2*limit || # bot right quadrant: below line y=x-B
           r.tr.y < -r.tr.x              # bot left quadrant: below line y=-x
end
isoutsidebounds(limit) = (r) -> isoutsidebounds(limit, r)

function part2(scan::Vector{Report}, testcase = false)
    ranges = Rect[]
    for r in scan
        #Rotate axis 45° (and flip and scale for numerical convenience)
        #so a Manhattan radius makes a square (instead of a rhombus).
        s = Point(r.sensor.x + r.sensor.y, r.sensor.x - r.sensor.y)

        #Now the range of this sensor is a simple square.
        #Remember after axis transformation, up is +y and left is -x (Cartesian orientation).
        push!(ranges, Rect(Point(s.x - r.distance, s.y - r.distance),
                           Point(s.x + r.distance, s.y + r.distance)))
    end

    #Two possibilities here:
    # 1. use scan lines directly on the ranges, and find a point on a scanline which is not in a range.
    # 2. start with the total solution space, and chop out no-go areas.

    # Both seem reasonable, but the scanlines are a little bit complicated due to the rhombic solution space.
    # So will opt, somewhat arbitrarily, to start with an oversized solution space (that includes the areas
    # outside the rhombus to make it square), and chop out each range. After filtering out the solutions
    # outside the range, we should be left with a single rectangle of size 1 - our point!
    limit = testcase ? 20 : 4000000
    space = [Rect(Point(0, -limit), Point(2*limit, +limit))]

    for r in ranges
        newSpace = Rect[]
        for s in space # remove range from each subspace, dropping those that end up outside the bounds
            append!(newSpace, filter(!isoutsidebounds(limit), rectdiff(s, r)))
        end
        space = newSpace
    end

    @show space

    # convert back into original coordinate space
    pt = space[1].bl # assuming all went well, it will be the only rect, and bl will equal tr.
    return Point((pt.x + pt.y)/2, (pt.x - pt.y)/2)
end

function plot_space(limit = 20)
    plot([(-10, -10 - limit), (10 + 2*limit, 10 + limit)],
         legend = false)
    plot_rect.(space)
    plot!()
end



testcase = false
zone = parseinput(testcase)
println("Part 1: " * string(part1(zone, testcase)))

scan = parseinput2(testcase)
println("Part 2: " * string(part2(scan, testcase)))
