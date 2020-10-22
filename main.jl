if (length(ARGS) != 1) || (!isdir(ARGS[1]))
    println(stderr::IO, "This program requires at least 1 argument, that is the root directory of the place where the documents are stored")
    exit(1)
end

filenames = readdir(ARGS[1])

for filename in filenames
    lowercased = lowercase(filename)
    cleaned = replace(lowercased, " " => "_")
    println(cleaned)
end