Base.@enum ErrorCode::UInt8 begin
    OK = 0
    ERROR = 1
end

Base.@enum Compare::UInt8 begin
    SEQ = 0
    SNE = 1
    EQ = 2
    NE = 3
    LT = 4
    LE = 5
    GT = 6
    GE = 7
end


Base.@enum Tag::Int64 begin
    Unknown = 0
    B8 = 1
    I8 = 2
    I16 = 3
    I32 = 4
    I64 = 5
    UI8 = 6
    UI16 = 7
    UI32 = 8
    UI64 = 9
    F32 = 10
    F64 = 11
    # CF32 = 12
    # CF64 = 13
    # Str = 14
    # Vector_I8 = 15
    # Vector_I16 = 16
    # Vector_I32 = 17
    # Vector_I64 = 18
    # Vector_UI8 = 19
    # Vector_UI16 = 20
    # Vector_UI32 = 21
    # Vector_UI64 = 22
    # Vector_F32 = 23
    # Vector_F64 = 24
    # Vector_CF32 = 25
    # Vector_CF64 = 26
    # Vector_B8 = 27
    # Vector_Str = 28
    # Array_I8 = 29
    # Array_I16 = 30
    # Array_I32 = 31
    # Array_I64 = 32
    # Array_UI8 = 33
    # Array_UI16 = 34
    # Array_UI32 = 35
    # Array_UI64 = 36
    # Array_F32 = 37
    # Array_F64 = 38
    # Array_CF32 = 39
    # Array_CF64 = 40
    # Array_B8 = 41
    # Array_Str = 42
end

@assert sizeof(Bool) == sizeof(UInt8) "Unknown architecture that doesn't use 8-bit for Bool"

const JVI64Pool = Int64[]
const JVU64Pool = UInt64[]
const JVF64Pool = Float64[]
const JVAnyPool = Any[]
const UnusedI64PoolSlots = Int64[]
const UnusedU64PoolSlots = Int64[]
const UnusedF64PoolSlots = Int64[]
const UnusedAnyPoolSlots = Int64[]

Base.@kwdef struct JV
    ID::Int64 = 0
end

function GetTagfromVal(x::Any)::Tag
    # 我这里把一些常用的放在了前面
    if x isa Int64
        return I64
    elseif x isa UInt64
        return UI64
    elseif x isa Float64
        return F64
        # elseif x isa Complex{Float64}
        #     return CF64
    elseif x isa Bool
        return B8
        # elseif x isa String
        #     return Tag.Str
        # elseif x isa Vector{Int64}
        #     return Tag.Vector_I64
        # elseif x isa Vector{UInt64}
        #     return Tag.Vector_UI64
        # elseif x isa Vector{Float64}
        #     return Tag.Vector_F64
        # elseif x isa Vector{Complex{Float64}}
        #     return Tag.Vector_CF64
        # elseif x isa Vector{Bool}
        #     return Tag.Vector_B8
        # elseif x isa Vector{String}
        #     return Tag.Vector_Str
        # elseif x isa Array{Int64}
        #     return Tag.Array_I64
        # elseif x isa Array{UInt64}
        #     return Tag.Array_UI64
        # elseif x isa Array{Float64}
        #     return Tag.Array_F64
        # elseif x isa Array{Complex{Float64}}
        #     return Tag.Array_CF64
        # elseif x isa Array{Bool}
        #     return Tag.Array_Bool
        # elseif x isa Array{String}
        #     return Tag.Array_Str
    elseif x isa Int8
        return I8
    elseif x isa Int16
        return I16
    elseif x isa Int32
        return I32
    elseif x isa UInt8
        return UI8
    elseif x isa UInt16
        return UI16
    elseif x isa UInt32
        return UI32
    elseif x isa Float32
        return F32
    else
        return Unknown
    end
    # elseif x isa Complex{Float32}
    #     return Tag.CF32
    # elseif x isa Vector{Int8}
    #     return Tag.Vector_I8
    # elseif x isa Vector{Int16}
    #     return Tag.Vector_I16
    # elseif x isa Vector{Int32}
    #     return Tag.Vector_I32
    # elseif x isa Vector{UInt8}
    #     return Tag.Vector_UI8
    # elseif x isa Vector{UInt16}
    #     return Tag.Vector_UI16
    # elseif x isa Vector{UInt32}
    #     return Tag.Vector_UI32
    # elseif x isa Vector{Float32}
    #     return Tag.Vector_F32
    # elseif x isa Vector{Complex{Float32}}
    #     return Tag.Vector_CF32
    # elseif x isa Array{Int8}
    #     return Tag.Array_I8
    # elseif x isa Array{Int16}
    #     return Tag.Array_I16
    # elseif x isa Array{Int32}
    #     return Tag.Array_I32
    # elseif x isa Array{UInt8}
    #     return Tag.Array_UI8
    # elseif x isa Array{UInt16}
    #     return Tag.Array_UI16
    # elseif x isa Array{UInt32}
    #     return Tag.Array_UI32
    # elseif x isa Array{Float32}
    #     return Tag.Array_F32
    # elseif x isa Array{Complex{Float32}}
    #     return Tag.Array_CF32
end

function GetTag(x::JV)::Tag
    return Tag((x.ID >> 48) & 0xFFFF)
end

function GetID(x::Int64)::Int64
    return x & 0xFFFFFFFFFFFF
end



function JV_ALLOC(@nospecialize(x::Any))
    tag = Int64(GetTagfromVal(x))
    if tag == 5
        if isempty(UnusedI64PoolSlots)
            push!(JVI64Pool, x)
            return JV(length(JVI64Pool) | (tag << 48))
        else
            id = pop!(UnusedI64PoolSlots)
            id = GetID(id)
            JVI64Pool[id] = x
            return JV(id | (tag << 48))
        end
    elseif tag == 9
        if isempty(UnusedU64PoolSlots)
            push!(JVU64Pool, x)
            return JV(length(JVU64Pool) | (tag << 48))
        else
            id = pop!(UnusedU64PoolSlots)
            id = GetID(id)
            JVU64Pool[id] = x
            return JV(id | (tag << 48))
        end
    elseif tag == 11
        if isempty(UnusedF64PoolSlots)
            push!(JVF64Pool, x)
            return JV(length(JVF64Pool) | (tag << 48))
        else
            id = pop!(UnusedF64PoolSlots)
            id = GetID(id)
            JVF64Pool[id] = x
            return JV(id | (tag << 48))
        end
    elseif (tag >= 1 && tag <= 4) || (tag >= 6 && tag <= 8) || tag == 10
        if tag == 2
            x = reinterpret(UInt8, x)
        elseif tag == 3
            x = reinterpret(UInt16, x)
        elseif tag == 4
            x = reinterpret(UInt32, x)
        elseif tag == 10
            x = reinterpret(UInt32, x)
        end
        return JV(x | (tag << 48))
        # TODO: add more types
    elseif tag == 0
        if isempty(UnusedAnyPoolSlots)
            push!(JVAnyPool, x)
            return JV(length(JVAnyPool))
        else
            id = pop!(UnusedAnyPoolSlots)
            JVAnyPool[id] = x
            return JV(id)
        end
    end
end

function JV_DEALLOC(x::JV)
    GetID(x.ID) == 0 && return nothing
    tag = Int64(GetTag(x))
    if tag == 5
        push!(UnusedI64PoolSlots, x.ID)
        JVI64Pool[GetID(x.ID)] = 0
    elseif tag == 9
        push!(UnusedU64PoolSlots, x.ID)
        JVU64Pool[GetID(x.ID)] = 0
    elseif tag == 11
        push!(UnusedF64PoolSlots, x.ID)
        JVF64Pool[GetID(x.ID)] = 0.0
        # TODO: add more types
    elseif tag == 0
        push!(UnusedAnyPoolSlots, x.ID)
        JVAnyPool[x.ID] = nothing
    end
    return nothing
end

@noinline function JV_LOAD(x::JV)
    tag = Int64(GetTag(x))
    id = GetID(x.ID)
    if tag == 5
        return JVI64Pool[id]
    elseif tag == 9
        return JVU64Pool[id]
    elseif tag == 11
        return JVF64Pool[id]
    elseif tag == 1
        return convert(Bool, id)
    elseif tag == 2
        id = convert(UInt8, id)
        return reinterpret(Int8, id)
    elseif tag == 3
        id = convert(UInt16, id)
        return reinterpret(Int16, id)
    elseif tag == 4
        id = convert(UInt32, id)
        return reinterpret(Int32, id)
    elseif tag == 6
        return convert(UInt8, id)
    elseif tag == 7
        return convert(UInt16, id)
    elseif tag == 8
        return convert(UInt32, id)
    elseif tag == 10
        id = convert(UInt32, id)
        return reinterpret(Float32, id)
    elseif tag == 0
        return JVAnyPool[id]
    end
end

Base.@kwdef struct JSym
    ID::Int64 = 0
end

const JSymCache = Base.IdDict{Symbol,JSym}()
const JSymPool = Symbol[]

function JSym(x::Symbol)
    get!(JSymCache, x) do
        push!(JSymPool, x)
        return JSym(length(JSymPool))
    end
end

@noinline function JSym_LOAD(x::JSym)
    return JSymPool[x.ID]
end

const JTypeCache = Base.IdDict{Type,Int64}()
const JTypeSlots = Type[]

function JTypeToIdent(x::Type)
    get!(JTypeCache, x) do
        push!(JTypeSlots, x)
        return Int64(length(JTypeSlots))
    end
end

function JTypeFromIdent(x::Int64)
    if x == 0
        return Any
    else
        return JTypeSlots[x]
    end
end

struct TyTuple{L,R}
    fst::L
    snd::R
end

struct TyList{T}
    len::Int64
    data::Ptr{T}
end

function Base.length(lst::TyList{T}) where {T}
    return lst.len
end

function Base.getindex(lst::TyList{T}, i::Integer) where {T}
    if i < 1 || i > lst.len
        throw(BoundsError(lst, i))
    end
    return unsafe_load(lst.data, i)
end

function Base.setindex!(lst::TyList{T}, x::T, i::Int) where {T}
    if i < 1 || i > lst.len
        throw(BoundsError(lst, i))
    end
    return unsafe_store!(lst.data, x, i)
end

function Base.unsafe_string(lst::TyList{UInt8})
    return unsafe_string(lst.data, lst.len)
end

function TyList(x::String)::TyList{UInt8}
    return TyList(length(x), pointer(x))
end

function __init__()
    empty!(JVI64Pool)
    empty!(JVU64Pool)
    empty!(JVF64Pool)
    empty!(JVAnyPool)
    empty!(UnusedI64PoolSlots)
    empty!(UnusedU64PoolSlots)
    empty!(UnusedF64PoolSlots)
    empty!(UnusedAnyPoolSlots)
    empty!(JSymCache)
    return empty!(JSymPool)
end
