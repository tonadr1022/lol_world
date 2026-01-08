#load "src/main.jai";

#run {
    make_directory_if_it_does_not_exist("./build/");
    Compiler :: #import "Compiler";
    Compiler.set_build_options_dc(.{output_path="build", output_executable_name="lol_world"});
    /*
    w := compiler_create_workspace("Target Program");
    options := get_build_options(w);
    options.output_path = "build";
    */
}

#scope_file 

#import "File";
