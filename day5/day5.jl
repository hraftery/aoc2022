stacks,proc = open("input.txt") do f
    stacks = Vector{Char}[]

    for l in eachline(f)
        if !in('[', l)
            break
        end

        stack = 1
        for i in 2:4:length(l)
            if length(stacks) < stack
                push!(stacks, [])
            end
            if l[i] != ' '
                push!(stacks[stack], l[i])
            end
            stack += 1
        end
    end

    readline(f) # skip blank line

    proc = Tuple{Int, Int, Int}[]

    for l in eachline(f)
        fields = split(l)
        push!(proc, Tuple(map((s) -> parse(Int, s), [fields[2], fields[4], fields[6]])))
        # Not sure which I hate more...
        #push!(proc, (parse(Int, fields[2]), parse(Int, fields[4], parse(Int, fields[6])))
    end

    (stacks,proc)
end

#println(stacks)
#println(proc)

stacks1 = stacks
stacks2 = deepcopy(stacks)


for step in proc
    # Part 1
    for _ in 1:step[1]
        crate = popfirst!(stacks1[step[2]])
        pushfirst!(stacks1[step[3]], crate)
    end
    #println(stacks1)

    # Part 2
    crates = splice!(stacks2[step[2]], 1:step[1])
    prepend!(stacks2[step[3]], crates)
    #println(stacks2)
end


#Whoa, watch out for String (constructor) and string (function).
println("Part 1: " * String([s[1] for s in stacks1]))
println("Part 2: " * String([s[1] for s in stacks2]))
