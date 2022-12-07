struct File
    size :: Int
    name :: String
end

struct Dir
    parent :: Union{Dir, Nothing}
    name :: String
    dirs :: Vector{Dir}
    files :: Vector{File}
end

tree = open("input.test") do f
    root = Dir(nothing, "/", [], [])

    currentDir = root

    for l in eachline(f)
        if startswith(l, "\$ cd")
            dirname = l[6:end]
            if dirname == "/"
                currentDir = root
            elseif dirname == ".."
                currentDir = currentDir.parent
            else
                idx = findfirst(d -> d.name == dirname, currentDir.dirs)
                if isnothing(idx)
                    newDir = Dir(currentDir, dirname, [], [])
                    push!(currentDir.dirs, newDir)
                    currentDir = newDir
                else
                    currentDir = currentDir.dirs[idx]
                end
            end
        elseif startswith(l, "\$ ls")
            # No particular action since listings are self-evident
        else
            size,name = split(l)
            if size == "dir"
                push!(currentDir.dirs, Dir(currentDir, name, [], []))
            else
                push!(currentDir.files, File(parse(Int, size), name))
            end
        end
    end

    root
end

function pp(node :: Union{Dir, File}, depth=0)
    print(repeat(' ',depth*2))
    print("- " * node.name * " ")
    if isa(node, File)
        println("(file, size=" * string(node.size) * ")")
    else
        println("(dir)")
        for child in #sort([node.dirs; node.files], by = c->c.name)
            pp(child, depth+1)
        end
    end
end

pp(tree)
