module Bibliography

# ── Types ─────────────────────────────────────────────────────────────────────
export Citation, CitationRecord, ReferenceLibrary

# ── BibTeX I/O ────────────────────────────────────────────────────────────────
export parse_bibtex_entry, read_references, to_bibtex

# ── Library management ────────────────────────────────────────────────────────
export load_bibliography!, bibliography, clear_bibliography!

# ── Annotation macros & functions ──────────────────────────────────────────────
export @Cite, @Source, @DataSource
export cite, lookup

# ── Comment-based scanner ─────────────────────────────────────────────────────
export scan_citations

# ── Querying & reporting ──────────────────────────────────────────────────────
export citations, used_keys, used_references, clear_citations!
export citation_report, export_bibliography

include("types.jl")
include("parser.jl")
include("annotations.jl")
include("scanner.jl")

end # module