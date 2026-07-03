module MLCorePythonCallExt

using MLCore: MLCore, getobs
using PythonCall: Py, pyisinstance, pybuiltins, pydict

# `getobs(data, i)` for PythonCall-backed data containers (e.g. HuggingFace `datasets`, whose
# observations come back as Python objects). Python indexes with 0-based semantics, so shift by
# one. A Python `dict` is treated as a batch of named columns and mapped over element-wise, so a
# dict-of-columns yields a dict holding the single `i`-th observation of each column.
function MLCore.getobs(data::Py, i::Integer)
    if pyisinstance(data, pybuiltins.dict)
        return pydict(Dict(k => getobs(v, i) for (k, v) in data.items()))
    else
        return data[i - 1]   # lists, numpy arrays, and other `__getitem__`-ables (batch-first)
    end
end

end # module MLCorePythonCallExt
