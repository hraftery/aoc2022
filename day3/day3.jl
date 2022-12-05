rucksacks1, rucksacks2 = open("input.txt") do f
    r1 = Tuple{Set{Char},Set{Char}}[]
    r2 = Tuple{Set{Char},Set{Char},Set{Char}}[]

    sack1 = Set{Char}
    sack2 = Set{Char}
    for (i, l) in enumerate(eachline(f))
        len = length(l)
        push!(r1, Tuple([Set(l[1:len÷2]), Set(l[len÷2+1:len])]))

        if i % 3 == 1
            sack1 = Set(l)
        elseif i % 3 == 2
            sack2 = Set(l)
        else
            push!(r2, Tuple([sack1, sack2, Set(l)]))
        end
    end

    (r1, r2)
end

#println(rucksacks1)
#println(rucksacks2)

shared = [first(intersect(r[1], r[2])) for r in rucksacks1]
priorities = [islowercase(s) ? 1+s-'a' : 27+s-'A' for s in shared]

println("Part 1: " * string(sum(priorities)))

shared = [first(intersect(r[1], r[2], r[3])) for r in rucksacks2]
priorities = [islowercase(s) ? 1+s-'a' : 27+s-'A' for s in shared]

println("Part 2: " * string(sum(priorities)))