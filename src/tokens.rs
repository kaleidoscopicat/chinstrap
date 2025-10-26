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
    let comp: LuaFunction = globals.get("comp")?;

    let tokenValue: LuaValue = comp.call(())?;

    let tokenMap: LuaTable = match tokenValue {
        LuaValue::Table(t) => t,
        _ => panic!("Expected a Lua table"),
    };

    for line_pair in tokenMap.sequence_values::<LuaValue>() {
        let line_value = line_pair?;
        let line_table = match line_value {
            LuaValue::Table(t) => t,
            _ => continue,
        };

        for token_pair in line_table.sequence_values::<LuaValue>() {
            let token_value = token_pair?;
            let token_table = match token_value {
                LuaValue::Table(t) => t,
                _ => continue,
            };

            let contents: String = token_table.get("Contents")?;
            let result: Option<f64> = token_table.get("Result")?;
            let ttype: i64 = token_table.get("Type")?;

            println!("Contents: {}, Result: {:?}, Type: {}", contents, result, ttype);
        }
    }

    Ok(())
}