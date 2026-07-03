module MLCorePythonCallExt

using MLCore: MLCore, getobs
using PythonCall: Py, pyisinstance, pybuiltins, pydict, pytuple, pylist, pyhasattr, pylen

# `getobs(data, i)` for PythonCall-backed data containers (e.g. HuggingFace `datasets`, whose
# observations come back as Python objects). Mirrors MLCore's Julia semantics:
#
# - `dict` and `tuple`/`namedtuple` are batches of columns, mapped over element-wise: a
#   dict/tuple-of-columns yields a dict/tuple holding the single `i`-th observation of each
#   column (matching `getobs(::Dict)` and `getobs(::Tuple)` in Julia). namedtuples keep their
#   type and field names.
# - anything with a length (list, numpy array, str, any `__len__`-able) is a batch-first
#   sequence of observations, indexed positionally with Python's 0-based semantics (`data[i-1]`).
# - anything without a length (int, float, numpy scalar, 0-d array) is a single observation, the
#   Python analogue of a Julia scalar with `numobs == 1`: returned as-is at `i == 1`, out of
#   bounds otherwise. This makes e.g. a tuple of scalars behave like `getobs((1, 2, 3), i)`.
function MLCore.getobs(data::Py, i::Integer)
    if pyisinstance(data, pybuiltins.dict)
        return pydict(Dict(k => getobs(v, i) for (k, v) in data.items()))
    elseif pyisinstance(data, pybuiltins.tuple)
        obs = [getobs(v, i) for v in data]
        # `_make` marks a namedtuple; use it to preserve the type and field names.
        return pyhasattr(data, "_make") ? data._make(pylist(obs)) : pytuple(obs)
    elseif _haslen(data)
        return data[i - 1]
    else
        i == 1 || throw(BoundsError(data, i))
        return data
    end
end

# A working `len()` marks a positionally-indexable batch. The `__len__` *attribute* is not a
# reliable signal (numpy scalars and 0-d arrays expose it but it raises), so we probe `len()`.
_haslen(x::Py) = try
    pylen(x)
    true
catch
    false
end

end # module MLCorePythonCallExt
