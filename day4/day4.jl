struct AssignmentPair
    elf1lower::Int
    elf1upper::Int
    elf2lower::Int
    elf2upper::Int
end

assignments = open("input.txt") do f
    ret = AssignmentPair[]    

    for l in eachline(f)
        vals = [parse(Int, i) for i in split(l, ['-',','])]
        push!(ret, AssignmentPair(vals[1], vals[2], vals[3], vals[4]))
    end

    ret
end

#println(assignments)


function fullycontained(ap :: AssignmentPair)
    return (ap.elf1lower >= ap.elf2lower && ap.elf1upper <= ap.elf2upper) ||
           (ap.elf2lower >= ap.elf1lower && ap.elf2upper <= ap.elf1upper)
end

println("Part 1: " * string(count(fullycontained, assignments)))

function overlap(ap :: AssignmentPair)
    return (ap.elf1lower <= ap.elf2upper && ap.elf1upper >= ap.elf2lower) ||
           (ap.elf2lower <= ap.elf1upper && ap.elf2upper >= ap.elf1lower)
end

println("Part 2: " * string(count(overlap, assignments)))
