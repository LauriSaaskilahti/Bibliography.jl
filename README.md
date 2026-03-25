# Bibliography.jl

Inline academic citations for Julia code. Tag your code with `@Cite` to link
computations directly to their source references — making the provenance of
constants, models, and design choices explicit and machine-readable.

## Why?

Scientific and engineering code is full of "magic numbers" and modelling choices
that originate from papers, datasets, or technical reports. Comments help, but
they are unstructured and easy to lose. Bibliography.jl gives you:

1. **Inline citation macros** (`@Cite`, `@Source`, `@DataSource`) that annotate
   code without affecting execution.
2. **Automatic tracking** of every citation: which file, which line, which
   variable was assigned, and what the code expression was.
3. **A reference library** loaded from standard `.bib` files, so cited keys
   can be validated and full bibliographic details are available.
4. **Reporting & export** — generate a citation report or export only the
   references actually used in your code to a new `.bib` file.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/LauriSaaskilahti/Bibliography.jl")
```

## Quick start

```julia
using Bibliography

# Load your BibTeX reference library (optional but recommended)
load_bibliography!("references.bib")

# Annotate code with citations — execution is unaffected
@Cite "beiron2021"   η_boiler = 0.92
@Cite "einstein1905" E = m * c^2
@DataSource "eurostat2023" population = 447_700_000

# See what was cited and where
citation_report()

# Export only the actually-used references
export_bibliography("used_references.bib")
```

## Macro reference

### `@Cite key [expression]`

Annotate an expression with an academic citation. The expression executes
normally; the citation is silently recorded.

```julia
@Cite "smith2020" x = 2/3 * x_0   # string key
@Cite smith2020   x = 2/3 * x_0   # bare identifier key (simple names only)
@Cite "smith2020"                  # standalone marker (no expression)
```

### `@Source key [expression]`

Alias for `@Cite`. Use to tag general (non-academic) references.

### `@DataSource key [expression]`

Tag code with a data-provenance reference — where a value or dataset comes from.

```julia
@DataSource "eurostat2023" population_eu = 447_700_000
```

## Library management

| Function | Description |
|---|---|
| `load_bibliography!(files...)` | Load `.bib` files into the global library |
| `bibliography()` | Return the current `ReferenceLibrary` |
| `clear_bibliography!()` | Clear library and all records |

## Querying & reporting

| Function | Description |
|---|---|
| `citations()` | All `CitationRecord`s collected so far |
| `citations(key)` | Records for a specific key |
| `used_keys()` | Unique cited keys in order of first use |
| `used_references()` | `Citation` objects from the library for cited keys |
| `citation_report(; io=stdout)` | Print a formatted citation report |
| `export_bibliography(file)` | Write cited references to a `.bib` file |
| `clear_citations!()` | Clear records (keep library loaded) |

## BibTeX parsing (low-level)

| Function | Description |
|---|---|
| `parse_bibtex_entry(str)` | Parse a single BibTeX entry string |
| `read_references(file)` | Read all entries from a `.bib` file |
| `to_bibtex(citation)` | Convert back to BibTeX string |

## Example output

```
Bibliography Citation Report
══════════════════════════════════════════════════════

[beiron2021]  Beiron et al., "Dynamic modeling for...", 2021
  model.jl:14 → η_boiler  │ η_boiler = 0.92

[einstein1905]  Albert Einstein, "On the Electrodynamics...", 1905
  physics.jl:7 → E  │ E = m * c ^ 2

[eurostat2023]  Eurostat, "Population on 1 January", 2023
  data.jl:3 [datasource] → population  │ population = 447_700_000
```

## Roadmap / ideas

- **`@Explanation`** / **`@Comment`** macros for non-citation annotations with
  author tracking and timestamps (code discussion threads).
- **Static analysis mode** — scan `.jl` files for `@Cite` usage without
  executing, for CI or documentation pipelines.
- **Documenter.jl integration** — auto-generate a bibliography section in docs.
- **DOI / CrossRef lookup** — resolve keys to full metadata online.
- **Per-variable provenance graph** — trace which citations influenced which
  outputs through the computation.

## License

MIT