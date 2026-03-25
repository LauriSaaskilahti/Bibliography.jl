# ── Global state ──────────────────────────────────────────────────────────────

const _LIBRARY = ReferenceLibrary()
const _RECORDS = CitationRecord[]

# ── Library management ────────────────────────────────────────────────────────

"""
    load_bibliography!(files::String...)

Load BibTeX entries from one or more `.bib` files into the global reference
library. Returns the total number of entries in the library.

```julia
load_bibliography!("refs.bib")
load_bibliography!("primary.bib", "secondary.bib")
```
"""
function load_bibliography!(files::String...)
    for file in files
        for c in read_references(file)
            _LIBRARY.entries[c.key] = c
        end
        push!(_LIBRARY.source_files, abspath(file))
    end
    length(_LIBRARY.entries)
end

"""
    bibliography()

Return the global `ReferenceLibrary`.
"""
bibliography() = _LIBRARY

"""
    clear_bibliography!()

Reset the global reference library and all citation records.
"""
function clear_bibliography!()
    empty!(_LIBRARY.entries)
    empty!(_LIBRARY.source_files)
    empty!(_RECORDS)
    nothing
end

# ── Internal helpers ──────────────────────────────────────────────────────────

"""Extract the assigned variable name from an expression, if it's a simple assignment."""
function _extract_variable(expr)
    expr isa Expr || return nothing
    if expr.head == :(=)
        lhs = expr.args[1]
        lhs isa Symbol && return lhs
        # typed assignment  x::T = val
        if lhs isa Expr && lhs.head == :(::) && lhs.args[1] isa Symbol
            return lhs.args[1]
        end
    end
    nothing
end

"""Record a citation into the global registry. Called at runtime by the macros.
Returns the `CitationRecord` and (if available) the `Citation` from the library."""
function _record_citation(key::AbstractString, file, line, code, var, kind)
    record = CitationRecord(String(key), String(file), Int(line), String(code), var, kind)
    push!(_RECORDS, record)
    if !isempty(_LIBRARY.entries) && !haskey(_LIBRARY.entries, String(key))
        @warn "Citation key '$(key)' not found in reference library" _file=file _line=line
    end
    record
end

# ── Macros ────────────────────────────────────────────────────────────────────
#
# PRIMARY usage: semicolon-separated macro at end of line:
#   η_boiler = 0.92;  @Cite "beiron2021"
#
# Standalone (e.g. at top of a block, returns the CitationRecord):
#   ref = @Cite "beiron2021"
#
# SECONDARY: comment-based annotations for static analysis (see scanner.jl):
#   η_boiler = 0.92   # @Cite beiron2021
#
# ALSO: standalone macro (e.g. at top of a block):
#   @Cite "beiron2021"

"""
    @Cite key [expression]

Record a bibliographic citation at runtime.

**Primary usage** — semicolon at end of line keeps natural reading order:
```julia
η_boiler = 0.92;  @Cite "beiron2021"
```

**Standalone** — returns the `CitationRecord`, useful for inspection:
```julia
ref = @Cite "beiron2021"
ref.key   # "beiron2021"
```

**With expression** — wraps and returns the value, records the citation:
```julia
@Cite "beiron2021" η_boiler = 0.92   # prefix style (less preferred)
```

Keys can be string literals or bare identifiers: `@Cite "key"` or `@Cite key`.
"""
macro Cite(key)
    file = string(__source__.file)
    line = __source__.line
    key_val = key isa Symbol ? string(key) : key
    quote
        Bibliography._record_citation($(esc(key_val)), $file, $line, "", nothing, :cite)
    end
end

macro Cite(key, expr)
    file = string(__source__.file)
    line = __source__.line
    code_str = string(expr)
    var_sym = _extract_variable(expr)
    key_val = key isa Symbol ? string(key) : key
    quote
        Bibliography._record_citation($(esc(key_val)), $file, $line, $code_str, $(QuoteNode(var_sym)), :cite)
        $(esc(expr))
    end
end

"""
    @Source key [expression]

Like `@Cite`, but tagged as `:source` — use for general (non-academic) references.
"""
macro Source(key)
    file = string(__source__.file)
    line = __source__.line
    key_val = key isa Symbol ? string(key) : key
    quote
        Bibliography._record_citation($(esc(key_val)), $file, $line, "", nothing, :source)
    end
end

macro Source(key, expr)
    file = string(__source__.file)
    line = __source__.line
    code_str = string(expr)
    var_sym = _extract_variable(expr)
    key_val = key isa Symbol ? string(key) : key
    quote
        Bibliography._record_citation($(esc(key_val)), $file, $line, $code_str, $(QuoteNode(var_sym)), :source)
        $(esc(expr))
    end
end

"""
    @DataSource key [expression]

Like `@Cite`, but tagged as `:datasource` — for data provenance references.

```julia
population_eu = 447_700_000;  @DataSource "eurostat2023"
```
"""
macro DataSource(key)
    file = string(__source__.file)
    line = __source__.line
    key_val = key isa Symbol ? string(key) : key
    quote
        Bibliography._record_citation($(esc(key_val)), $file, $line, "", nothing, :datasource)
    end
end

macro DataSource(key, expr)
    file = string(__source__.file)
    line = __source__.line
    code_str = string(expr)
    var_sym = _extract_variable(expr)
    key_val = key isa Symbol ? string(key) : key
    quote
        Bibliography._record_citation($(esc(key_val)), $file, $line, $code_str, $(QuoteNode(var_sym)), :datasource)
        $(esc(expr))
    end
end

# ── Convenience functions ─────────────────────────────────────────────────────

"""
    cite(key, value) -> value

Functional alternative to the `@Cite` macro. Records the citation and returns
the value unchanged. Useful when you want to wrap a value inline:

```julia
η_boiler = cite("beiron2021", 0.92)
```

For end-of-line style, prefer the semicolon macro: `η_boiler = 0.92; @Cite "beiron2021"`
"""
function cite(key::AbstractString, value)
    # Use a generic caller location (not available from a function)
    _record_citation(key, "", 0, "", nothing, :cite)
    value
end

"""
    cite(key) -> CitationRecord

Record a standalone citation and return the record.
"""
function cite(key::AbstractString)
    _record_citation(key, "", 0, "", nothing, :cite)
end

"""
    lookup(key::AbstractString) -> Union{Citation, Nothing}

Look up a citation key in the loaded reference library.
Returns `nothing` if not found.

```julia
ref = lookup("beiron2021")
ref.author   # "Beiron, Johanna and ..."
ref.year     # "2021"
```
"""
function lookup(key::AbstractString)
    get(_LIBRARY.entries, key, nothing)
end

# ── Querying ──────────────────────────────────────────────────────────────────

"""
    citations()

Return a copy of all `CitationRecord`s collected so far.
"""
citations() = copy(_RECORDS)

"""
    citations(key::AbstractString)

Return all records for a specific citation key.
"""
citations(key::AbstractString) = filter(r -> r.key == key, _RECORDS)

"""
    used_keys()

Return the unique citation keys that have been used in code, in order of first appearance.
"""
function used_keys()
    seen = Set{String}()
    keys = String[]
    for r in _RECORDS
        if r.key ∉ seen
            push!(seen, r.key)
            push!(keys, r.key)
        end
    end
    keys
end

"""
    used_references()

Return `Citation` objects from the library for all cited keys.
Keys not present in the library are skipped.
"""
function used_references()
    [_LIBRARY.entries[k] for k in used_keys() if haskey(_LIBRARY.entries, k)]
end

"""
    clear_citations!()

Clear all recorded citation annotations (keeps the library loaded).
"""
function clear_citations!()
    empty!(_RECORDS)
    nothing
end

# ── Reporting ─────────────────────────────────────────────────────────────────

"""
    citation_report(; io::IO=stdout)

Print a formatted report of all citations used in code, grouped by key.
Shows the full bibliographic entry (if loaded) and every location where it
was cited along with the annotated code.
"""
function citation_report(; io::IO=stdout)
    if isempty(_RECORDS)
        println(io, "No citations recorded.")
        return
    end

    # Group records by key, preserving first-seen order
    by_key = Dict{String,Vector{CitationRecord}}()
    key_order = String[]
    for r in _RECORDS
        if !haskey(by_key, r.key)
            by_key[r.key] = CitationRecord[]
            push!(key_order, r.key)
        end
        push!(by_key[r.key], r)
    end

    println(io, "Bibliography Citation Report")
    println(io, "═" ^ 50)

    for key in key_order
        records = by_key[key]
        println(io)

        # Header: full reference if in library, otherwise just the key
        entry = get(_LIBRARY.entries, key, nothing)
        if entry !== nothing
            author = get(entry.fields, "author", "Unknown")
            title  = get(entry.fields, "title", "Untitled")
            year   = get(entry.fields, "year", "n.d.")
            println(io, "[$key]  $author, \"$title\", $year")
        else
            println(io, "[$key]  (not in reference library)")
        end

        # Each usage location
        for r in records
            tag  = r.kind == :cite ? "" : " [$(r.kind)]"
            loc  = isempty(r.file) ? "  REPL" : "  $(basename(r.file)):$(r.line)"
            vstr = r.variable !== nothing ? " → $(r.variable)" : ""
            code = isempty(r.code) ? "" : "  │ $(r.code)"
            println(io, "$loc$tag$vstr$code")
        end
    end
    println(io)
end

"""
    export_bibliography(filename::String)

Write only the cited references to a `.bib` file.
Returns the number of entries written.
"""
function export_bibliography(filename::String)
    refs = used_references()
    open(filename, "w") do io
        write(io, to_bibtex(refs))
    end
    length(refs)
end
