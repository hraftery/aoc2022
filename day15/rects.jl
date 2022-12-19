# Designed for standard cartesion coordinates, so least positive are
# bottom and left, most positive are top and right.
struct Rect
    bl::Point
    tr::Point
    Rect(p0 :: Point, p1 :: Point) = p0.x>p1.x || p0.y>p1.y ?
        error("bl ordinates cannot be greater than tr ordinates") : new(p0, p1)
    Rect(x0, y0, x1, y1) = Rect(Point(x0, y0), Point(x1, y1))
end

function size(r::Rect)
    # Rects include their edges, so 1+ on both dimensions
    return (1+r.tr.x-r.bl.x)*(1+r.tr.y-r.bl.y)
end

function rectdiff(r0::Rect, r1::Rect)
    ret = Rect[]
    r0x0,r0y0,r0x1,r0y1 = [r0.bl.x, r0.bl.y, r0.tr.x, r0.tr.y]
    r1x0,r1y0,r1x1,r1y1 = [r1.bl.x, r1.bl.y, r1.tr.x, r1.tr.y]

    #Check for overlap first.
    if r0x1 < r1x0 || r0x0 > r1x1 || r0y1 < r1y0 || r0y0 > r1y1
        push!(ret, r0) # no change
        return ret
    end

    #Otherwise, split into new rectangles that cover what's left of each side.
    #left side
    if r0x0 < r1x0
        push!(ret, Rect(r0.bl, Point(r1x0-1, r0y1)))
    end
    #right side
    if r0x1 > r1x1
        push!(ret, Rect(Point(r1x1+1, r0y0), r0.tr))
    end
    #bottom side
    if r0y0 < r1y0
        push!(ret, Rect(Point(max(r0x0, r1x0), r0y0), Point(min(r0x1, r1x1), r1y0-1)))
    end
    #top side
    if r0y1 > r1y1
        push!(ret, Rect(Point(max(r0x0, r1x0), r1y1+1), Point(min(r0x1, r1x1), r0y1)))
    end
    
    return ret
end

