<img width="830" height="218" alt="chinstrap banner" src="https://github.com/user-attachments/assets/352fd069-f16d-47ba-a240-e8da821b40ae" />


---
Chinstrap is a lightweight, human-readable shader language designed specifically for direct integration with Unity and a C#/Rust-friendly syntax. It is purpose-built for ease of use and maintainability, without the verbosity of traditional HLSL, which it compiles directly into. The compiler for Chinstrap is written in Lua and Rust.

## Features
* **Friendly syntax**: Type non-specific function & variable declarations (fn), readable indenting (moving away from HLSL boilerplate), Unity-like types (`Vector3`/`float3`, `Vector4`/`float4`/`Color`, `Array`/`RWStructuredBuffer<T>`).
* **Logical backwards** compatability with HLSL, whilst having more readable methods alongside it. (e.g. `Vector3` and `float3` both get compiled into a `float3`)
* **Lightweight compiler**: The compiler is designed to be fast and minimal, parsing .csp files efficiently with a Lua-based parser, making it suitable for iterative development and quick testing.
* **VSCode support**: A dedicated extension provides syntax highlighting, snippets for syntax (fn, @uniform, @property, tables), and integrated in-editor compilation.
  
## Example
```
@property("MainTex", 2D); $ Single-property declaration
@uniform(Props); $ Multi-property declaration

Props = {
    MainTex_sampler: SamplerState,
    Tint: Color = Color(1.0, 1.0, 1.0, 1.0),
    LightDir: Vector3 = Vector3(0.0, 0.0, 1.0),
}

myVariable = "Hello, World!";

fn frag(Vector2 uv) {
    final = sample(uv.x, uv.y);
    return final;
};
```

## TODO
| **Task** | **Completed** |
| :------- | :-----------: |
| **Lexer** | ✅ |
| _Single-token_ Parsing | ✅ |
| _Lookahead(1)_ Parsing | ❌ |
| Compilation - _Expressions_ | ❌ |
| Compilation - _Assign_ | ❌ |
| Compilation - _Arrays_ | ❌ |
| Compilation - _Non-specific Types_ | ❌ |
| **Compiles fully into HLSL** | ❌ |
| **Tests** | ❌ |
| Compilation for Compute Shaders | ❌ |
| **Full Release** | ❌ |
