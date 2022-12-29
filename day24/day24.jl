using DataStructures

const Loc = Tuple{Int, Int} # row, column ordering
const Locs = Set{Loc}
@enum Dir right down left up
const DirChars  = ">v<^"
index(e :: Enum) = Int(e) + 1
toChar(d :: Dir) = DirChars[index(d)]
toDir(c :: Char) = Dir(findfirst(c, DirChars)-1)
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
  # Run DFS
  q = Queue{Tuple{Loc, Valley, Vector{Loc}}}()  # node queue: (current location, current valley, path history)
  enqueue!(q, (curloc, valley, [])) # weird that Queue requires types and can't be given initial contents?
	
	while !isempty(q) # could be replaced by "true"
		curloc, valley, history = dequeue!(q)
		
    nextHistory = [history; curloc]
    nextValley = steptime(valley)
    
		if isend(neighbour(curloc, down), valley) # Then we can exit the valley,
      return nextHistory                      # so we're done.
    end
 
    for nextMove in filter(l -> isclear(l, nextValley), [curloc; neighbours(curloc)])
      # Oh nice, immutability means they can all safely share the same nextValley
      enqueue!(q, (nextMove, nextValley, nextHistory))
    end
	end
end

function part1(testcase)
  valley = parseinput(testcase)
  curloc = (0, 1) # start just above the top left corner

  path = findpath(curloc, valley)

  for loc in path
    show(valley, loc)
    println("")
    valley = steptime(valley)
  end

  return length(path)
end

testcase = true
println("Part 1: " * string(part1(testcase)))
#println("Part 2: " * string(part2(testcase)))

#@time part1(testcase)
#@time part2(testcase)
