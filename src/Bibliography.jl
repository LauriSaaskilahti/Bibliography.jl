module Bibliography

export Citation, read_references, to_bibtex, parse_bibtex_entry

"""Citation(bibtype::Symbol, key::String, fields::Dict{String,String})
A structure representing a bibliographic citation in BibTeX format.
"""
struct Citation
    bibtype::Symbol       # The type of citation (book, article, etc.)
    key::AbstractString           # The citation key
    fields::Dict{String,String}  # All fields from the BibTeX entry
    
    function Citation(bibtype::Symbol, key::AbstractString, fields::Dict{String,String})
        # Validate the bibtype
        valid_types = [:article, :book, :booklet, :conference, :inbook, 
                      :incollection, :inproceedings, :manual, :mastersthesis,
                      :misc, :phdthesis, :proceedings, :techreport, :unpublished]
        
        if !(bibtype in valid_types)
            error("Invalid BibTeX type: $bibtype. Valid types are: $valid_types")
        end
        
        new(bibtype, key, fields)
    end
end


"""parse_bibtex_entry(entry::String) -> Citation
Parse a single BibTeX entry string into a Citation object.
"""
function parse_bibtex_entry(entry::String)
    # Remove comments and whitespace
    entry = replace(entry, r"%.*?\n" => "")  # Remove comments
    entry = strip(entry)
    
    # Match the BibTeX entry pattern with DOTALL flag
    m = match(r"@(\w+)\s*\{\s*([^,\s]+)\s*,\s*(.*)\}"s, entry)
    if m === nothing
        error("Invalid BibTeX entry format: $(entry[1:min(50, end)])...")
    end
    
    bibtype = Symbol(lowercase(m.captures[1]))
    key = strip(m.captures[2])
    fields_str = strip(m.captures[3])
    
    # Parse fields with more flexible pattern
    fields = Dict{String,String}()

    for m in eachmatch(r"(\w+)\s*=\s*\{(.*?)\}\s*,"s, entry)
        field_name = lowercase(strip(m.captures[1]))
        field_value = strip(m.captures[2])
        if startswith(field_value, '{') && endswith(field_value, '}')
            field_value = field_value[2:prevind(field_value, end)]
        end
        field_value = replace(field_value, r"\s+" => " ")
        field_value = strip(field_value)
        fields[field_name] = field_value
    end
    matches = collect(eachmatch(r"(\w+)\s*=\s*\{(.*?)\}", entry))
    last_match = last(matches)
    field_name = lowercase(strip(last_match.captures[1]))
    field_value = strip(last_match.captures[2])
    field_value = replace(field_value, r"\s+" => " ")
    field_value = strip(field_value)
    fields[field_name] = field_value

    Citation(bibtype, key, fields)
end


"""read_references(filename::String) -> Vector{Citation}
Read BibTeX references from a file and return a vector of Citation objects.
"""
function read_references(filename::String)
    text = read(filename, String)
    
    # Remove comments
    text = replace(text, r"%.*?\n" => "")
    
    # Find all entries using lookahead for the next @
    entries = split(text, r"(?=@\w+\s*\{)")
    filter!(x -> !isempty(strip(x)), entries)
    
    citations = Citation[]
    for entry in entries
        try
            # Skip if doesn't start with @
            startswith(entry, '@') || continue
            
            # Convert SubString to String and remove whitespace
            entry_str = string(strip(entry))
            
            # Parse the entry
            push!(citations, parse_bibtex_entry(entry_str))
        catch e
            @warn "Skipping malformed entry: $e\nEntry: $(entry[1:min(50, end)])..."
        end
    end
    
    citations
end



"""to_bibtex(citation::Citation) -> String
Convert a Citation object back to a valid BibTeX string.
"""
function to_bibtex(citation::Citation)
    fields = ["  $key = {$value}" for (key, value) in citation.fields]
    fields_str = join(fields, ",\n")
    
    """
    @$(citation.bibtype){$(citation.key),
    $(fields_str)
    }
    """
end

"""to_bibtex(citations::Vector{Citation}) -> String
Convert multiple Citation objects to a valid BibTeX string.
"""
function to_bibtex(citations::Vector{Citation})
    join([to_bibtex(c) for c in citations], "\n")
end

# Additional convenience functions
function Base.show(io::IO, citation::Citation)
    print(io, "Citation(@$(citation.bibtype){$(citation.key)}, with $(length(citation.fields)) fields)")
end

function Base.getproperty(citation::Citation, field::Symbol)
    if field in [:bibtype, :key, :fields]
        return getfield(citation, field)
    else
        field_str = lowercase(string(field))
        if haskey(citation.fields, field_str)
            return citation.fields[field_str]
        else
            error("Citation has no field $field")
        end
    end
end

end # module