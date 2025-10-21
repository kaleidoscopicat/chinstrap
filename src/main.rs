use std::io;
use std::env;
mod ioreader;
use ioreader::*;

fn main() {
    let args: Vec<String> = env::args().collect();
    assert!(args.len() > 1, "Must give an argument for the file to compile!");

    // Get Tokenizer from the file path given

    let file_path: &String = &args[1];
    let source_result = get_source(file_path);

    let source: Vec<String> = match source_result {
        Ok(vec) => vec,
        Err(e) => {
            eprintln!("Error Code 0:\n\tFile {file_path} cannot be converted into type source correctly!");
            Vec::new()
        }
    };

    let mut line_reader = Line::new(&source[0], true, 0, &source);
    let contents_temp = line_reader.contents.to_string();

    println!("{}", contents_temp);

    while (line_reader.next_line(false))
    {
        println!("{}", line_reader.contents);
    }
}