"""
    ThreadQueue
A thread safe queue implementation for using as the queue for BFS.

Original: https://github.com/JuliaGraphs/Graphs.jl/blob/master/src/Parallel/traversals/bfs.jl
"""

using Base.Threads: @threads, nthreads, Atomic, atomic_add!, atomic_cas!

struct ThreadQueue{T,N<:Integer}
    data::Vector{T}
    head::Atomic{N} # Index of the head
    tail::Atomic{N} # Index of the tail
end

function ThreadQueue(T::Type, maxlength::N) where {N<:Integer}
    q = ThreadQueue(Vector{T}(undef, maxlength), Atomic{N}(1), Atomic{N}(1))
    return q
end

function enqueue!(q::ThreadQueue{T,N}, val::T) where {T} where {N}
    # TODO: check that head > tail
    offset = atomic_add!(q.tail, one(N))
    q.data[offset] = val
    return offset
end

function dequeue!(q::ThreadQueue{T,N}) where {T} where {N}
    # TODO: check that head < tail
    offset = atomic_add!(q.head, one(N))
    return q.data[offset]
end

function dequeue_all!(q::ThreadQueue{T,N}) where {T} where {N}
    # TODO: check that head < tail
    d = q.data[q.head[]:(q.tail[] - 1)]
    q.head[] = q.tail[]

    return d
end

function isempty(q::ThreadQueue{T,N}) where {T} where {N}
    return (q.head[] == q.tail[]) && q.head != one(N)
end

function getindex(q::ThreadQueue{T}, iter) where {T}
    return q.data[iter]
end
