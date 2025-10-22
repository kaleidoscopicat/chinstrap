/*
 * @name: ioreader.rs
 * @author: kaleidoscopicat
 * @desc: Helper classes and functions for reading StarShade code.
 */

use std::io::{self, BufReader};
use std::io::prelude::*;
use std::fs::File;
use std::sync::Mutex;

use crate::tokens::*;

pub static CACHE: Mutex<Vec<Block>> = Mutex::new(Vec::new());

#[derive(Clone)]
pub struct Block {
    pub contents: Vec<String>,
    pub parent_block: Box<Option<Block>>,
    pub children: Box<Vec<Block>>,
}

#[derive(Clone)]
pub struct Line {
    pub contents: String,
    pub current_line: bool,
    pub line_number: usize,
    pub source: Vec<String>,
}

impl Block {
    pub fn new(contents: Vec<String>, parent_block: Option<&Block>, children: Option<Vec<&Block>>) -> Block {
        let loaded_children: Vec<Block> = match children {
            Some(x) => x.into_iter().map(|b| (*b).clone()).collect(),
            None => Vec::new()
        };

        return Block {
            contents: contents,
            parent_block: Box::new(parent_block.cloned()),
            children: Box::new(loaded_children)
        }
    }

    pub fn add_child(&mut self, block: &Block) {
        let mut clonedBlock: Block = block.clone();
        clonedBlock.parent_block = Box::new(Some(self.clone()));
        self.children.push(clonedBlock);
    }

    pub fn search_through(&mut self) {
        let mut current_block_lines: Vec<String> = Vec::new();
        let mut brace_depth: usize = 0;

        let contents = self.contents.clone();
        for line in contents {
            if line.contains('{') {
                brace_depth += 1;
                if brace_depth == 1 {
                    current_block_lines.clear();
                    continue;
                }
            }

            if brace_depth > 0 {
                current_block_lines.push(line.clone());
            }

            if line.contains('}') {
                if brace_depth > 0 {
                    brace_depth -= 1;
                }

                if brace_depth == 0 {
                    current_block_lines.pop();

                    let mut child_block = Block::new(current_block_lines.clone(), Some(self), None);
                    child_block.search_through();

                    self.add_child(&child_block);

                    current_block_lines.clear();
                }
            }
        }
    }
}

impl Line {
    pub fn new(contents: &String, is_current_line: bool, line_number: usize, source: &Vec<String>) -> Line
    {
        // TODO: Check for more efficient way? Too much Some(x) wrapping?
        let mut new_line: Line = Line {
            contents: contents.to_string(),
            current_line: is_current_line,
            line_number: line_number,
            source: source.to_vec()
        };

        return new_line;
    }

    pub fn to_line(&self) -> Line {
        let mut new_line: Line = Line {
            contents: self.contents.to_string(),
            current_line: self.current_line,
            line_number: self.line_number,
            source: self.source.clone(), // clone the Vec<String>
        };

        return new_line;
    }

    pub fn next_line(&mut self, switch_focus: bool) -> bool
    {
        if (switch_focus) {
            self.current_line = false;
        }
        let next_line_contents = self.source.get(self.line_number + 1);
        let current_contents = self.contents.to_string();

        match next_line_contents {
            Some(c) => (self.contents = c.to_string()),
            None => {
                return false;
            }
        }

        if (self.contents != current_contents)
        {
            self.line_number += 1;
            return true;
        }

        return false;
    }

    pub fn prev_line(&mut self, switch_focus: bool) -> bool
    {
        if (self.line_number == 0)
        {
            return false;
        }
        if (switch_focus) {
            self.current_line = false;
        }

        let prev_line_contents = self.source.get(self.line_number - 1);
        let current_contents = self.contents.to_string();

        match prev_line_contents {
            Some(c) => (self.contents = c.to_string()),
            None => println!("Reached start of file whilst reading!")
        }

        if (self.contents != current_contents)
        {
            self.line_number -= 1;
            return true;
        }

        return false;
    }
}

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