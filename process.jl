import HTTP

test_path = "/home/atomicbomber/Desktop/process_temp/D03105030 Franki Tello Panjaitan.pdf"

function pdftotext(pdfpath)
    return read(`pdftotext "$pdfpath" -`)
end

# function pdftotxt(pdfpath, tika_url="http://localhost:9998")
#     response = nothing
#     open(pdfpath) do pdffilestream
#         response = HTTP.request(
#             "PUT",
#             joinpath(tika_url, "tika"),
#             Dict([ ("Content-Type", "application/pdf") ]),
#             pdffilestream
#         )
#     end
    
#     return String(response.body)
# end

tika_executable_path = "/home/atomicbomber/programs/tika-server-1.24.jar" 
input_dir = "/home/atomicbomber/Desktop/data_skripsi_informatika_untan"

temp_dir = "/home/atomicbomber/Desktop/process_temp"
!isdir(temp_dir) && mkdir(temp_dir)

output_dir = "/home/atomicbomber/Desktop/process_out"
!isdir(output_dir) && mkdir(output_dir)

println("Running using $(Threads.nthreads()) threads.")

catalogue = Dict{String,Array{String,1}}()

for level1_file in readdir(input_dir, join=true)
    !isdir(level1_file) && continue

    for level2_file in readdir(level1_file, join=true)
        !isdir(level2_file) && continue        
        mahasiswa_identity = splitdir(level2_file)[2]

        for (root, dir, files) in walkdir(level2_file)
            bab_files = [joinpath(root, file) for file in files if findfirst("bab", lowercase(file)) !== nothing]
            length(bab_files) === 0 && continue
            
            !haskey(catalogue, mahasiswa_identity) && (catalogue[mahasiswa_identity] = Array{String,1}())
            append!(catalogue[mahasiswa_identity], bab_files)
        end
    end
end

for (mahasiswa_name, skripsi_files) in catalogue
    mahasiswa_dir = joinpath(temp_dir, mahasiswa_name)
    !isdir(mahasiswa_dir) && mkdir(mahasiswa_dir)

    for file in skripsi_files
        root, basename = splitdir(file)
        barename, ext = splitext(basename)

        if (ext === ".docx" || ext === ".doc")
            output = "$barename.pdf"
            fullpath_output = joinpath(mahasiswa_dir, output)
            isfile(fullpath_output) && continue

            command_text = "libreoffice --headless --convert-to pdf:writer_pdf_Export --outdir \"$mahasiswa_dir\" \"$file\""            
            println(command_text)

            run(`libreoffice --headless "-env:UserInstallation=file:///tmp/LibreOffice_Conversion_$(ENV["USER"])" --convert-to pdf:writer_pdf_Export --outdir $mahasiswa_dir $file`)                
            println()
        else
            fullpath_output = joinpath(mahasiswa_dir, basename)
            isfile(fullpath_output) && continue
            
            println("Copying $file to $fullpath_output.")
            cp(file, fullpath_output)
        end
    end
end

extract = function (file)
    basename = lowercase(splitdir(file)[2])
    return basename[
        findfirst("bab", basename)[1]:end
    ]
end

Threads.@threads for mahasiswa_dir in readdir(temp_dir, join=true)
    !isdir(mahasiswa_dir) && continue
    
    root, dir = splitdir(mahasiswa_dir)    
    mahasiswa_identity = dir
    output_filename = "$mahasiswa_identity.pdf"
    output_filepath = joinpath(root, output_filename)
    
    input_files = sort(
        [file for file in readdir(mahasiswa_dir, join=true) if splitext(file)[2] === ".pdf"],
        by=extract,
    )

    length(input_files) === 0 && continue

    run(`pdfunite $input_files $output_filepath`)
end

for file in readdir(temp_dir, join=true)
    isdir(file) && continue

    basefile, ext = splitext(file)

    open("$basefile.txt", "w") do filestream
        print(filestream, pdftotxt(file))
    end
end

