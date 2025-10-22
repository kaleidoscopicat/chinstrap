/*
 * @name: tokens.rs
 * @author: kaleidoscopicat
 * @desc: Handles tokens in files. Main token-izer. Contains token-versions of pure classes.
 */

use crate::ioreader::*;

pub enum TokenType {
    Keyword,
    Identifier,
    Operator,
    LiteralString,
    LiteralNumber,
    Symbol,
    Comment,
    Unknown,
}

#[derive(Clone)]
pub struct Token {
    pub kind: TokenType,
    pub contents: String,
    pub line_number: usize,
}

#[derive(Clone)]
pub struct TokenLine { // Line @ ioreader.rs
    pub contents: Vec<Token>,
    pub source: Vec<Vec<Token>>,
    pub line_number: usize,
}

#[derive(Clone)]
pub struct TokenBlock { // Block @ ioreader.rs
    pub contents: Vec<TokenLine>,
    pub children: Box<Vec<TokenBlock>>,
}

impl Token {
    pub fn from_line(line: &str, line_numer: usize) -> Vec<Token> {
        let mut tokens: Vec<Token> = Vec::new();

        let parts = line.split_whitespace();

        for part in parts {
            let kind = if part.starts_with("$$") {
                TokenType::Comment
            } else if part.starts_with("\"") && part.ends_with("\"") {
                TokenType::LiteralString
            } else if part.chars().all(|c| c.is_numeric()) {
                TokenType::LiteralNumber
            } else if ['{', '}', '(', ')', ':', ';', '='].contains(&part) {
                TokenType::Symbol
            } else if ["fn", "let", "if", "else", "for", "return", "continue"].contains(&part) {
                TokenType::Keyword
            } else if ["+", "-", "*", "/", "->"].contains(&part) {
                TokenType::Operator
            } else {
                TokenType::Identifier
            };

            tokens.push(Token {
                kind,
                contents: part.to_string(),
                line_number,
            })
        }

        return tokens;
    }
}

impl TokenLine {
    pub fn from_line(line: &Line) -> TokenLine {
        TokenLine {
            contents: Token::from_line(&line.contents, line.line_number),
            source: vec![],
            line_number: line.line_number,
        }
    }
}

impl TokenBlock {
    pub fn from_block(block: &Block) -> TokenBlock {
        let mut token_lines = Vec::new();
        for (i, line) in block.contents.iter().enumerate() {
            let line_struct = Line {
                contents: line.clone(),
                current_line: false,
                line_number: i,
                source: block.contents.clone()
            };

            token_lines.push(TokenLine::from_line(&line_struct));
        }

        let mut token_children = Vec::new();
        for child in block.children.iter() {
            token_children.push(TokenBlock::from_block(child));
        }

        return TokenBlock {
            contents: token_lines,
            children: Box::new(token_children),
        };
    }
}