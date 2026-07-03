using PythonCall

# Build Python objects for the tests.
col1 = pylist([10, 20, 30])
col2 = pylist([40, 50, 60])
namedtuple = pyimport("collections").namedtuple

@testset "list / ndarray-like (positional, 0-based)" begin
    # A Python sequence is a batch of observations, indexed with Python's 0-based semantics.
    @test pyconvert(Int, getobs(col1, 1)) == 10
    @test pyconvert(Int, getobs(col1, 2)) == 20
    @test pyconvert(Int, getobs(col1, 3)) == 30
    @test_throws PyException getobs(col1, 4)
end

@testset "dict of columns (mapped element-wise)" begin
    d = pydict(Dict("a" => col1, "b" => col2))
    @test pyconvert(Dict{String,Int}, getobs(d, 1)) == Dict("a" => 10, "b" => 40)
    @test pyconvert(Dict{String,Int}, getobs(d, 3)) == Dict("a" => 30, "b" => 60)
end

@testset "tuple of columns (mapped element-wise, like Julia Tuple)" begin
    t = pytuple((col1, col2))
    @test pyconvert(Tuple{Int,Int}, getobs(t, 1)) == (10, 40)
    @test pyconvert(Tuple{Int,Int}, getobs(t, 2)) == (20, 50)
end

@testset "namedtuple keeps its type and field names" begin
    Row = namedtuple("Row", pylist(["x", "y"]))
    r = Row(col1, col2)
    obs = getobs(r, 3)
    @test pyconvert(String, obs.__class__.__name__) == "Row"
    @test pyconvert(Int, obs.x) == 30
    @test pyconvert(Int, obs.y) == 60
end

@testset "scalars are single observations (numobs == 1)" begin
    # No `len()` -> a single observation, returned as-is at i == 1, out of bounds otherwise.
    # Mirrors Julia's `getobs((1, 1, 2), 1) == (1, 1, 2)` and its `BoundsError` at i == 2.
    t = pytuple((pyint(1), pyint(1), pyint(2)))
    @test pyconvert(Tuple{Int,Int,Int}, getobs(t, 1)) == (1, 1, 2)
    @test_throws BoundsError getobs(t, 2)

    @test pyconvert(Int, getobs(pyint(7), 1)) == 7
    @test_throws BoundsError getobs(pyint(7), 2)
end

@testset "nested containers" begin
    # dict holding a tuple-of-columns; getobs descends through both.
    d = pydict(Dict("pair" => pytuple((col1, col2))))
    obs = getobs(d, 2)
    @test pyconvert(Tuple{Int,Int}, obs["pair"]) == (20, 50)
end
