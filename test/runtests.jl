using Test
using Bibliography

@testset "Bibliography.jl" begin
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
        @test c.journal == "Annalen der Physik"
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

    @testset "Citation show" begin
        c = Citation(:article, "test2020", Dict("author" => "Test", "title" => "Title"))
        buf = IOBuffer()
        show(buf, c)
        @test occursin("Citation(@article{test2020}", String(take!(buf)))
    end

    @testset "to_bibtex vector" begin
        c1 = Citation(:article, "a1", Dict("author" => "A", "title" => "T1"))
        c2 = Citation(:book, "b1", Dict("author" => "B", "title" => "T2"))
        result = to_bibtex([c1, c2])
        @test occursin("@article{a1", result)
        @test occursin("@book{b1", result)
    end

    @testset "getproperty missing field" begin
        c = Citation(:article, "test", Dict("author" => "A"))
        @test_throws ErrorException c.title
    end
end
