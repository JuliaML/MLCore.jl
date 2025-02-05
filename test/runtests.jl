using MLCore
using Test
using Random
using SparseArrays
using DataFrames

@testset "MLCore.jl" begin
    # Write your tests here.
    @testset "observation" begin
        include("observation.jl")
    end
end
