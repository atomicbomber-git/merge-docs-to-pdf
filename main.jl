import JSON

if (length(ARGS) != 1) || (!isdir(ARGS[1]))
    println(stderr::IO, "This program requires at least 1 argument, that is the root directory of the place where the documents are stored")
    exit(1)
end

function clean_filename(filename)
    cleaned = lowercase(filename)
    cleaned = replace(cleaned, " " => "_")
end

root_path = ARGS[1]
filenames = readdir(root_path)

mahasiswa_names = Array{String,1}()
contains_bab = Dict{String,Array{String,1}}()
contains_skripsi = Dict{String,Array{String,1}}()
contains_remainder = Dict{String,Array{String,1}}()

for filename in filenames

    subdir_path = joinpath(root_path, filename)
    subfilenames = readdir(subdir_path)

    for subfilename in subfilenames
        full_subfilename = joinpath(subdir_path, subfilename)
        
        if (!isdir(full_subfilename))
            continue
        end

        append!(mahasiswa_names, [subfilename])

        # Check for files that contain BAB
        for (root, dir, files) in walkdir(full_subfilename)
            for file in files

                joined_filename = joinpath(root, file)

                if (findfirst("bab", lowercase(file)) !== nothing)
                    if (!haskey(contains_bab, subfilename))
                        contains_bab[subfilename] = Array{String,1}()
                    end

                    append!(contains_bab[subfilename], [joined_filename])
                
                elseif (
                    ( findfirst("skripsi", lowercase(file)) !== nothing ) ||
                    ( findfirst("tugas akhir", lowercase(file)) !== nothing )
                )
                    if (!haskey(contains_skripsi, subfilename))
                        contains_skripsi[subfilename] = Array{String,1}()
                    end

                    append!(contains_skripsi[subfilename], [joined_filename])
                else
                    if (!haskey(contains_remainder, subfilename))
                        contains_remainder[subfilename] = Array{String,1}()
                    end
                    
                    append!(contains_remainder[subfilename], [joined_filename])
                end
            end
        end
    end
end


final_catalogue = Dict{String, Array{String, 1}}()
prioritized_extensions = [".pdf", ".docx", ".doc"]

for mahasiswa_name in mahasiswa_names
    final_catalogue[mahasiswa_name] = Array{String,1}()

    local filenames = get(contains_skripsi, mahasiswa_name, nothing)
    if (filenames !== nothing)
        for extension in prioritized_extensions
            for filename in filenames
                if (splitext(filename)[2] === extension)
                    
                    append!(
                        final_catalogue[mahasiswa_name],
                        [filename]
                    )
                    break
                end
            end
        end 
    end
    
    if (length(final_catalogue[mahasiswa_name]) !== 0)
        continue
    end

    filenames = get(contains_bab, mahasiswa_name, nothing)
    if (filenames !== nothing)
        for extension in prioritized_extensions
            temp = Array{String,1}()
            for filename in filenames
                if (splitext(filename)[2] === extension)
                    append!(
                        temp,
                        [filename]
                    )
                end
            end

            if (length(temp) !== 0)
                append!(final_catalogue[mahasiswa_name], temp)
                break
            end
        end
    end

    if (length(final_catalogue[mahasiswa_name]) !== 0)
        continue
    end

    append!(
        final_catalogue[mahasiswa_name],
        contains_remainder[mahasiswa_name]
    )
end

temp_directory = "/home/atomicbomber/Desktop/experiment"
!isdir(temp_directory) && mkdir(temp_directory)

out_directory = "/home/atomicbomber/Desktop/output"
!isdir(out_directory) && mkdir(out_directory)

for (key, value) in final_catalogue
    for (mahasiswa_name, files) in final_catalogue

        mahasiswa_dir = joinpath(temp_directory, mahasiswa_name)
        !isdir(mahasiswa_dir) && mkdir(mahasiswa_dir)

        for file in files
            extension = splitext(file)[2]
            dir, filename = splitdir(file)
            
            bare_filename, filename_extension = splitext(filename)
            converted_filename = "$bare_filename.pdf"

            if (extension === ".docx" || extension === ".doc")
                if (!isfile(joinpath(mahasiswa_dir, converted_filename)))
                    println("Converting $(filename) to PDF...\n")
                    run(`libreoffice --headless --convert-to pdf:writer_pdf_Export --outdir $mahasiswa_dir $file`)
                    println()
                end
            elseif (extension === ".pdf")
                if (!isfile(joinpath(mahasiswa_dir, filename)))
                    println("Copying $file to $mahasiswa_dir")
                    cp(file, joinpath(mahasiswa_dir, filename), force=true)
                end
            end
        end
    end
end

for (root, dir, files) in walkdir(temp_directory)
    mahasiswa_identity = splitdir(root)[2]
    out_file_path = joinpath(out_directory, "$(mahasiswa_identity).pdf")

    pdf_files = [joinpath(root, file) for file in files if splitext(file)[2] === ".pdf"]
    
    if (length(pdf_files) !== 0)
        println("Merging $(join(pdf_files, ", ", " and ")) to $out_file_path")

        command = `pdfunite $pdf_files $out_file_path`
        run(command)
    end
end