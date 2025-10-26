/*
 * @name: tokens.rs
 * @author: kaleidoscopicat
 * @desc: Handles tokens in files. Main token-izer. Contains token-versions of pure classes.
 */

use crate::ioreader::*;
use mlua::prelude::*;
use std::fs;

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

pub fn test() -> LuaResult<()> {
    let lua = Lua::new();

    let rust_print = lua.create_function(|_, msg: String| {
        println!("{}", msg);
        Ok(())
    })?;
    lua.globals().set("print", rust_print)?;

    let code = fs::read_to_string("lua/tokenizer.lua")
        .expect("Failed to read tokenizer.lua");

    lua.load(&code).exec().expect("Failed to execute Lua file!");

    let globals = lua.globals();
    let debug: LuaFunction = globals.get("debug")?;

    let result: String = debug.call(())?;

    Ok(())
}