using DelimitedFiles;

inp = readdlm("input.txt")

# If we wanted column major ordering, we'd need:
#inp = permutedims(inp)
# Turns out we can just use "eachrow"

SCORE = Dict("X" => 1,
             "Y" => 2,
             "Z" => 3)

WINS =  Dict("A" => "Y",
             "B" => "Z",
             "C" => "X")

DRAWS = Dict("A" => "X",
             "B" => "Y",
             "C" => "Z")

LOSSES= Dict("A" => "Z",
             "B" => "X",
             "C" => "Y")

function scoreround1(r)
    score = SCORE[r[2]]
    if      WINS[r[1]]  == r[2]   return score + 6
    elseif  DRAWS[r[1]] == r[2]   return score + 3
    else                          return score + 0
    end
end

p1 = sum(map(scoreround1, eachrow(inp)))
println("Part 1: " * string(p1))

function scoreround2(r)
    if      r[2] == "Z"   return SCORE[  WINS[r[1]]] + 6
    elseif  r[2] == "Y"   return SCORE[ DRAWS[r[1]]] + 3
    else                  return SCORE[LOSSES[r[1]]] + 0
    end
end

p2 = sum(map(scoreround2, eachrow(inp)))
println("Part 2: " * string(p2))
