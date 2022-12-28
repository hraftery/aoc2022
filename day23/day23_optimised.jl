const Loc = Tuple{Int, Int} # row, column ordering
const Locs = Set{Loc} # SortedSet{Loc} <-- interestingly, 20% slower
@enum Dir N NE E SE S SW W NW
index(e :: Enum) = Int(e) + 1
const Up    = [N, NE, NW]
const Down  = [S, SE, SW]
const Left  = [W, NW, SW]
const Right = [E, NE, SE]

function neighbour(loc :: Loc, dir :: Dir)
  #                N  NE   E  SE   S  SW   W  NW
  row = loc[1] + [-1, -1,  0,  1,  1,  1,  0, -1][index(dir)]
  col = loc[2] + [ 0,  1,  1,  1,  0, -1, -1, -1][index(dir)]
  return (row, col)
end

function neighbours(loc :: Loc)
  return [neighbour(loc, d) for d in instances(Dir)]
end

function Base.axes(locs :: Locs)
  r0, r1 = extrema([l[1] for l in locs])
  c0, c1 = extrema([l[2] for l in locs])
  return (r0:r1, c0:c1)
end

function parseinput(testcase = false)
  elves = Locs()

  open(testcase ? "input.test2" : "input.txt") do f
    for (row, l) ∈ enumerate(eachline(f))
      cols = findall(isequal('#'), l)
      union!(elves, [(row, col) for col in cols]);
    end
  end

  return elves
end

function show(elves)
  rows, cols = axes(elves)
  for r ∈ rows
    println(String([(r,c) ∈ elves ? '#' : '.' for c in cols]))
  end
end


function doround(elfLocs, count=0)
  proposals = Dict{Loc,Loc}() # dst => src
  for elfLoc ∈ elfLocs
    ns = neighbours(elfLoc)
    if !isdisjoint(elfLocs, ns) # First half
      for (check, go) ∈ circshift([(Up, N), (Down, S), (Left, W), (Right, E)], -count)
        if isdisjoint(elfLocs, ns[index.(check)])
          dst = ns[index(go)]
          if dst ∈ keys(proposals)  # Clash. So remove it since only two
            delete!(proposals, dst) # elves can have the same proposal.
          else # no clash, add to proposals
            proposals[dst] = elfLoc
          end
          break
        end
      end
    end
  end
  # Second half. Tried to combine the halves but couldn't figure out a way.
  for p in proposals
    delete!(elfLocs, p[2])
    push!(elfLocs, p[1])
  end
  
  return !isempty(proposals)
end


function part1(testcase)
  elves = parseinput(testcase)

  for count = 0:9
    doround(elves, count)
  end

  rows, cols = axes(elves)
  area = length(rows) * length(cols)
  numempty = area - length(elves)
  
  return numempty
end

function part2(testcase)
  elves = parseinput(testcase)

  for i ∈ 0:typemax(Int)
    doround(elves, i) || return i
  end
end

testcase = false
println("Part 1: " * string(part1(testcase)))
println("Part 2: " * string(part2(testcase)))

@time part1(testcase)
@time part2(testcase)




function abandoned()
  for (check, go) ∈ circshift([(Up, N), (Down, S), (Left, W), (Right, E)], -count)
    if isdisjoint(elfLocs, ns[index.(check)])    # Eg. check N, NE and NW. If clear, then
      if neighbour(ns[index(go)], go) ∉ elfLocs  # only an elf N of N could have the same
        newElfLoc = ns[index(go)]                # proposal. So if no elf, propose.
      end
      break
    end
  end
end