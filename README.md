# Bibliopgraphy.jl 

Allows for writing source citations as inline code. E.g.:
fuel_price = 0.64 u"€"/u"kg"  @cite("MyAcademicPaper et al. 2015")

This serves two purposes:
1) Allows inline citations for anyone reading the code
2) Stores the citations for later model communication

This is a citation/note-taking/commenting tool only, and thus a simple add-on with zero runtime overhead (and infinitesimal compile time overhead). 
Besides citations we also have:
@datasource
@comment
@explanation
@source/reference (the generic construct)

This creates a new datastructure that stores the variable attached as key, and the reference as the value. The datastructure must be queried by separate function provided by the code module. 
New additions are added toi the datastructure, never overwritten. Addition date is also automatically recorded. Extra option of specifying who is authoring is allowed. This way this also works as commentary discussion section if wanted (though possibly a bit clumsy) similar to Word's comments. When model is exported, these are exported as well.
