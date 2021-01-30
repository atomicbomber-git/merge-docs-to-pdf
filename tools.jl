using HTTP

const EXTRACT_REGEXES = [
    r"\s*\(([^\)]*)\)\s*",
    r"\s*\"([^\"]*)\"\s*",
    r"\s*\“([^\“]*)\”\s*"
]

function pdftotext(pdfpath, tika_url="http://localhost:9998")
    response = nothing
    open(pdfpath) do pdffilestream
        response = HTTP.request(
            "PUT",
            joinpath(tika_url, "tika/main"),
            Dict([ ("Content-Type", "application/pdf") ]),
            pdffilestream
        )
    end
    
    return String(response.body)
end

function digit_percentage(text::AbstractString)::Float64
    return count(isdigit, text) / length(text)
end

function symbol_percentage(text::AbstractString)::Float64
    return count(
        c -> ~isletter(c) && ~isdigit(c) && (c !== ' ')
    , text) / length(text)
end

function contains_too_many_nonletters(text::AbstractString, threshold::Float64 = 0.2)::Bool
    return (digit_percentage(text) >= threshold) || (symbol_percentage(text) >= threshold)
end

function contains_forbidden_text(haystack::AbstractString, exclusion_list::Array{String,1})::Bool
    haystack = lowercase(haystack)
    split_haystack = split(haystack, ' ')

    for text in exclusion_list
        if (length(split(text, ' ')) == 1)
            for word in split_haystack
                if (word == lowercase(text))
                    return true
                end
            end
        else
            if (contains(haystack, lowercase(text)))
                return true
            end
        end
    end
    return false
end

function remove_subsentences(input::AbstractString, regexes::Array{Regex,1}=EXTRACT_REGEXES)::AbstractString
    for regex in regexes
        input = replace(input, regex => s" ")
    end
    return input
end

function get_subsentences(
    text::AbstractString,
    regexes::Array{Regex,1} = EXTRACT_REGEXES   
)::Array{AbstractString, 1}
    results = Array{AbstractString,1}()
    
    for regex in regexes
        match_results = eachmatch(regex, text)

        for match_result in match_results
            append!(results, [match_result[1]])
        end
    end

    return results
end


function qualifies_as_sentence(text::AbstractString)::Bool
    exclusion_list = [
        "jurnal edukasi dan penelitian informatika",
        "jepin",
        "justin",
        "Jurnal Sistem dan Teknologi Informasi",
        "referensi",
        "daftar pustaka",
        "kata kunci",
        "keywords"
    ]

    if (contains_too_many_nonletters(text))
        return false
    end

    if (contains_forbidden_text(text, exclusion_list))
        return false
    end

    if (length(
        filter(
            word -> ~contains_too_many_nonletters(word) && ~(word == ""),
            split(text)
        )
    ) <= 5)
        return false
    end

    return true
end

function fix_broken_commas(text::AbstractString)::AbstractString
    result = replace(text, r"(\s+)," => s",")
    result = replace(result, r",([^\ ])" => s", \1")
    return result
end

function fix_duplicate_spaces(text::AbstractString)::AbstractString
    return replace(text, r"\ {2,}" => s" ")
end

function replace_dots(text::AbstractString, replacement::AbstractString="<DOT>")::AbstractString
    return replace(text, r"([\*\w]*)\.(\w+\s*)" => SubstitutionString("\\1$replacement\\2"))
end

function replace_back_dots(text::AbstractString, replacement::AbstractString="\\<DOT\\>")::AbstractString
    regex_string = "([\\*\\w]*)$replacement(\\w+\\s*)"
    return replace(text, Regex(regex_string) => s"\1.\2")
end

if abspath(PROGRAM_FILE) == @__FILE__
    println(
        replace_dots("hello.com")
    )


    # println(
    #     remove_subsentences(
    #         "pengetahuan (ilmu ajaib) dapat diklasifikasikan (dikelompokkan) menjadi tiga, yaitu, procedural knowledge (pengetahuan (pengetahuan tacit)"
    #     )
    # )

    # println(qualifies_as_sentence("Hello 12121212121121212") )
    # println(qualifies_as_sentence("Hello world") )
    # println(qualifies_as_sentence("di jurnal jepin") )
    # println(qualifies_as_sentence("di jurnal JUSTINIAN") )
    # println(qualifies_as_sentence("di Jurnal Sistem dan Teknologi informasi") )
    # println(qualifies_as_sentence("saya pergi ke sekolah pagi ini bersama teman saya") )
    # println(qualifies_as_sentence(" , vol 3, no 4, pp"))
end