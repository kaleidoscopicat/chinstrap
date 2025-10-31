/*
 * @name: ioreader.rs
 * @author: kaleidoscopicat
 * @desc: Helper function(s) for reading Chinstrap code.
 */

use std::io::{self, BufReader};
use std::io::prelude::*;
use std::fs::File;

pub fn get_source(file_path: &String) -> io::Result<Vec<String>>
{
    let file = File::open(file_path)?;
    let reader = BufReader::new(file);
    
    let mut lines = Vec::new();

    for line in reader.lines() {
        lines.push(line?);
    }
    
    return Ok(lines);
}