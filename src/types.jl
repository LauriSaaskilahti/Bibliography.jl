"""
    Citation(bibtype::Symbol, key::String, fields::Dict{String,String})

A bibliographic entry from a BibTeX file.

# Fields
- `bibtype`: Entry type (`:article`, `:book`, etc.)
- `key`: Citation key (e.g. `"einstein1905"`)
- `fields`: BibTeX fields (author, title, year, etc.)
"""
struct Citation
    bibtype::Symbol
    key::String
    fields::Dict{String,String}

    function Citation(bibtype::Symbol, key::AbstractString, fields::Dict{String,String})
        valid_types = [:article, :book, :booklet, :conference, :inbook,
                      :incollection, :inproceedings, :manual, :mastersthesis,
                      :misc, :phdthesis, :proceedings, :techreport, :unpublished]
        if !(bibtype in valid_types)
            error("Invalid BibTeX type: $bibtype. Valid types are: $valid_types")
        end
        new(bibtype, String(key), fields)
    end
end

function Base.show(io::IO, c::Citation)
    print(io, "Citation(@$(c.bibtype){$(c.key)}, $(length(c.fields)) fields)")
end

function Base.getproperty(c::Citation, field::Symbol)
    if field in (:bibtype, :key, :fields)
        return getfield(c, field)
    end
    s = lowercase(string(field))
    haskey(c.fields, s) && return c.fields[s]
    error("Citation '$(c.key)' has no field '$field'")
end

"""
    CitationRecord

A record of a citation annotation made in source code via `@Cite` or similar macros.

# Fields
- `key`: BibTeX citation key
- `file`: Source file where the annotation appears
- `line`: Line number
- `code`: The annotated expression as a string
- `variable`: Variable being assigned on this line, or `nothing`
- `kind`: Annotation type (`:cite`, `:source`, `:datasource`)
"""
struct CitationRecord
    key::String
    file::String
    line::Int
    code::String
    variable::Union{Symbol,Nothing}
    kind::Symbol
end

function Base.show(io::IO, r::CitationRecord)
    loc = isempty(r.file) ? "REPL" : "$(basename(r.file)):$(r.line)"
    var_str = r.variable !== nothing ? " → $(r.variable)" : ""
    print(io, "CitationRecord($(r.key) at $loc$var_str)")
end

"""
    ReferenceLibrary

A collection of BibTeX entries loaded from `.bib` files. Serves as the
reference database against which `@Cite` keys are validated.
"""
mutable struct ReferenceLibrary
    entries::Dict{String,Citation}
    source_files::Vector{String}
end

ReferenceLibrary() = ReferenceLibrary(Dict{String,Citation}(), String[])

function Base.show(io::IO, lib::ReferenceLibrary)
    n = length(lib.entries)
    f = length(lib.source_files)
    print(io, "ReferenceLibrary($n entries from $f files)")
end
