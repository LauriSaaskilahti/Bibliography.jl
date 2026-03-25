# ── BibTeX parsing and serialization ──────────────────────────────────────────

"""
    parse_bibtex_entry(entry::String) -> Citation

Parse a single BibTeX entry string into a `Citation`.
"""
function parse_bibtex_entry(entry::String)
    entry = replace(entry, r"%.*?\n" => "")  # strip comments
    entry = strip(entry)

    m = match(r"@(\w+)\s*\{\s*([^,\s]+)\s*,\s*(.*)\}"s, entry)
    if m === nothing
        error("Invalid BibTeX entry format: $(first(entry, 50))...")
    end

    bibtype = Symbol(lowercase(m.captures[1]))
    key = strip(m.captures[2])

    fields = Dict{String,String}()

    # Match all field = {value} pairs followed by a comma
    for fm in eachmatch(r"(\w+)\s*=\s*\{(.*?)\}\s*,"s, entry)
        name  = lowercase(strip(fm.captures[1]))
        value = strip(fm.captures[2])
        # Strip double braces: {{Title}} → Title
        if startswith(value, '{') && endswith(value, '}')
            value = value[2:prevind(value, end)]
        end
        value = replace(value, r"\s+" => " ")
        fields[name] = strip(value)
    end

    # The last field may not have a trailing comma
    all_matches = collect(eachmatch(r"(\w+)\s*=\s*\{(.*?)\}"s, entry))
    if !isempty(all_matches)
        last_m = last(all_matches)
        name  = lowercase(strip(last_m.captures[1]))
        value = replace(strip(last_m.captures[2]), r"\s+" => " ")
        fields[name] = strip(value)
    end

    Citation(bibtype, key, fields)
end

"""
    read_references(filename::String) -> Vector{Citation}

Read all BibTeX entries from a `.bib` file.
"""
function read_references(filename::String)
    text = read(filename, String)
    text = replace(text, r"%.*?\n" => "")

    entries = split(text, r"(?=@\w+\s*\{)")
    filter!(x -> !isempty(strip(x)), entries)

    citations = Citation[]
    for entry in entries
        startswith(strip(entry), '@') || continue
        try
            push!(citations, parse_bibtex_entry(String(strip(entry))))
        catch e
            @warn "Skipping malformed entry" exception = e
        end
    end
    citations
end

"""
    to_bibtex(citation::Citation) -> String

Convert a `Citation` back to a BibTeX string.
"""
function to_bibtex(citation::Citation)
    parts = ["  $k = {$v}" for (k, v) in citation.fields]
    "@$(citation.bibtype){$(citation.key),\n$(join(parts, ",\n"))\n}\n"
end

"""
    to_bibtex(citations::Vector{Citation}) -> String

Convert multiple `Citation` objects to a BibTeX string.
"""
function to_bibtex(citations::Vector{Citation})
    join(to_bibtex.(citations), "\n")
end
