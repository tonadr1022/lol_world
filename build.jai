#load "src/main.jai";

#run build();

build :: () {
    make_directory_if_it_does_not_exist("./build/");
    Compiler :: #import "Compiler";
    Compiler.set_build_options_dc(.{output_path="build", output_executable_name="lol_world"});
}

#scope_file

#import "File";
