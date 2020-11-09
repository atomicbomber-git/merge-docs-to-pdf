using WordTokenizers
using JSON

output_path = "/home/atomicbomber/Desktop/articles-output"
json_path = "/home/atomicbomber/Desktop/tokens.json"

token_map = Dict{String,Int}()

function custom_tokenize(text::AbstractString)
    tokens = WordTokenizers.rev_tokenize(text)
    return [token for token in tokens if !contains(token, WordTokenizers.MERGESYMBOL)]
end

function is_valid_token(text::AbstractString)
    for char in text
        if !isletter(char)
            return false
        end 
    end

    return true
end


for file in readdir(output_path, join=true)
    open(file, "r") do file_io
        text = read(file_io, String)

        for sentence in split_sentences(text)
            for token in custom_tokenize(sentence)
            
                !is_valid_token(token) && continue
                lowercased_token = lowercase(token)

                if (haskey(token_map, lowercased_token))
                    token_map[lowercased_token] = token_map[lowercased_token] + 1 
                else
                    token_map[lowercased_token] = 1
                end
            end
        end
    end
end

filtered_token_map = Dict{String, Int}()

for (key, value) in token_map
    if (value > 5) 
        filtered_token_map[key] = value
    end
end

open(json_path, "w") do io
    JSON.print(io, filtered_token_map)
end