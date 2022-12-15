using SparseArrays

# Make sure zero is empty to suit SparseArray which only stores non-zeros.
@enum Cell empty sensor beacon range

CellChars = Dict(sensor => 'S', beacon => 'B', range => '#', empty => '.')

# These three overrides are just to keep SparseArray happy. 
Base.zero(::Type{Cell}) = empty # Not sure why these need to be explicit.
Base.zero(::Cell) = empty       # Feel like I'm doing something wrong...
function Base.show(io::IO, ::MIME"text/plain", c::Cell)
    if get(io, :compact, false)
        print(io, CellChars[c])
    else
        # honestly, I just want to call the default implementation here, but don't know how.
        print(io, string(c) * "::Cell = " * string(Int(c)))
    end
end
# necessary to get correct alignment. Makes no sense at all...
function Base.show(io::IO, c::Cell)
    if get(io, :compact, false)
        print(io, CellChars[c])
    else
        # honestly, I just want to call the default implementation here, but don't know how.
        print(io, string(c) * "::Cell = " * string(Int(c)) * " ??")
    end
end

function Base.show(io::IO, ::MIME"text/plain", s::SparseMatrixCSC{Cell, Int64})
    I,J,_ = findnz(s)
    miny, minx = minimum.([I, J])
    maxy, maxx = maximum.([I, J])

    println(io, "Occupied region ($minx, $miny) to ($maxx, $maxy):")
    if maxx-minx > 100 || maxy-miny > 100
        return
    end

    print(io, "  ") # margin
    println(io, String([x%10 == 0 ? '0' : (x%5 == 0 ? '5' : ' ') for x in minx:maxx])) # x-axis labels    
    for y in miny:maxy
        print(io, " ") # margin
        print(io, y%10 == 0 ? "0" : (y%5 == 0 ? "5" : " ")) # y-axis label
        print(io, " ") # margin
        for x in minx:maxx
            print(io, CellChars[s[y,x]])
        end
        println("")
    end
    
end


struct Point
    x::Int
    y::Int
end

dist(x0, y0, x1, y1) = abs(x1-x0) + abs(y1-y0)
dist(p0::Point, p1::Point) = dist(p0.x, p0.y, p1.x, p1.y)

zone = open("input.txt") do f
    sensors = Set{Point}()
    beacons = Set{Point}()
    ranges  = Set{Point}()
    for l in eachline(f)
        sxsybxby = parse.(Int, last.(split.(split(l, [',', ':']), '=')))
        #SparseArray's can't handle negative indices, which is a bit of a bummer.
        #So just shift everything by a fixed amount to ensure +ve indices.
        sxsybxby .+= 1000000
        sx, sy, bx, by = sxsybxby
        d = dist(sx, sy, bx, by) + 1 # +1 to include the beacon in the range
        @show d
        push!(sensors, Point(sx, sy))
        push!(beacons, Point(bx, by))
        #union!(ranges, [Point(x,y) for x = sx-d:sx+d, y = sy-d:sy+d if dist(x, y, sx, sy) < d])
        union!(ranges, [Point(x,y) for x = sx-d:sx+d, y = 3000000 if dist(x, y, sx, sy) < d])
    end

    # If there's already a sensor or beacon at a range coord, remove it from ranges
    setdiff!(ranges, sensors, beacons)
    ls, lb, lr = length.([sensors, beacons, ranges])

    return sparse([[s.y for s in sensors] ; [b.y for b in beacons] ; [r.y for r in ranges]],
                  [[s.x for s in sensors] ; [b.x for b in beacons] ; [r.x for r in ranges]],
                   [fill(sensor, ls)      ; fill(beacon, lb)       ; fill(range, lr)])
end


function part1(zone)
    I,_,V = findnz(zone)

    xs = filter(x -> V[x] != beacon, findall(isequal(1000000+2000000), I))
    #xs = filter(x -> V[x] != beacon, findall(isequal(1000000+10), I))
    return length(xs)
end


println("Part 1: " * string(part1(zone)))

