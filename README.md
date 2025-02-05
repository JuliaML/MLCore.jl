# MLCore.jl

[![Build Status](https://github.com/JuliaML/MLCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaML/MLCore.jl/actions/workflows/CI.yml?query=branch%3Amain)


MLCore.jl is a Julia package providing some basic API for machine learning tasks. It is meant to be used and extended by other packages
such as [MLUtils.jl](https://github.com/JuliaML/MLUtils.jl).

Defines the following methods:
- `numobs(x)`
- `getobs(data, idx)`, `getobs(data, idxs)`, and `getobs(data)`
- `getobs!(buffer, data, idx)`

It also provides implementations for Base types such as arrays, tuples, named tuples, and dictionaries
Also provides implementations for `Tables.jl` tables.

Read the [documentation](https://juliaml.github.io/MLUtils.jl/stable/api/#Core-API) for more details.

# Related Packages

- [MLUtils.jl](https://github.com/JuliaML/MLUtils.jl): Contains a broad set of utilities for machine learning tasks. 
  Methods in MLCore.jl used to be part of MLUtils.jl but were moved to MLCore.jl to reduce dependencies.
- [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl): Defines a common API for working with data in Julia. Mainly targeting tabular data.
- [StatsAPI.jl](https://github.com/JuliaStats/StatsAPI.jl): Defines a common API for statistical operations in Julia.
  Some methods in MLCore.jl are inspired by StatsAPI.jl but have different semantics (see [this issue](https://github.com/JuliaStats/StatsAPI.jl/pull/3)).
- [LearnAPI.jl](https://github.com/JuliaAI/LearnAPI.jl): A broad API for machine learning models in Julia. 
   MLCore.jl is meant to be complementary to LearnAPI.jl (see [this issue](https://github.com/JuliaAI/LearnAPI.jl/issues/39)).

