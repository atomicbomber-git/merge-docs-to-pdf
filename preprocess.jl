root_dir = "/home/atomicbomber/Desktop/data_skripsi_informatika_untan"

for (root, dirs, files) in walkdir(root_dir, topdown=false)
    for file in files
        fullpath = joinpath(root, file)
        extension = splitext(file)[2]

        if (extension === ".rar")
            run(`unrar x -o+ $fullpath $root`)
        elseif (extension === ".zip")
            run(`unzip -o -d $root $fullpath`)
        end
    end
end