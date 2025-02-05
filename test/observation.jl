struct FallbackType end
Base.getindex(::FallbackType, i) = 1234
Base.length(::FallbackType) = 5678

# create some test data
Random.seed!(1335)
const X = rand(4, 15)
const y = repeat(["setosa","versicolor","virginica"], inner = 5)
const Y = permutedims(hcat(y,y), [2,1])
const Yt = hcat(y,y)
const yt = Y[1:1,:]
const Xv = view(X,:,:)
const yv = view(y,:)
const XX = rand(20,30,15)
const XXX = rand(3,20,30,15)
const vars = (X, Xv, yv, XX, XXX, y)
const tuples = ((X,y), (X,Y), (XX,X,y), (XXX,XX,X,y))
const Xs = sprand(10, 15, 0.5)
const ys = sprand(15, 0.5)
const X1 = hcat((1:15 for i = 1:10)...)'
const Y1 = collect(1:15)


@testset "fallbacks" begin
    x = FallbackType()
    @test getobs(x, 3) == 1234
    @test numobs(x) == 5678
end

@testset "array" begin
    a = rand(2,3)
    @test numobs(a) == 3
    @test @inferred getobs(a, 1) == a[:,1]
    @test @inferred getobs(a, 2) == a[:,2]
    @test @inferred getobs(a, 1:2) == a[:,1:2]
end

@testset "0-dim SubArray" begin
    v = view([3], 1)
    @test @inferred(numobs(v)) === 1
    @test @inferred(getobs(v, 1)) === 3
    @test_throws BoundsError getobs(v, 2)
    @test_throws BoundsError getobs(v, 2:3)
end


@testset "named tuple" begin
    X2, Y2 = rand(2, 3), rand(3)
    dataset = (x=X2, y=Y2)
    @test numobs(dataset) == 3
    o = @inferred getobs(dataset, 2)
    @test o.x == X2[:,2]
    @test o.y == Y2[2]

    o = @inferred getobs(dataset, 1:2)
    @test o.x == X2[:,1:2]
    @test o.y == Y2[1:2]
end

@testset "dict" begin
    dataset = Dict("X" => X, "y" => y) 
    @test numobs(dataset) == 15

    @test_broken @inferred getobs(dataset, 2) # not inferred
    o = getobs(dataset, 2)
    @test o["X"] == X[:,2]
    @test o["y"] == y[2]

    o = getobs(dataset, 1:2)
    @test o["X"] == X[:,1:2]
    @test o["y"] == y[1:2]
end

@testset "numobs" begin
    @test_throws MethodError numobs(X,X)
    @test_throws MethodError numobs(X,y)

    @testset "Array, SparseArray, and Tuple" begin
        @test_throws DimensionMismatch numobs((X,XX,rand(100)))
        @test_throws DimensionMismatch numobs((X,X'))
        for var in (Xs, ys, vars...)
            @test @inferred(numobs(var)) === 15
        end
        @test @inferred(numobs(())) === 0
    end

    @testset "SubArray" begin
        @test @inferred(numobs(view(X,:,:))) === 15
        @test @inferred(numobs(view(X,:,:))) === 15
        @test @inferred(numobs(view(XX,:,:,:))) === 15
        @test @inferred(numobs(view(XXX,:,:,:,:))) === 15
        @test @inferred(numobs(view(y,:))) === 15
        @test @inferred(numobs(view(Y,:,:))) === 15
    end
end

@testset "getobs" begin
    @testset "Array and Subarray" begin
        # access outside numobs bounds
        @test_throws BoundsError getobs(X, -1)
        @test_throws BoundsError getobs(X, 0)
        @test_throws BoundsError getobs(X, 16)
        for i in (2, 2:10, [2,1,4])
            @test getobs(XX, i) == XX[:, :, i]
        end
        for i in (2, 1:15, 2:10, [2,5,7], [2,1])
            @test typeof(getobs(Xv, i)) <: Array
            @test typeof(getobs(yv, i)) <: ((i isa Int) ? String : Array)
            @test all(getobs(Xv, i) .== X[:, i])
            @test getobs(Xv,i)  == X[:,i]
            @test getobs(X,i)   == X[:,i]
            @test getobs(XX,i)  == XX[:,:,i]
            @test getobs(XXX,i) == XXX[:,:,:,i]
            @test getobs(y,i)   == y[i]
            @test getobs(yv,i)  == y[i]
            @test getobs(Y,i)   == Y[:,i]
        end
    end

    @testset "SparseArray" begin
        @test typeof(getobs(Xs,2)) <: SparseVector
        @test typeof(getobs(Xs,1:5)) <: SparseMatrixCSC
        @test typeof(getobs(ys,2)) <: Float64
        @test typeof(getobs(ys,1:5)) <: SparseVector
        for i in (2, 1:15, 2:10, [2,5,7], [2,1])
            @test getobs(Xs,i) == Xs[:,i]
            @test getobs(ys,i) == ys[i]
        end
    end

    @testset "Tuple" begin
        # bounds checking correctly
        @test_throws BoundsError getobs((X,y), 16)
        # special case empty tuple
        @test @inferred(getobs((), 10)) === ()
        tx, ty = getobs((Xv, yv), 2:5)
        @test typeof(tx) <: Array
        @test typeof(ty) <: Array
        for i in (1:15, 2:10, [2,5,7], [2,1])
            @test_throws DimensionMismatch getobs((X', y), i)
            @test @inferred(getobs((X,y), i))  == (X[:,i], y[i])
            @test @inferred(getobs((X,yv), i)) == (X[:,i], y[i])
            @test @inferred(getobs((Xv,y), i)) == (X[:,i], y[i])
            @test @inferred(getobs((X,Y), i))  == (X[:,i], Y[:,i])
            @test @inferred(getobs((X,yt), i)) == (X[:,i], yt[:,i])
            @test @inferred(getobs((XX,X,y), i)) == (XX[:,:,i], X[:,i], y[i])
            # compare if obs match in tuple
            x1, y1 = getobs((X1,Y1), i)
            @test all(x1' .== y1)
            x1, y1, z1 = getobs((X1,Y1,sparse(X1)), i)
            @test all(x1' .== y1)
            @test all(x1 .== z1)
        end
        @test getobs((Xv,y), 2) == (X[:,2], y[2])
        @test getobs((X,yv), 2) == (X[:,2], y[2])
        @test getobs((X,Y), 2) == (X[:,2], Y[:,2])
        @test getobs((XX,X,y), 2) == (XX[:,:,2], X[:,2], y[2])
    end
end

@testset "getobs!" begin
    @testset "Array and Subarray" begin
        Xbuf = similar(X)
        getobs!(Xbuf, X)
        @test Xbuf == X
        # access outside numobs bounds
        @test_throws BoundsError getobs!(Xbuf, X, -1)
        @test_throws BoundsError getobs!(Xbuf, X, 0)
        @test_throws BoundsError getobs!(Xbuf, X, 151)
        
        buff = zeros(4)
        @test @inferred(getobs!(buff, X, 5)) == getobs(X, 5)
        
        buff = zeros(4, 8)
        @test @inferred(getobs!(buff, X, 3:10)) == getobs(X, 3:10)
        
        buff = zeros(20,30)
        @test @inferred(getobs!(buff, XX, 5)) == XX[:,:,5]
        
        buff = zeros(20, 30, 5)
        @test @inferred(getobs!(buff, XX, 6:10)) == XX[:,:,6:10]
        
        # string vector
        @test getobs!("setosa", y, 1) == "setosa"
        @test getobs!(nothing, y, 1) == "setosa"
    end

    @testset "SparseArray" begin
        # Sparse Arrays opt-out of buffer usage
        @test @inferred(getobs!(nothing, Xs, 1)) == getobs(Xs, 1)
        @test @inferred(getobs!(nothing, Xs, 5:10)) == getobs(Xs, 5:10)
        @test @inferred(getobs!(nothing, ys, 1)) === getobs(ys, 1)
        @test @inferred(getobs!(nothing, ys, 5:10)) == getobs(ys, 5:10)
    end

    @testset "Tuple" begin
        @test_throws MethodError getobs!((nothing,nothing), (X,y))
        @test getobs!((nothing,nothing), (X,y), 1:5) == getobs((X,y), 1:5)
        @test_throws MethodError getobs!((nothing,nothing,nothing), (X,y))
        xbuf = zeros(4,2)
        ybuf = ["foo", "bar"]
        @test_throws MethodError getobs!((xbuf,), (X,y))
        @test_throws MethodError getobs!((xbuf,ybuf,ybuf), (X,y))
        @test_throws DimensionMismatch getobs!((xbuf,), (X,y), 1:5)
        @test_throws DimensionMismatch getobs!((xbuf,ybuf,ybuf), (X,y), 1:5)
        @test @inferred(getobs!((xbuf,ybuf),(X,y), 2:3)) === (xbuf,ybuf)
        @test xbuf == getobs(X, 2:3)
        @test ybuf == getobs(y, 2:3)
        @test @inferred(getobs!((xbuf,ybuf),(X,y), [14,5])) === (xbuf,ybuf)
        @test xbuf == getobs(X, [14,5])
        @test ybuf == getobs(y, [14,5])

        @test getobs!((nothing,xbuf),(Xs,X), 3:4) == (getobs(Xs,3:4),xbuf)
        @test xbuf == getobs(X,3:4)
    end

    @testset "tables" begin
        df = DataFrame(a=[1,2,3], y=["a","b","c"])
        @test getobs(df) == df
        @test getobs(df, 1) == df[1,:]
        @test getobs(df, 2:3) == df[2:3,:]
        @test numobs(df) == 3
    end
end
