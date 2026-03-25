using Test
using Bibliography

@testset "Bibliography.jl" begin

    # ── Parser tests ──────────────────────────────────────────────────────────

    @testset "parse_bibtex_entry" begin
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
        c = parse_bibtex_entry(entry)
        @test c.bibtype == :article
        @test c.key == "einstein1905"
        @test c.author == "Albert Einstein"
        @test c.title == "On the Electrodynamics of Moving Bodies"
        @test c.year == "1905"
    end

    @testset "to_bibtex roundtrip" begin
        entry = """
        @book{knuth1984,
          author = {Donald E. Knuth},
          title = {The TeXbook},
          publisher = {Addison-Wesley},
          year = {1984}
        }
        """
        c = parse_bibtex_entry(entry)
        bibtex_str = to_bibtex(c)
        @test occursin("@book{knuth1984", bibtex_str)
        @test occursin("Donald E. Knuth", bibtex_str)
    end

    @testset "invalid bibtype" begin
        entry = """
        @foobar{test2020,
          author = {Test Author},
          title = {Test Title}
        }
        """
        @test_throws ErrorException parse_bibtex_entry(entry)
    end

    @testset "Citation show and properties" begin
        c = Citation(:article, "test2020", Dict("author" => "Test", "title" => "Title"))
        @test occursin("test2020", sprint(show, c))
        @test c.author == "Test"
        @test_throws ErrorException c.journal  # missing field
    end

    @testset "to_bibtex vector" begin
        c1 = Citation(:article, "a1", Dict("author" => "A"))
        c2 = Citation(:book, "b1", Dict("author" => "B"))
        result = to_bibtex([c1, c2])
        @test occursin("@article{a1", result)
        @test occursin("@book{b1", result)
    end

    # ── Annotation macro tests ────────────────────────────────────────────────

    @testset "@Cite macro" begin
        clear_bibliography!()  # start clean

        # @Cite with expression — should return the value
        val = @Cite "testkey" 2 + 3
        @test val == 5

        # @Cite standalone
        @Cite "standalone_key"

        recs = citations()
        @test length(recs) == 2
        @test recs[1].key == "testkey"
        @test recs[1].kind == :cite
        @test recs[1].code == "2 + 3"
        @test recs[2].key == "standalone_key"
    end

    @testset "@Cite captures variable" begin
        clear_bibliography!()
        @Cite "someref" x_test = 42
        @test x_test == 42
        recs = citations()
        @test recs[1].variable == :x_test
    end

    @testset "@Cite with bare identifier key" begin
        clear_bibliography!()
        @Cite mykey 1 + 1
        @test citations()[1].key == "mykey"
    end

    @testset "@Source macro" begin
        clear_bibliography!()
        v = @Source "src1" 10
        @test v == 10
        @test citations()[1].kind == :source
    end

    @testset "@DataSource macro" begin
        clear_bibliography!()
        @DataSource "ds1" data = [1, 2, 3]
        @test data == [1, 2, 3]
        @test citations()[1].kind == :datasource
        @test citations()[1].variable == :data
    end

    # ── Library & reporting tests ─────────────────────────────────────────────

    @testset "load_bibliography! and querying" begin
        clear_bibliography!()

        # Write a temp bib file
        tmpfile = tempname() * ".bib"
        open(tmpfile, "w") do io
            write(io, """
            @article{ref_a,
              author = {Alice},
              title = {Paper A},
              year = {2020}
            }

            @book{ref_b,
              author = {Bob},
              title = {Book B},
              year = {2021}
            }
            """)
        end

        n = load_bibliography!(tmpfile)
        @test n == 2
        lib = bibliography()
        @test haskey(lib.entries, "ref_a")
        @test haskey(lib.entries, "ref_b")

        # Cite one of them
        @Cite "ref_a" y_test = 99
        @test y_test == 99

        @test used_keys() == ["ref_a"]
        refs = used_references()
        @test length(refs) == 1
        @test refs[1].key == "ref_a"

        # citation_report should produce output
        buf = IOBuffer()
        citation_report(io=buf)
        report = String(take!(buf))
        @test occursin("ref_a", report)
        @test occursin("Alice", report)

        rm(tmpfile)
    end

    @testset "export_bibliography" begin
        clear_bibliography!()

        tmpbib = tempname() * ".bib"
        open(tmpbib, "w") do io
            write(io, """
            @article{exp_a,
              author = {Author A},
              title = {Title A},
              year = {2020}
            }
            @article{exp_b,
              author = {Author B},
              title = {Title B},
              year = {2021}
            }
            """)
        end

        load_bibliography!(tmpbib)

        @Cite "exp_a" z_test = 1
        # exp_b is NOT cited

        outfile = tempname() * ".bib"
        n = export_bibliography(outfile)
        @test n == 1

        exported = read(outfile, String)
        @test occursin("exp_a", exported)
        @test !occursin("exp_b", exported)

        rm(tmpbib)
        rm(outfile)
    end

    @testset "clear functions" begin
        clear_bibliography!()
        @test isempty(citations())
        @test isempty(bibliography().entries)

        @Cite "x" 1
        @test length(citations()) == 1
        clear_citations!()
        @test isempty(citations())
    end

    @testset "@Cite standalone returns CitationRecord" begin
        clear_bibliography!()
        rec = @Cite "returntest"
        @test rec isa CitationRecord
        @test rec.key == "returntest"
        @test rec.kind == :cite
    end

    @testset "cite() function with value" begin
        clear_bibliography!()
        val = cite("funckey", 3.14)
        @test val == 3.14
        @test length(citations()) == 1
        @test citations()[1].key == "funckey"
    end

    @testset "cite() function standalone" begin
        clear_bibliography!()
        rec = cite("standalone_func")
        @test rec isa CitationRecord
        @test rec.key == "standalone_func"
    end

    @testset "lookup()" begin
        clear_bibliography!()

        tmpbib = tempname() * ".bib"
        open(tmpbib, "w") do io
            write(io, """
            @article{lookup_test,
              author = {Lookup Author},
              title = {Lookup Title},
              year = {2025}
            }
            """)
        end
        load_bibliography!(tmpbib)

        entry = lookup("lookup_test")
        @test entry !== nothing
        @test entry.author == "Lookup Author"
        @test entry.year == "2025"

        @test lookup("nonexistent") === nothing

        rm(tmpbib)
    end

    @testset "semicolon end-of-line style" begin
        clear_bibliography!()
        # This is the primary usage pattern
        x_semi = 42;  @Cite "semicolon_test"
        @test x_semi == 42
        @test length(citations()) == 1
        @test citations()[1].key == "semicolon_test"
    end

    # ── Comment-based scanner tests ───────────────────────────────────────────

    @testset "scan_citations basic" begin
        clear_bibliography!()

        tmpfile = tempname() * ".jl"
        open(tmpfile, "w") do io
            write(io, """
            x = 42             # @Cite einstein1905
            y = 3.14           # @DataSource eurostat2023
            z = "hello"        # @Source knuth1984
            normal_line = 1    # just a regular comment
            """)
        end

        recs = scan_citations(tmpfile; warn_unknown=false)
        @test length(recs) == 3

        @test recs[1].key == "einstein1905"
        @test recs[1].kind == :cite
        @test recs[1].variable == :x
        @test occursin("x = 42", recs[1].code)

        @test recs[2].key == "eurostat2023"
        @test recs[2].kind == :datasource
        @test recs[2].variable == :y

        @test recs[3].key == "knuth1984"
        @test recs[3].kind == :source
        @test recs[3].variable == :z

        # Records are also in the global registry
        @test length(citations()) == 3

        rm(tmpfile)
    end

    @testset "scan_citations quoted key formats" begin
        clear_bibliography!()

        tmpfile = tempname() * ".jl"
        open(tmpfile, "w") do io
            write(io, """
            a = 1  # @Cite("quoted_key")
            b = 2  # @Cite "also_quoted"
            c = 3  # @Cite bare_key
            """)
        end

        recs = scan_citations(tmpfile; warn_unknown=false)
        @test length(recs) == 3
        @test recs[1].key == "quoted_key"
        @test recs[2].key == "also_quoted"
        @test recs[3].key == "bare_key"

        rm(tmpfile)
    end

    @testset "scan_citations multiple tags per line" begin
        clear_bibliography!()

        tmpfile = tempname() * ".jl"
        open(tmpfile, "w") do io
            write(io, """
            val = 1.02  # @Cite ref_a  @DataSource ref_b
            """)
        end

        recs = scan_citations(tmpfile; warn_unknown=false)
        @test length(recs) == 2
        @test recs[1].key == "ref_a"
        @test recs[1].kind == :cite
        @test recs[2].key == "ref_b"
        @test recs[2].kind == :datasource

        rm(tmpfile)
    end

    @testset "scan_citations ignores # in strings" begin
        clear_bibliography!()

        tmpfile = tempname() * ".jl"
        open(tmpfile, "w") do io
            # The # inside the string should not be treated as a comment
            write(io, """
            s = "no # comment here"  # @Cite realcite
            """)
        end

        recs = scan_citations(tmpfile; warn_unknown=false)
        @test length(recs) == 1
        @test recs[1].key == "realcite"

        rm(tmpfile)
    end

    @testset "scan_citations directory" begin
        clear_bibliography!()

        tmpdir = mktempdir()
        open(joinpath(tmpdir, "a.jl"), "w") do io
            write(io, "x = 1  # @Cite key_a\n")
        end
        open(joinpath(tmpdir, "b.jl"), "w") do io
            write(io, "y = 2  # @Cite key_b\n")
        end
        # non-.jl file should be ignored
        open(joinpath(tmpdir, "notes.txt"), "w") do io
            write(io, "z = 3  # @Cite key_c\n")
        end

        recs = scan_citations(tmpdir; warn_unknown=false)
        @test length(recs) == 2
        keys = [r.key for r in recs]
        @test "key_a" in keys
        @test "key_b" in keys

        rm(tmpdir; recursive=true)
    end

    @testset "scan + library integration" begin
        clear_bibliography!()

        # Set up library
        tmpbib = tempname() * ".bib"
        open(tmpbib, "w") do io
            write(io, """
            @article{lib_ref,
              author = {Author},
              title = {Title},
              year = {2020}
            }
            """)
        end
        load_bibliography!(tmpbib)

        # Set up source file
        tmpjl = tempname() * ".jl"
        open(tmpjl, "w") do io
            write(io, "val = 99  # @Cite lib_ref\n")
        end

        scan_citations(tmpjl)

        @test used_keys() == ["lib_ref"]
        refs = used_references()
        @test length(refs) == 1
        @test refs[1].author == "Author"

        buf = IOBuffer()
        citation_report(io=buf)
        report = String(take!(buf))
        @test occursin("lib_ref", report)
        @test occursin("Author", report)

        rm(tmpbib)
        rm(tmpjl)
    end

end
