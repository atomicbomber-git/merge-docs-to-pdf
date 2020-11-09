using HTTP

function pdftotxt(pdfpath, tika_url="http://localhost:9998")
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

root_path = "/home/atomicbomber/Desktop/DATA_TA_JEFRI/"
output_path = "/home/atomicbomber/Desktop/articles-output"
!isdir(output_path) && mkdir(output_path)

# example_file = "/home/atomicbomber/Desktop/DATA_TA_JEFRI/jepin/vol_1__no_1_(2015)_edisi_perdana/10008-32748-4-pb.pdf"

# println(pdftotxt(example_file))


filepath_list = Array{String, 1}()

for (root, dir, files) in walkdir(root_path)
    append!(filepath_list, [joinpath(root, file) for file in files if splitext(file)[2] === ".pdf"])
end

fail_list = Array{String, 1}()

Threads.@threads for filepath in filepath_list
    filename = splitdir(filepath)[2]
    println("Processing $filename...")

    try
        extracted_text = pdftotxt(filepath)
        barename, extension = splitext(filename)
        
        output_name = "$barename.txt"
        open(joinpath(output_path, output_name), "w") do io
            write(io, extracted_text)
        end

        println("Finished processing $filename.")
    catch e
        append!(fail_list, [filename])
        println("Failed to process $filename.")
    end
end

println("We failed to process these documents: ")
println(join(fail_list, ", ", " and "))