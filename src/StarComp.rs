use std::io;
use std::env;

mod ioreader;
mod tokens;

use ioreader::*;
use tokens::*;

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
    let mut block_tree = Block::new(source, None, None); // Primary block never really gets it's contents... read... so?
    block_tree::search_through();

    let token_tree = TokenBlock::from_block(&block_tree);
    
}