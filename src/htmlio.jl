# HTML Output Utilities

using Base64: Base64EncodePipe
using Colors
using ImageTransformations
using DomTerm

make_newline() = make_div("clear:both", "")
function make_div(st, content::String; id="", class="")
    if !isempty(id) && !isempty(class)
        return "<div id=\"$id\" class=\"$class\" style=\"$st\">"*content*"</div>"
    end
    if !isempty(id) && isempty(class)
        return "<div id=\"$id\" style=\"$st\">"*content*"</div>"
    end
    if isempty(id) && !isempty(class)
        return "<div class=\"$class\" style=\"$st\">"*content*"</div>"
    end
    if isempty(id) && isempty(class)
        return "<div style=\"$st\">"*content*"</div>"
    end
end

function make_img(st, content::String; id="", class="")
    if !isempty(id) && !isempty(class)
        return "<img id=\"$id\" class=\"$class\" style=\"$st\" src='data:image/png;base64,"*content*"' />"
    end
    if !isempty(id) && isempty(class)
        return "<img id=\"$id\" style=\"$st\" src='data:image/png;base64,"*content*"' />"
    end
    if isempty(id) && !isempty(class)
        return "<img class=\"$class\" style=\"$st\" src='data:image/png;base64,"*content*"' />"
    end
    if isempty(id) && isempty(class)
        return "<img style=\"$st\" src='data:image/png;base64,"*content*"' />"
    end
end

DTPIOContext(io, KVs::Pair...) = IOContext(
    io,
    :limit=>true, :color=>true, :domterm=>true,
    KVs...
)

function cmatrix_to_pngstr(img::AbstractMatrix{<:Colorant}; ratio=0.5, maxlen=10^6)
    buf = IOBuffer()
    b64 = Base64EncodePipe(buf)
    while applicable(length, img) && length(img) > maxlen
        img = imresize(img; ratio)
    end
    show(DTPIOContext(b64), MIME("image/png"), img)
    png_str = String(take!(buf))
    close(b64)

    return png_str
end

function make_img(st, im::AbstractMatrix{<:Colorant}; id="", class="")
    return make_img(st, cmatrix_to_pngstr(im); id, class)
end

to_html_ele(x::AbstractMatrix{<:Colorant}) = make_img("", cmatrix_to_pngstr(im))
to_html_ele(x::String) = make_div("", x)  # FIXME

function hprint(args...)
    content = ""
    for arg in args
        content *= to_html_ele(arg)
    end

    if !isempty(content)
        hput(content)
    end
end

function hprintln(args...)
    !isempty(args) && hprint(args...)
    hput("<div style=\"clear:both\"></div>")
end

# `x`: an HTML element
# dt_addst(".centerizer * {margin: 0 auto}")
function centerize(x::String)
    return make_div("text-align:center", x; class="centerizer")
end
