const INT_DIGITS = Vector{Int} # represent an integer as a vector of its digits (in arbitrary base)
const SNAFU_CHARS = "=-012"
const SNAFU_BASE = -2:2
tosnafustr(s :: INT_DIGITS) = String(map(d -> SNAFU_CHARS[1+d-first(SNAFU_BASE)], s))
fromsnafustr(s :: String) = map(c -> SNAFU_BASE[findfirst(c, SNAFU_CHARS)], collect(s))
function Base.:(+)(a :: INT_DIGITS, b :: INT_DIGITS)
  # Good discussion on element-wise operations on vectors of different lengths here:
  # https://stackoverflow.com/q/69711260/3697870
  # Just roll our own simple right-aligned version here.
  len = max(length(a), length(b))
  prepend!(a, zeros(len - length(a)))
  prepend!(b, zeros(len - length(b)))
  # Now we can use the built in.
  return a .+ b
end

function normalise(a :: INT_DIGITS, base :: UnitRange{Int})
  ret = INT_DIGITS()
  carry = 0
  for d in reverse(a)
    d += carry
    if d ∈ base
      carry = 0
    else # normalise!
      carry = fld(d - first(base), length(base))
      d = mod(d, base)
    end
    pushfirst!(ret, d)
  end
  return ret
end
normalise(a :: INT_DIGITS, base :: Int) = normalise(a, 0:(base-1))

function parseinput(testcase = false) :: Vector{String}
  return readlines(testcase ? "input.test" : "input.txt")
end

function part1(testcase)
  lines = parseinput(testcase)

  #tot = INT_DIGITS

  tot = sum(fromsnafustr.(lines))
  
  tot = normalise(tot, SNAFU_BASE)

  return tosnafustr(tot)
end


testcase = false
println("Part 1: " * string(part1(testcase)))

# @time part1(testcase)
