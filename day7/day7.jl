mutable struct Node
    isFile :: Bool
    parent :: Union{Node, Nothing}
    name :: String
    size :: Union{Int, Missing}
    children :: Vector{Node}
end
Dir(p, n) =     Node(false, p, n, missing, [])
File(p, n, s) = Node(true, p, n, s, [])

function pp(node :: Node, descend=false, depth=0)
    print(repeat(' ', depth*2))
    print("- " * node.name * " ")
    println("(" *
            (node.isFile ? "file" : "dir") *
            (ismissing(node.size) ? "" : ", size=" * string(node.size)) *
            ")")
        
    if descend
        for child in node.children
            pp(child, descend, depth+1)
        end
    end
end

function calculatesize(node :: Node)
    if !ismissing(node.size)
        return node.size # nothing more to be done
    end

    if isempty(node.children)
        node.size = 0
    else
        node.size = sum([calculatesize(n) for n in node.children])
    end
    
    return node.size
end

function dfs(node :: Node, pred :: Function, matches :: Vector{Node} = Node[])
    if(pred(node))
        push!(matches, node)
    end

    for child in node.children
        dfs(child, pred, matches)
    end

    return matches
end


tree = open("input.txt") do f
    root = Dir(nothing, "/")

    currentDir = root

    for l in eachline(f)
        if startswith(l, "\$ cd")
            dirname = l[6:end]
            if dirname == "/"
                currentDir = root
            elseif dirname == ".."
                currentDir = currentDir.parent
            else
                idx = findfirst(c -> c.name == dirname, currentDir.children)
                if isnothing(idx)
                    newDir = Dir(currentDir, dirname)
                    push!(currentDir.children, newDir)
                    currentDir = newDir
                else
                    currentDir = currentDir.children[idx]
                end
            end
        elseif startswith(l, "\$ ls")
            # No particular action since listing lines are self-evident
        else
            size,name = split(l)
            push!(currentDir.children,
                  size == "dir" ? Dir(currentDir, name)
                                : File(currentDir, name, parse(Int, size)))
        end
    end

    root
end


#pp(tree, true)
#println("")

calculatesize(tree)

#pp(tree, true)
#println("")

dirs_no_bigger_than_100000 = dfs(tree, n -> !n.isFile && n.size <= 100000)

for n in dirs_no_bigger_than_100000
    pp(n)
end

println("\nPart 1: " * string(sum([n.size for n in dirs_no_bigger_than_100000])))
println("")

const DISK_SIZE = 70000000
const TARGET_AVAIL_SIZE = 30000000

deletion_size_target = TARGET_AVAIL_SIZE - (DISK_SIZE - tree.size)

dirs_bigger_than_target = dfs(tree, n -> !n.isFile && n.size >= deletion_size_target)

for n in dirs_bigger_than_target
    pp(n)
end

target_dir = first(sort(dirs_bigger_than_target, by=n->n.size))
println("\nPart 2: " * string(target_dir.size))
