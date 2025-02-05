module MLCore

# using SimpleTraits: @traitfn, @traitimpl, @traitdef
using Tables: Tables
using DataAPI: DataAPI
using SimpleTraits

@traitdef IsTable{X}
@traitimpl IsTable{X} <- Tables.istable(X)

include("observation.jl")
export numobs, getobs, getobs!

end
