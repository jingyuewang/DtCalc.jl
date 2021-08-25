import Base: display, redisplay

using DomTerm: DomTermInline
using Colors: Colorant
using MathMLRepr: LATEX
using Mxma: MExpr

#
#using DataFrames: DataFrame
#display(d::DomTermInline, x::DataFrame) = display(d, MIME("text/html"), x)
#
#using GR: SVG
#display(d::DomTermInline, x::SVG) = display(d, MIME("image/svg+xml"), x)

# Register single-argument function `display(x)` for all types that DomTerm
# supports.
display(d::DomTermInline, x::LATEX) = display(d, MIME("text/mathml+xml"), x)
display(d::DomTermInline, x::MExpr) = display(d, MIME("text/mathml+xml"), x)

typeset_matvec = false
function typeset_matrix(f::Bool)
    global typeset_matvec

    typeset_matvec = f
    return typeset_matvec
end

function display(d::DomTermInline, x::Vector{<:Number})
    if typeset_matvec
        display(d, MIME("text/mathml+xml"), x)
    else
        display(d, MIME("text/plain"), x)
    end
end
function display(d::DomTermInline, x::AbstractMatrix)
    if typeset_matvec
        display(d, MIME("text/mathml+xml"), x)
    else
        display(d, MIME("text/plain"), x)
    end
end

# in-memory Image objects
function display(d::DomTermInline, x::AbstractMatrix{<:Colorant})
    n = length(x)
    # use svg for small images, use png for large images
    if n < 4*1024
        display(d, MIME("image/svg+xml"), x)
    else
        display(d, MIME("image/png"), x)
    end
end
function display(d::DomTermInline, x::Vector{C}) where C<:Colorant
    n = length(x)
    r = Matrix{C}(undef, n, 1)
    for i = 1:n r[i,1] = x[i] end
    display(d, r)
end
function display(d::DomTermInline, x::C) where C<:Colorant
    r = Matrix{C}(undef, 1, 1)
    r[1,1] = x
    display(d, r)
end

const surfacetype_to_mime = Dict(
    :png => MIME("image/png"),
    :svg => MIME("image/svg+xml"),
    :jpg => MIME("image/jpeg"),
    :jpeg => MIME("image/jpeg")
    )

function displayinline(m::Module)
    if Symbol(m) === :Luxor
        @eval begin
            function display(d::DomTermInline, x::$m.Drawing)
                display(d, surfacetype_to_mime[x.surfacetype], x)
            end
        end
    elseif Symbol(m) === :GR
        @eval begin
            display(d::DomTermInline, x::$m.SVG) = display(d, MIME("image/svg+xml"), x)
            $m.inline()
        end
    elseif Symbol(m) === :DataFrames
        @eval begin
            display(d::DomTermInline, x::$m.DataFrame) = display(d, MIME("text/html"), x)
        end
    else
        @error("inline display for module: ", Symbol(m), " is not supported.")
    end
end
#
