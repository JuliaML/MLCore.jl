# MLCore.jl

[![Build Status](https://github.com/JuliaML/MLCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaML/MLCore.jl/actions/workflows/CI.yml?query=branch%3Amain)


MLCore.jl is a Julia package providing some basic API for machine learning tasks. It is meant to be used and extended by other packages
such as [MLUtils.jl](https://github.com/JuliaML/MLUtils.jl).

Defines the following methods:
- `numobs(x)`
- `getobs(data, idx)`, `getobs(data, idxs)`, and `getobs(data)`
- `getobs!(buffer, data, i)`

It also provides implementations for Base types such as arrays, tuples, named tuples, and dictionaries
Also provides implementations for `Tables.jl` tables.

Read the [documentation](https://juliaml.github.io/MLUtils.jl/stable/api/#Core-API) for more details.
