#############################################################################
## pretty_print_xml()
function pretty_print_xml(xmlstr::String)
    # convert a utf-8 string `xmlstr` to a vector of unicode chars so we can
    # index into it easily
    xml_chars = Char[]
    i = 1
    while i <= ncodeunits(xmlstr)
        push!(xml_chars, xmlstr[i])
        i = nextind(xmlstr, i)
    end

    # print the tree
    ele_stack = [("string", -1, -1)]
    i = 1
    while i <= length(xml_chars)
        #skip whitespaces
        while isspace(xml_chars[i]) i += 1 end
        xml_chars[i] != '<' && error("Unknown token: ", xml_chars[i])
        i = pretty_print_element(xml_chars, i, 0, ele_stack)
    end
end

const tbsz = 3
function pretty_print_element(
    xml::Vector{Char}, start::Int, indent::Int, ele_stack::Vector{Tuple{String, Int, Int}}
)
    # mml[start] must be '<'
    t_start, t_end, i, ele_name = start, -1, start + 1, ""
    hasChild::Bool = false
    # get starting tag
    while xml[i] != '>' && xml[i] != ' '
        ele_name *= xml[i]
        i += 1
    end
    # move the index to the position right behind '>'
    if xml[i] == '>'
        t_end = i
        i += 1
    else
        # xml[i] == ` `, there are attributes following the tag name
        while xml[i] != '>'; i += 1; end
        t_end = i
        i += 1
    end

    push!(ele_stack, (ele_name, t_start, t_end))
    #print(" "^indent*"<", ele_name, '>')
    if xml[i - 2] == '/'
        # simple leaf elements <ele ... /> are printed in one line
        print(" "^indent*String(xml[t_start:t_end]))
        #while xml[i] != '<'
        #    print(mml[i])
        #    i += 1
        #end
        # Now mml[i] == '<' in the ending tag of <mi>, <mn>, <mo>, <mspace>
        #while mml[i] != '>' i += 1 end
        #i += 1
        i <= length(xml) && while isspace(xml[i]) i += 1 end
        #print("</", ele_name, ">")
        #println()
        pop!(ele_stack)
        return i
    else
        # the starting tag name, we do not know yet if this element has a child
        print(" "^indent*"<", ele_name, '>')
        # keep finding the next tag and print
        while true
            while isspace(xml[i]) i += 1 end
            i > length(xml) && break

            if xml[i] == '<' && xml[i+1] != '/'
                # a child element
                println() # printing child starts a new line
                hasChild = true
                i = pretty_print_element(xml, i, indent + tbsz, ele_stack)
            elseif xml[i] == '<' && xml[i+1] == '/'
                # we encounter the closing tag of an element
                i += 2
                en2 = ""
                while xml[i] != '>'
                    en2 *= xml[i]
                    i += 1
                end
                en = pop!(ele_stack)
                # we could have sth like <mspace width=...> </mspace>
                !startswith(en[1], en2) && begin
                    println(ele_stack)
                    error("tag not match: ", en, " -- ", en2)
                end
                # xml[i] == '>'
                if hasChild
                    println()
                    println(" "^indent*"</", en2, '>')
                else
                    println("</", en2, '>')
                end
                i += 1
                #i > length(xml) && return i
                #while isspace(xml[i]) i += 1 end
                return i
            else
                # xml[i] != `<`, we encounter the content of an element
                content = ""
                while xml[i] != '<'
                    content *= xml[i]
                    i += 1
                end
                if hasChild # some child element is already printed
                    print(" "^indent*content)
                else
                    print(content)
                end
            end
        end
    end
end

