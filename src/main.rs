/*
 * @name: main.rs
 * @author: kaleidoscopicat
 * @desc: Main file for processing Chinstrap code and compiling it. Gets compiled into an
 *        exe by Cargo.
 */

use std::io;
use std::env;

mod ioreader;
mod middleman;

use ioreader::*;
use middleman::*;

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

    middleman::passthru(source);
}