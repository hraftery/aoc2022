struct Cave
    rockcols :: Dict{Int, Set{Int}}
    sandcols :: Dict{Int, Set{Int}}
end

function addrock(c::Cave, x::Int, y::Int)
    addrock(c, x, [y])
end

function addrocks(c::Cave, x::Int, y::Vector{Int})
    if haskey(c.rockcols, x)
        union!(c.rockcols[x], ys)
    else
        c.rockcols[x] = Set(ys)
    end
end

rockcols = open("input.test") do f
    rocks = Dict{Int, Set{Int}}()
    for path in eachline(f)
        points = [parse.(Int, i) for i in split.(split(path, " -> "), ",")]
        lines = zip(points[1:end-1], points[2:end])
        for ((x0,y0),(x1,y1)) in lines
            if x0 == x1
                ys = collect(y0<=y1 ? (y0:y1) : (y1:y0))
                haskey(rocks, x0) ? union!(rocks[x0], ys) : rocks[x0] = Set(ys)
            else
                xs = collect(x0<=x1 ? (x0:x1) : (x1:x0))
                for x in xs
                    haskey(rocks, x) ? push!(rocks[x], y0) : rocks[x] = Set(y0)
                end
            end
        end
    end
    return rocks
end

struct Point
    x::Int
    y::Int
end

function part1(rockcols)
    i = 1
    while true
        s = Point(500, 0)

        if rockcols