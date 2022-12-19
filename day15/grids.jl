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

    print(io, "   ") # margin
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
