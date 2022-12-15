using SparseArrays

# Make sure zero is empty to suit SparseArray which only stores non-zeros.
@enum Cell empty rock sand

# These three overrides are just to keep SparseArray happy. 
Base.zero(::Type{Cell}) = empty # Not sure why these need to be explicit.
Base.zero(::Cell) = empty       # Feel like I'm doing something wrong...
function Base.show(io::IO, ::MIME"text/plain", c::Cell)
    if get(io, :compact, false)
        if     c == rock    print(io, "#")
        elseif c == sand    print(io, "o")
        else                print(io, "X")
        end
    else
        # honestly, I just want to call the default implementation here, but don't know how.
        print(io, string(c) * "::Cell = " * string(Int(c)))
    end
end
# necessary to get correct alignment. Makes no sense at all...
function Base.show(io::IO, c::Cell)
    if get(io, :compact, false)
        if     c == rock    print(io, "#")
        elseif c == sand    print(io, "o")
        else                print(io, "X")
        end
    else
        # honestly, I just want to call the default implementation here, but don't know how.
        print(io, string(c) * "::Cell = " * string(Int(c)) * " ??")
    end
end


struct Point
    x::Int
    y::Int
end


cave = open("input.txt") do f
    rocks = Set{Point}()
    for path in eachline(f)
        points = [parse.(Int, i) for i in split.(split(path, " -> "), ",")]
        lines = zip(points[1:end-1], points[2:end])
        for ((x0,y0),(x1,y1)) in lines
            if x0 == x1
                ys = collect(y0<=y1 ? (y0:y1) : (y1:y0))
                union!(rocks, [Point(x0, y) for y in ys])
            else
                xs = collect(x0<=x1 ? (x0:x1) : (x1:x0))
                union!(rocks, [Point(x, y0) for x in xs])
            end
        end
    end
    return sparse([p.y for p in rocks], [p.x for p in rocks], fill(rock, length(rocks)))
end

function isvacant(cave, pt)
    (rows, cols) = size(cave)
    return pt.y > rows || pt.x > cols || cave[pt.y, pt.x] == empty #note [y,x] order when indexing
    #return isnothing(findfirst((pt.x, pt.y), zip(nzs[2], nzs[1])))
end

function fallsstraightto(cave, pt)
    (rows, cols) = size(cave)

    if pt.y <= rows && pt.x <= cols
        occupiedrows = sort(rowvals(cave)[nzrange(cave, pt.x)])
        fallstoidx = findfirst(r -> r > pt.y, occupiedrows)
        if !isnothing(fallstoidx)
            return Point(pt.x, occupiedrows[fallstoidx] - 1)
        end
    end

    return nothing # falls forever
end

function fallsto(cave, pt)
    ret = fallsstraightto(cave, pt)
    if isnothing(ret)
        return ret
    else
        l = Point(ret.x-1, ret.y+1)
        r = Point(ret.x+1, ret.y+1)

        # try left, then right, else settle here
        if isvacant(cave, l)
            return fallsto(cave, l)
        elseif isvacant(cave, r)
            return fallsto(cave, r)
        else
            return ret
        end
    end
end

function part1(cave)
    i = 0
    while true
        s = Point(500, 0)

        s = fallsto(cave, s)
        if isnothing(s)
            return i
        end

        cave[s.y, s.x] = sand
        i += 1
    end
    return i
end


println("Part 1: " * string(part1(cave)))


function testpart1(cave)
    s = Point(10, 0)

    s = fallsto(cave, s)
    
    cave[s.y, s.x] = sand
    
    cave
end
