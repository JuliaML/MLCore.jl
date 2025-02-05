
# Write your package code here.
"""
    numobs(data)

Return the total number of observations contained in `data`.

If `data` does not have `numobs` defined, 
then in the case of `Tables.istable(data) == true`
returns the number of rows, otherwise returns `length(data)`.

Authors of custom data containers should implement
`Base.length` for their type instead of `numobs`.
`numobs` should only be implemented for types where there is a
difference between `numobs` and `Base.length`
(such as multi-dimensional arrays).

`numobs` supports by default nested combinations of arrays, tuples,
named tuples, and dictionaries. 

See also [`getobs`](@ref).

# Examples

```jldoctest
julia> x = (a = [1, 2, 3], b = ones(6, 3)); # named tuples

julia> numobs(x)
3

julia> x = Dict(:a => [1, 2, 3], :b => ones(6, 3)); # dictionaries

julia> numobs(x) 
3
```
All internal containers must have the same number of observations:
```julia
julia> x = (a = [1, 2, 3, 4], b = ones(6, 3));

julia> numobs(x)
ERROR: DimensionMismatch: All data containers must have the same number of observations.
Stacktrace:
 [1] _check_numobs_error()
   @ MLCore ~/.julia/dev/MLCore/src/observation.jl:176
 [2] _check_numobs
   @ ~/.julia/dev/MLCore/src/observation.jl:185 [inlined]
 [3] numobs(data::@NamedTuple{a::Vector{Int64}, b::Matrix{Float64}})
   @ MLCore ~/.julia/dev/MLCore/src/observation.jl:190
 [4] top-level scope
   @ REPL[13]:1
```
"""
function numobs end

# Generic Fallbacks
@traitfn numobs(data::X) where {X; IsTable{X}} = DataAPI.nrow(data)
@traitfn numobs(data::X) where {X; !IsTable{X}} = length(data)


"""
    getobs(data, [idx])

Return the observations corresponding to the observation index `idx`.

The index `idx` is an integer with values in the range `1:numobs(data)`.
Types can optionally support `idx` being an array of integers.

If `data` does not have `getobs` defined,
then in the case of `Tables.table(data) == true`
returns the row(s) in position `idx`, otherwise returns `data[idx]`.

Authors of custom data containers should implement
`Base.getindex` for their type instead of `getobs`.
`getobs` should only be implemented for types where there is a
difference between `getobs` and `Base.getindex`
(such as multi-dimensional arrays).

The returned observation(s) should be in the form intended to
be passed as-is to some learning algorithm. There is no strict
interface requirement on how this "actual data" must look like.
Every author behind some custom data container can make this
decision themselves.
The output should be consistent when `idx` is a scalar vs vector.

`getobs` supports by default nested combinations of array, tuple,
named tuples, and dictionaries. 

The return from `getobs` should always be a materialized object,
not a view, altough it can be a reference to the original data. 

If the argument `idx` is not provided, `getobs(data)` should return
a materialized version of the data.

See also [`getobs!`](@ref) and [`numobs`](@ref).

# Examples

```jldoctest
julia> x = (a = [1, 2, 3], b = rand(6, 3));

julia> getobs(x, 2) == (a = 2, b = x.b[:, 2])
true

julia> getobs(x, [1, 3]) == (a = [1, 3], b = x.b[:, [1, 3]])
true

julia> x = Dict(:a => [1, 2, 3], :b => rand(6, 3));

julia> getobs(x, 2) == Dict(:a => 2, :b => x[:b][:, 2])
true

julia> getobs(x, [1, 3]) == Dict(:a => [1, 3], :b => x[:b][:, [1, 3]])
true

julia> struct DummyDataset end

julia> MLCore.numobs(d::DummyDataset) = 10

julia> MLCore.getobs(d::DummyDataset) = [1:10;] 

julia> MLCore.getobs(d::DummyDataset, i::Int) = 0 < i <= numobs(d) ? i : throw(ArgumentError("Index out of bounds"))
```
"""
function getobs end

# Generic Fallbacks

getobs(data) = data

@traitfn getobs(data::X, idx) where {X; IsTable{X}} = Tables.subset(data, idx, viewhint=false)
@traitfn getobs(data::X, idx) where {X; !IsTable{X}} = data[idx]


"""
    getobs!(buffer, data, idx)

Inplace version of `getobs(data, idx)`. If this method
is defined for the type of `data`, then `buffer` should be used
to store the result, instead of allocating a dedicated object.

Implementing this function is optional. In the case no such
method is provided for the type of `data`, then `buffer` will be
*ignored* and the result of [`getobs`](@ref) returned. This could be
because the type of `data` may not lend itself to the concept
of `copy!`. Thus, supporting a custom `getobs!` is optional
and not required.

Custom implementations of `getobs!` should be consistent with
[`getobs`](@ref) in terms of the output format,
that is `getobs!(buffer, data, idx) == getobs(data, idx)`.

See also [`getobs`](@ref) and [`numobs`](@ref). 
"""
function getobs! end
# getobs!(buffer, data) = getobs(data)
getobs!(buffer, data, idx) = getobs(data, idx)

# --------------------------------------------------------------------
# Arrays
# We are very opinionated with arrays: the observation dimension
# is th last dimension. For different behavior wrap the array in 
# a custom type, e.g. with Tables.table.


numobs(A::AbstractArray{<:Any, N}) where {N} = size(A, N)

# 0-dim arrays
numobs(A::AbstractArray{<:Any, 0}) = 1

function getobs(A::AbstractArray{<:Any, N}, idx) where N
    I = ntuple(_ -> :, N-1)
    return A[I..., idx]
end

getobs(A::AbstractArray{<:Any, 0}, idx) = A[idx]

function getobs!(buffer::AbstractArray, A::AbstractArray{<:Any, N}, idx) where N
    I = ntuple(_ -> :, N-1)
    buffer .= view(A, I..., idx)
    return buffer
end

function getobs!(buffer::AbstractArray, A::AbstractArray)
    buffer .= A
    return buffer
end

# --------------------------------------------------------------------
# Tuples and NamedTuples

_check_numobs_error() =
    throw(DimensionMismatch("All data containers must have the same number of observations."))

function _check_numobs(data::Union{Tuple, NamedTuple, Dict})
    length(data) == 0 && return 0
    n = numobs(data[first(keys(data))])

    for i in keys(data)
        ni = numobs(data[i])
        n == ni || _check_numobs_error()
    end
    return n
end

numobs(data::Union{Tuple, NamedTuple}) = _check_numobs(data)


getobs(tup::Union{Tuple, NamedTuple}) = map(x -> getobs(x), tup)

Base.@propagate_inbounds function getobs(tup::Union{Tuple, NamedTuple}, indices)
    @boundscheck _check_numobs(tup)
    return map(x -> getobs(x, indices), tup)
end

function getobs!(buffers::Union{Tuple, NamedTuple},
                 tup::Union{Tuple, NamedTuple},
                 indices)
    _check_numobs(tup)

    return map(buffers, tup) do buffer, x
        getobs!(buffer, x, indices)
    end
end

## Dict

numobs(data::Dict) = _check_numobs(data)

getobs(data::Dict, i) = Dict(k => getobs(v, i) for (k, v) in pairs(data))

getobs(data::Dict) = Dict(k => getobs(v) for (k, v) in pairs(data))

function getobs!(buffers, data::Dict, i)
    for (k, v) in pairs(data)
        getobs!(buffers[k], v, i)
    end

    return buffers
end
