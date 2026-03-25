using Bibliography

# Example: Parse a BibTeX entry
entry = """
@article{einstein1905,
  author = {Albert Einstein},
  title = {On the Electrodynamics of Moving Bodies},
  journal = {Annalen der Physik},
  year = {1905},
  volume = {17},
  pages = {891--921}
}
"""

citation = parse_bibtex_entry(entry)
println(citation)
println("Author: ", citation.author)
println("Title: ", citation.title)

# Convert back to BibTeX
println("\nReconstructed BibTeX:")
println(to_bibtex(citation))