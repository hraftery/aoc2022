include("rects.jl")

using Plots
using Test

@testset "rects" begin
    test_nooverlap1()
    test_nooverlap2()
    test_overlaptotal()
    test_overlapbl()
    test_overlapb()
    test_overlapbr()
    test_overlapr()
    test_overlaptr()
    test_overlapt()
    test_overlaptl()
    test_overlapl()
    test_overlaptb()
    test_overlaplr()
    test_overlaptlr()
    test_overlapblr()
    test_overlaptbl()
    test_overlaptbr()
end

function test_nooverlap1()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(-5, -5), Point(-1,-1))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 1
    @test r3[1] == r1
end

function test_nooverlap2()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(11, -5), Point(12,-1))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 1
    @test r3[1] == r1
end

function test_overlaptotal()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(4, 4), Point(6,6))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 4
    @test r3[1] == Rect(0,0,3,10)
    @test r3[2] == Rect(7,0,10,10)
    @test r3[3] == Rect(4,0,6,3)
    @test r3[4] == Rect(4,7,6,10)
end

function test_overlapbl()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(-2, -2), Point(6,6))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 2
    @test r3[1] == Rect(7,0,10,10)
    @test r3[2] == Rect(0,7,6,10)
end

function test_overlapb()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(4, -2), Point(6,6))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 3
    @test r3[1] == Rect(0,0,3,10)
    @test r3[2] == Rect(7,0,10,10)
    @test r3[3] == Rect(4,7,6,10)
end

function test_overlapbr()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(4, -2), Point(12,6))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 2
    @test r3[1] == Rect(0,0,3,10)
    @test r3[2] == Rect(4,7,10,10)
end

function test_overlapr()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(4, 4), Point(12,6))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 3
    @test r3[1] == Rect(0,0,3,10)
    @test r3[2] == Rect(4,0,10,3)
    @test r3[3] == Rect(4,7,10,10)
end

function test_overlaptr()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(4, 4), Point(12,12))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 2
    @test r3[1] == Rect(0,0,3,10)
    @test r3[2] == Rect(4,0,10,3)
end

function test_overlapt()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(4, 4), Point(6,12))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 3
    @test r3[1] == Rect(0,0,3,10)
    @test r3[2] == Rect(7,0,10,10)
    @test r3[3] == Rect(4,0,6,3)
end

function test_overlaptl()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(-2, 4), Point(6,12))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 2
    @test r3[1] == Rect(7,0,10,10)
    @test r3[2] == Rect(0,0,6,3)
end

function test_overlapl()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(-2, 4), Point(6,6))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 3
    @test r3[1] == Rect(7,0,10,10)
    @test r3[2] == Rect(0,0,6,3)
    @test r3[3] == Rect(0,7,6,10)
end

function test_overlaptb()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(4, -2), Point(6,12))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 2
    @test r3[1] == Rect(0,0,3,10)
    @test r3[2] == Rect(7,0,10,10)
end

function test_overlaplr()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(-2, 4), Point(12,6))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 2
    @test r3[1] == Rect(0,0,10,3)
    @test r3[2] == Rect(0,7,10,10)
end

function test_overlaptlr()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(-2, 4), Point(12,12))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 1
    @test r3[1] == Rect(0,0,10,3)
end

function test_overlapblr()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(-2, -2), Point(12,6))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 1
    @test r3[1] == Rect(0,7,10,10)
end

function test_overlaptbl()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(-2, -2), Point(6,12))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 1
    @test r3[1] == Rect(7,0,10,10)
end

function test_overlaptbr()
    r1 = Rect(Point(0,0), Point(10, 10))
    r2 = Rect(Point(4, -2), Point(12,12))
    r3 = rectdiff(r1, r2)
    plot_test(r1, r2, r3)
    @test length(r3) == 1
    @test r3[1] == Rect(0,0,3,10)
end

rect2shape(r :: Rect) = Shape([r.bl.x, r.tr.x, r.tr.x, r.bl.x], [r.bl.y, r.bl.y, r.tr.y, r.tr.y])

function plot_rect(r :: Rect, opacity=0.5)
    plot!(rect2shape(r), opacity=opacity)
end

function plot_test(r1 :: Rect, r2 :: Rect, r3 :: Vector{Rect})
    plot(-1:11, -1:11)
    plot_rect(r1)
    plot_rect(r2)
    plot_rect.(r3)
    plot!() #force update
end
