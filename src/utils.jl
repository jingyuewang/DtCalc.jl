using FileIO

IMAGE_FILETYPES = [:GIF, :JPEG, :PNG, :PGMBinary]
function is_image(filename)
    q = query(filename)
    for mtype in IMAGE_FILETYPES
        q isa File{DataFormat{mtype}, String} && return true
    end
    return false
end

const card_sz = 256
const card_st = "shadow" # styles: shadow, plain
# Basically set up a bunch of styles for a div containing an image and a string
function make_card(img::AbstractMatrix{<:Colorant}, title::String;
                   cardsize=card_sz, cardstyle=card_st)
    style = ""
    style *= "width: $(cardsize)px;"
    style *= "height: $(cardsize)px;"
    style *= "background-color: white;"
    style *= "box-sizing: border-box;"
    style *= "float: left;"
    style *= "margin: 30px 20px;"
    if cardstyle == "shadow"
        style *= "box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);"
    else
        style *= "border: solid black; border-width: 1px;"  # a plain border style
    end
    style *= "position: relative;"

    im_style = ""
    im_style *= "max-width: 90%;"
    im_style *= "width: auto;"
    im_style *= "max-height: 70%;"
    im_style *= "height: auto;"
    im_style *= "display: block;"
    im_style *= "margin: 0.5em auto auto;"

    tt_style = ""
    tt_style *= "margin-left: 10%;"
    tt_style *= "margin-right: 10%;"
    tt_style *= "position: absolute;"
    tt_style *= "bottom: 10px;"
    tt_style *= "font-size: 75%;"

    return make_div(style, make_img(im_style, img)*make_div(tt_style, title))
end

function preview_dir(img_dir; index=[])
    flist = readdir(img_dir)
    imglist = filter(is_image, flist)

    for (i, fn) in enumerate(imglist)
        if isempty(index) || i in index
            im = load(img_dir*'/'*fn)
            sz = size(im)
            # TODO: add support for 3D images (e.g., animated gif)
            if length(size(im)) <= 2
                if maximum(sz) > (card_sz*0.9)
                    r = (card_sz*0.9)/maximum(sz)
                    im = imresize(im, ratio=r)
                end
                hput(make_card(im, fn))
            end
        end
    end
    hprintln()
end

function ls_imginfo(img_dir)
    flist = readdir(img_dir)
    imglist = filter(is_image, flist)

    for fn in imglist
        im = load(img_dir*fn)
        println(fn, ": dimension ", size(im))
    end
end

const expbitlen = Dict([
    Float64 => 11,
    Float32 => 8,
    Float16 => 5
    ])
__FloatType = Union{Float64, Float32, Float16}

function showIEEE754(x::__FloatType)
    # NOTE: the first char in the bit string is the hightest bit.
    bs = bitstring(x)
    bitlen=length(bs)
    exp_bitlen = expbitlen[typeof(x)]

    ## All to be drawn:
    # 64 boxes, the top-left corner of the first box is the origin.
    # three over-brackets (including one degenerated).
    # three circles.
    boxes = Vector{Rect}(undef, bitlen)
    ovbrs = Vector{Brace}(undef, 3)
    circles = Vector{Circ}(undef, 3)
    # parameters
    boxwidth, boxheight = 14, 28
    circ_offset = R²(0, 5)
    r = 5

    # create boxes
    for i in 1:bitlen
        boxes[i] = Rect((i-1)*boxwidth, 0, boxwidth, boxheight, label=string(bs[i]))
    end

    # create overbrackets
    ovbrs[1] = Brace(boxes[1], label="sign")
    ovbrs[2] = Brace(boxes[2], boxes[1+exp_bitlen], label="exponent\n($exp_bitlen bit)")
    ovbrs[3] = Brace(boxes[2+exp_bitlen], boxes[bitlen],
                     label="fraction\n($(bitlen - 1 - exp_bitlen) bit)")

    # create circles
    circles[1] = Circ(midbottom(boxes[1]) + circ_offset + (0, r), r, label="$(bitlen - 1)")
    circles[2] = Circ(midbottom(boxes[1+exp_bitlen]) + circ_offset + (0, r), r,
                      label="$(bitlen - 1 - exp_bitlen)")
    circles[3] = Circ(midbottom(boxes[bitlen]) + circ_offset + (0, r), r, label="0")

    # set class, id, and styles
    boxes[1].id = "box1"
    for i = 2:bitlen
        boxes[i].class = (2 <= i <= 1+exp_bitlen ? "expbox" : "fracbox")
    end
    ovbrs[1].id = "overbrace1"
    css = CssRules([
        ("#overbrace1", "--vg-offset: 0.5;"), # 0.5 or greater values: degenerated brace
        ("#box1", "fill: cyan;"),
        (".expbox", "fill: lightgreen;"),
        (".fracbox", "fill: yellow;"),
        ("Rect", "--vg-label-side: center;"),
        ("Brace", "stroke: blue; --vg-shape: bracket; --vg-side: above; --vg-label-side: above;"),
        ("Circ", "fill: pink; --vg-label-side: below;"),
    ])
    if typeof(x) == Float16
        css["#overbrace1"] *= "--vg-label-anchor: end;"
    end
    # write to a svg string and display it
    svg = make_svg_root(boxes, ovbrs, circles; css)
    hput(svg)
    println()
end

