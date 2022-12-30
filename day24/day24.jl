const Loc = Tuple{Int, Int} # row, column ordering
const Locs = Set{Loc}
@enum Dir right down left up
const DirChars  = ">v<^"
index(e :: Enum) = Int(e) + 1
toChar(d :: Dir) = DirChars[index(d)]
toDir(c :: Char) = Dir(findfirst(c, DirChars)-1)
const Opposites = Dict(right => left, down => up, left => right, up => down)
const Blizzards = Tuple{Locs, Locs, Locs, Locs}
EmptyBlizzards() = (Locs(), Locs(), Locs(), Locs()) # weirdly necessary?

function move(loc :: Loc, dir :: Dir, rows :: Int, cols :: Int)
  row = mod(loc[1] + [0, 1, 0, -1][index(dir)], 1:rows)
  col = mod(loc[2] + [1, 0, -1, 0][index(dir)], 1:cols)
  return (row, col)
end

struct Valley
  rows :: Int
  cols :: Int
  blizzards :: Blizzards
end

isstart(l :: Loc, _ :: Valley) = l == (0, 1)
isend(  l :: Loc, v :: Valley) = l == (v.rows+1, v.cols)
isclear(l :: Loc, v :: Valley) = isstart(l, v) || isend(l, v) ||
                                (l[1] ∈ 1:v.rows && l[2] ∈ 1:v.cols &&
                                 !any([l ∈ bs for bs in v.blizzards]))

function neighbour(loc :: Loc, dir :: Dir)
  #                 R   D   L   U
  row = loc[1] + [  0,  1,  0, -1][index(dir)]
  col = loc[2] + [  1,  0, -1,  0][index(dir)]
  return (row, col)
end

function neighbours(loc :: Loc)
  return [neighbour(loc, d) for d in instances(Dir)]
end

function parseinput(testcase = false) :: Valley
  b = EmptyBlizzards()

  f = open(testcase ? "input.test2" : "input.txt")
  length(readline(f)) # discard top wall, which contains nothing we don't know

  for (row, l) ∈ enumerate(eachline(f))
    # last row? Then discard bottom wall too, and return.
    eof(f) && return Valley(row-1, length(l)-2, b)

    for (col, c) ∈ enumerate(collect(l))
      if c ∈ DirChars
        push!(b[index(toDir(c))], (row, col-1)) # -1 to remove wall
      end
    end
  end

  error("Shouldn't be here.")
end

function show(v :: Valley, loc :: Loc = (0,0))
  println("#" * (loc == (0,1) ? "E" : " ") * repeat('#', v.cols))
  for row ∈ 1:v.rows
    print("#")
    for col in 1:v.cols
      bs = [(row,col) ∈ v.blizzards[index(d)] for d ∈ instances(Dir)]
      c = count(bs)
      if     c == 0    print(loc == (row,col) ? "E" : ".")
      elseif c >= 2    print(string(c))
      else             print(DirChars[findfirst(bs)])
      end
    end
    println("#")
  end
  println(repeat('#', v.cols) * (loc == (v.rows+1,v.cols) ? "E" : " ") * "#")
end

function steptime(v :: Valley)
  newBlizzards = EmptyBlizzards()
  for d ∈ instances(Dir)
    union!(newBlizzards[index(d)], [move(l, d, v.rows, v.cols) for l in v.blizzards[index(d)]])
  end
  return Valley(v.rows, v.cols, newBlizzards)
end

function findpath(curloc :: Loc, valley :: Valley)
  # Run DFS using a single-threaded frontier approach. So instead of a queue of nodes to visit, we
  # build a set of nodes representing the next frontier, and switch to it at the end of the current.
  # Note we actually use a dict so only the node location is used as the key for uniqueness checks.
  # Making the frontier unique makes **all** the difference to runtime complexity.

  # Start with just the start node.
  nextFrontier = Dict([(curloc, [curloc])]) # node dict: (current location => path history).
  
  # pre-calculate all future valleys to save clogging up the queue
  valleys = [valley]
  for _ ∈ Base.OneTo(lcm(valley.rows, valley.cols)-1) # after that, they just start repeating
    push!(valleys, steptime(last(valleys)))
  end

  maxdist = 0

	while !isempty(nextFrontier)
    frontier = nextFrontier
    nextFrontier = typeof(nextFrontier)() # start fresh
    nextValley = nothing # will be set in first loop iteration below

    for (curloc, history) in frontier
      # Step 1: create next state
      nextHistory = [history; curloc]
      if isnothing(nextValley) # will be same for all nodes in frontier, so set once
        nextValley = valleys[mod1(length(nextHistory)+1, lastindex(valleys))]
      end

      # Step 2: check if we can exit the valley.
      if isend(neighbour(curloc, down), valley)
        return (nextHistory, nextValley)              # If so, get outta here.
      end

      # Step 3: take Manhatten distance as rough indication of progress towards goal.
      dist = sum(curloc)
      if dist > maxdist
        maxdist = dist
#        @show (curloc, length(history))
      elseif dist < maxdist - 15 # try pruning searches that are X units behind the front runners
        continue # Honestly, not a big time impact. But has some space impact.
      end
 
      # Step 4: add neighbours to next frontier
      for nextMove in filter(l -> isclear(l, nextValley), [curloc; neighbours(curloc)])
        # Oh nice, immutability means they can all safely share the same nextValley, so don't include it.
        get!(nextFrontier, nextMove, nextHistory) # Despite the name, adds nextMove if it doesn't exist.
      end
    end
	end
  error("Path not found")
end

function part1(testcase)
  valley = parseinput(testcase)
  curloc = (0, 1) # start just above the top left corner

  path, _ = findpath(curloc, valley)

  if testcase
    for loc in path
      show(valley, loc)
      println("")
      valley = steptime(valley)
    end
  end

  return length(path)
end

function rotate180(v :: Valley)
  # Rotate all blizzard locations
  bs = [Set([(1 + v.rows - r, 1 + v.cols - c) for (r,c) in locs]) for locs in v.blizzards]
  # Then swap left<->right and up<->down
  return Valley(v.rows, v.cols, Tuple(bs[[index(Opposites[d]) for d in instances(Dir)]]))
end

function part2(testcase)
  pathlengths = Int[]

  valley = parseinput(testcase)
  curloc = (0, 1) # start just above the top left corner

  path, valley = findpath(curloc, valley)
  push!(pathlengths, length(path))

  # Now to go back, we can restart the search using the current valley, because any
  # alternate paths are equivalent to following the optimal path and then staying put.
  # So just rotate the current valley 180° and go again.
  valley = rotate180(valley)
  curloc = (0, 1)
  path, valley = findpath(curloc, valley)
  push!(pathlengths, length(path))

  # And one more time back the other way
  valley = rotate180(valley)
  curloc = (0, 1)
  path, valley = findpath(curloc, valley)
  push!(pathlengths, length(path))

  return sum(pathlengths)
end


testcase = false
println("Part 1: " * string(part1(testcase)))
println("Part 2: " * string(part2(testcase)))

@time part1(testcase)
@time part2(testcase)
