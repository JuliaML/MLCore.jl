# MLCore

[![Build Status](https://github.com/JuliaML/MLCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaML/MLCore.jl/actions/workflows/CI.yml?query=branch%3Amain)


MLCore provides the basic API for machine learning in Julia, meant to be used and extended by other packages
such as [MLUtils.jl](https://github.com/JuliaML/MLUtils.jl).

Defines the following methods:
- `numobs(x)`
- `getobs(data, i)`
- `getobs!(buffer, data, i)`

It also provides implementations for Base types such as arrays, tuples, named tuples, and dictionaries
Also provides implementations for `Tables.jl` tables.

Read the [documentation](https://juliaml.github.io/MLUtils.jl/stable/api/#Core-API) for more details.
