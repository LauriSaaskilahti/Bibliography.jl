# ── Comment-based citation scanner ────────────────────────────────────────────
#
# The primary way to annotate code: put structured tags in end-of-line comments.
#
#   η_boiler = 0.92   # @Cite beiron2021
#   pop = 4.5e8       # @DataSource eurostat2023
#   x = f(y)          # @Source internal_report_2024
#
# Supported comment formats:
#   # @Cite key
#   # @Cite("key")
#   # @Cite "key"
#   # multiple tags:  @Cite key1  @DataSource key2

# Regex that matches @Cite, @Source, or @DataSource followed by a key.
# Key can be: bare identifier, "quoted", or ("quoted")
const _ANNOTATION_RE = r"@(Cite|Source|DataSource)\s*\(?[\"']?(\w+)[\"']?\)?"

"""
    _extract_variable_from_code(code::AbstractString)

Extract the variable name being assigned on a line of Julia code.
Returns the name as a `Symbol`, or `nothing`.
"""
function _extract_variable_from_code(code::AbstractString)
    # Match simple assignment: `var = ...` or `var::Type = ...`
    m = match(r"^\s*(\w+)\s*(?:::[^=]+)?\s*=(?!=)", code)
    m === nothing ? nothing : Symbol(m.captures[1])
end

"""
    scan_citations(files::String...; warn_unknown=true) -> Vector{CitationRecord}

Scan Julia source files for citation annotations in comments.
Recognizes `# @Cite key`, `# @Source key`, and `# @DataSource key` patterns
at the end of lines (or on comment-only lines).

Records are added to the global registry (same as macro-based annotations)
and also returned.

```julia
scan_citations("src/model.jl", "src/data.jl")
scan_citations("src")  # scans all .jl files recursively
```
"""
function scan_citations(files::String...; warn_unknown::Bool=true)
    new_records = CitationRecord[]
    for path in files
        _scan_path!(new_records, path, warn_unknown)
    end
    append!(_RECORDS, new_records)
    new_records
end

function _scan_path!(records, path, warn_unknown)
    if isdir(path)
        for (root, dirs, files) in walkdir(path)
            for f in files
                endswith(f, ".jl") || continue
                _scan_file!(records, joinpath(root, f), warn_unknown)
            end
        end
    elseif isfile(path)
        _scan_file!(records, path, warn_unknown)
    else
        @warn "Path not found: $path"
    end
end

function _scan_file!(records, filepath, warn_unknown)
    lines = readlines(filepath)
    for (lineno, line) in enumerate(lines)
        # Find the comment portion of the line
        comment_start = _find_comment_start(line)
        comment_start === nothing && continue

        comment = line[comment_start:end]

        # Check for annotation patterns in the comment
        for m in eachmatch(_ANNOTATION_RE, comment)
            kind_str = lowercase(m.captures[1])
            key = String(m.captures[2])
            kind = kind_str == "cite" ? :cite :
                   kind_str == "source" ? :source : :datasource

            # Extract the code portion (everything before the comment)
            code = strip(line[1:comment_start-1])
            var = _extract_variable_from_code(code)

            record = CitationRecord(key, abspath(filepath), lineno,
                                    String(code), var, kind)
            push!(records, record)

            if warn_unknown && !isempty(_LIBRARY.entries) && !haskey(_LIBRARY.entries, key)
                @warn "Citation key '$key' not found in reference library" file=filepath line=lineno
            end
        end
    end
end

"""
Find the start index of a `#` line comment, ignoring `#` inside strings.
Returns `nothing` if there is no comment on this line.
"""
function _find_comment_start(line::AbstractString)
    in_string = false
    escape_next = false
    for (i, ch) in enumerate(line)
        if escape_next
            escape_next = false
            continue
        end
        if ch == '\\'
            escape_next = true
            continue
        end
        if ch == '"'
            in_string = !in_string
            continue
        end
        if !in_string && ch == '#'
            # Check it's not #= block comment (we skip those for simplicity)
            if i < length(line) && line[i+1] == '='
                continue
            end
            return i
        end
    end
    nothing
end
