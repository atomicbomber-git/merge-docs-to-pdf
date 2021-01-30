
include("./tools.jl")

root_path = "/home/atomicbomber/Desktop/DATA_TA_JEFRI/"
output_path = "/home/atomicbomber/projects/spelling-corrector/database/seeds/sentences"

!isdir(output_path) && mkdir(output_path)


filepath_list = Array{String, 1}()

for (root, dir, files) in walkdir(root_path)
    append!(filepath_list, [joinpath(root, file) for file in files if splitext(file)[2] === ".pdf"])
end

function fix_text(text)
    text = fix_broken_commas(text)
    text = fix_duplicate_spaces(text)
end

const START_MARKER_CANDIDATES = [
    "abstrak",
    "abstract",
]

function get_start_index(text::AbstractString, start_markers=START_MARKER_CANDIDATES)
    position = nothing
    
    for start_marker in start_markers
        position = findfirst(text, start_marker)

        if !isnothing(position)
            break
        end
    end

    if isnothing(position)
        return nextind(text, 1)
    else
        return nextind(text, position.stop)
    end
end

const STOP_MARKER_CANDIDATES = [
    r"daftar pustaka",
    r"referensi",
    r"\[\s*1\s*\]",
]

function get_stop_index(text::AbstractString, stop_markers=STOP_MARKER_CANDIDATES)
    position = nothing
    
    for stop_marker in stop_markers
        match_offsets = map(
            m -> m.offset,
            eachmatch(stop_marker, text)
        )

        position = length(match_offsets) > 0 ? last(match_offsets) : nothing

        if (!isnothing(position))
            break
        end
    end

    if (isnothing(position))
        return prevind(text, length(text))
    else
        return prevind(text, position)
    end
end

Threads.@threads for filepath in filepath_list[1:1]
    filename = splitdir(filepath)[2]
    basename = splitext(filename)[1]

    println("Processing $filename...")

    output_filepath = joinpath(output_path, "$(basename).txt")
    !isfile(output_filepath) && touch(output_filepath)
    
    text = pdftotext(filepath)
    filtered = lowercase(text)
    filtered = filtered[get_start_index(filtered):get_stop_index(filtered)]

    println(filtered)

    filtered = replace(filtered,  '\n' => ' ')
    filtered = replace(filtered, "dkk." => "dkk")
    filtered = replace(filtered, "vol." => "vol")
    filtered = replace(filtered, "no." => "no")
    filtered = replace(filtered, "et." => "et")
    filtered = replace(filtered, "al." => "al")
    filtered = replace(filtered, "pt." => "pt")
    filtered = replace(filtered, "cv." => "cv")
    filtered = replace(filtered, "dr." => "dr")
    filtered = replace(filtered, "cv." => "cv")

    # Mengganti teks seperti ".pdf" dan "hello.txt" menjadi "<DOT>pdf" dan "hello<DOT>txt"
    filtered = replace_dots(filtered)
    
    # Menghapus teks seperti "[1]", "[2]", atau "[123443]"
    filtered = replace(filtered, r"\s*\[\d+\]\s*" => s"")

    # Potong teks jadi kalimat
    sentences = split(filtered, ".")
    sentences = map(sentence -> strip(sentence, [' ', '-', '—']  ), sentences)

    file = open(output_filepath, "w")

    # Removes sentences that starts with number
    for sentence in filter(qualifies_as_sentence, sentences)
        sentence = replace_back_dots(sentence)
        subsentences = get_subsentences(sentence)

        for subsentence in filter(qualifies_as_sentence, subsentences)
            subsentence = fix_text(subsentence)
            write(file, "$subsentence\n")
        end

        sentence = remove_subsentences(sentence)
        sentence = fix_text(sentence)

        write(file, "$sentence\n")
    end

    close(file)
end