packetpairs = open("input.txt") do f
    lists = map(something ∘ eval ∘ Meta.parse, filter(!isempty, readlines(f)))
    
    return zip(lists[1:2:end], lists[2:2:end])
end

# isless for vectors is already defined the way we want:
# https://github.com/JuliaLang/julia/issues/16046#issuecomment-428503428
# so just add a definition for comparing ints with vectors
function Base.isless(x::Int, y::AbstractVector)
    return [x] < y
end
function Base.isless(x::AbstractVector, y::Int)
    return x < [y]
end
# and override the default one for isequal (which, instead of throwing an error,
# falls back to `===` for dissimilar types - base/Base.jl#L127)
function Base.isequal(x::Int, y::AbstractVector)
    return isequal([x], y)
end
function Base.isequal(x::AbstractVector, y::Int)
    return isequal(x, [y])
end


function part1(packetpairs)
    cmps = [l<r for (l, r) in packetpairs]
    return findall(cmps)
end

println("Part 1: " * string(sum(part1(packetpairs))))


function part2(packetpairs)
    dividers = ([[2]], [[6]])
    packets = collect(Iterators.flatten(packetpairs))
    sort!(append!(packets, dividers))
    return findall(p -> p in dividers, packets)
end

println("Part 2: " * string(prod(part2(packetpairs))))


# Had to do part1 manually to figure out what was wrong with my solution.
# Turns out `isequal` has a catch-all implementation that I needed to override.
# Manual method below.
function compare(l, r, depth=0)
    print(repeat(' ', depth*2))
    println("- Compare $l vs $r")
    depth += 1

    if isa(l, Int) && isa(r, Int)
        if l == r
            return nothing
        else
            print(repeat(' ', depth*2))
            if l < r
                println("- Left side is smaller, so inputs are in the right order")
                return true
            else
                println("- Right side is smaller, so inputs are not in the right order")
                return false
            end
        end
    elseif isa(l, AbstractVector) && isa(r, AbstractVector)
        for (li, ri) in zip(l, r)
            c = compare(li, ri, depth)
            if !isnothing(c)
                return c
            end
        end
        ll = length(l)
        lr = length(r)
        if ll == lr
            return nothing
        else
            print(repeat(' ', depth*2))
            if ll < lr
                println("- Left side ran out of items, so inputs are in the right order")
                return true
            else
                println("- Right side ran out of items, so inputs are not in the right order")
                return false
            end
        end
    elseif isa(l, Int) && isa(r, AbstractVector)
        print(repeat(' ', depth*2))
        println("- Mixed types; convert left to [$l] and retry comparison")
        return compare([l], r, depth)
    elseif isa(l, AbstractVector) && isa(r, Int)
        print(repeat(' ', depth*2))
        println("- Mixed types; convert right to [$r] and retry comparison")
        return compare(l, [r], depth)
    else
        println("ARGH!")
    end
end


function part1_manual(packetpairs)
    cmps = []
    for (i, (l, r)) in enumerate(packetpairs)
        println("")
        println("== Pair $i ==")
        push!(cmps, compare(l, r))
    end
    return findall(cmps)
end
