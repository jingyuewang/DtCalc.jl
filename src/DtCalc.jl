module DtCalc

using Reexport
@reexport using DomTerm
@reexport using FixedPointNumbers
@reexport using Colors
@reexport using FileIO
@reexport using ImageShow
@reexport using ImageTransformations
@reexport using SVGDraw
@reexport using MathMLRepr
@reexport using Mxma

include("display.jl")
include("htmlio.jl")
include("utils.jl")

export
    # basics
    display, make_newline, make_div, make_img,
    # stream io
    hprint, hprintln,
    # utilities
    showIEEE754, ls_imginfo, preview_dir,
    # setings
    typeset_matrix
end
