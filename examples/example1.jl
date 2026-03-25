using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using Bibliography

# ── Load the reference library ────────────────────────────────────────────────
bibfile = joinpath(@__DIR__, "references.bib")
load_bibliography!(bibfile)
println("Loaded library: ", bibliography())

# ═══════════════════════════════════════════════════════════════════════════════
# ANNOTATED CODE — citations go at the end of the line, after a semicolon.
# The code reads naturally: computation first, reference second.
# ═══════════════════════════════════════════════════════════════════════════════

E = 9e16;                               @Cite "einstein1905"
η_boiler = 0.92;                        @Cite "beiron2021"
p = E / 3e8;                            @Cite "einstein1905"
population_eu = 447_700_000;            @DataSource "eurostat2023"
algorithm = "Knuth shuffle";            @Source "knuth1984"

# Standalone — returns a CitationRecord you can inspect:
ref = @Cite "beiron2021"
println("Captured record: ", ref)

# Functional style — cite(key, value) returns the value unchanged:
correction_factor = cite("beiron2021", 1.02)

# Look up full bibliographic details from the library:
entry = lookup("beiron2021")
println("Author: ", entry.author)
println("Year:   ", entry.year)

# Comment-based annotations also work (picked up by scan_citations):
# gravity = 9.81  # @Cite einstein1905

# ═══════════════════════════════════════════════════════════════════════════════
# SCANNING — optionally scan for comment-based annotations too
# ═══════════════════════════════════════════════════════════════════════════════

scan_citations(@__FILE__)

# ── Inspect what was cited ────────────────────────────────────────────────────
println("\n--- All citation records ---")
for r in citations()
    println("  ", r)
end

println("\n--- Used keys ---")
println("  ", used_keys())

# ── Full report ──────────────────────────────────────────────────────────────
println()
citation_report()

# ── Export only the cited references to a new .bib file ──────────────────────
outfile = joinpath(@__DIR__, "used_references.bib")
n = export_bibliography(outfile)
println("Exported $n cited references to $outfile")