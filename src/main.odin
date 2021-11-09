package main

import    "vendor:glfw"
import gl "vendor:opengl"
import    "core:fmt"
import    "core:os"
import    "core:mem"

main :: proc() {
    glfw.Init()
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CLIENT_API, glfw.OPENGL_API)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)

    WIDTH  :: 800
    HEIGHT :: 600

    window := glfw.CreateWindow(WIDTH, HEIGHT, "Triangle", nil, nil)
    defer glfw.DestroyWindow(window)
    if window == nil {
        fmt.panicf("Failed to create a window!\n")
    }

    glfw.MakeContextCurrent(window)

    gl.load_up_to(
        3, 3, 
        proc(p: rawptr, name: cstring) {
            (cast(^rawptr)p)^ = glfw.GetProcAddress(name)
        },
    )

    gl.Viewport(0, 0, WIDTH, HEIGHT)
    glfw.SetFramebufferSizeCallback(
        window, 
        cast(glfw.FramebufferSizeProc)proc "c" (window: ^glfw.WindowHandle, width, height: i32) {
            gl.Viewport(0, 0, width, height)
        },
    )

    vertex_data :: []f32{
        //  Vertices           Colors
        -0.5, -0.5,  0.0,   1.0, 0.0, 0.0,
         0.5, -0.5,  0.0,   0.0, 1.0, 0.0,
         0.0,  0.5,  0.0,   0.0, 0.0, 1.0,
    }

    vbo: u32
    gl.GenBuffers(1, &vbo)

    vao: u32
    gl.GenVertexArrays(1, &vao)

    gl.BindVertexArray(vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertex_data) * size_of(f32), raw_data(vertex_data), gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), cast(rawptr)cast(uintptr)0)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), cast(rawptr)cast(uintptr)(3 * size_of(f32)))
    gl.EnableVertexAttribArray(1)

    compile_shader :: proc(path: string, shader_type: u32) -> u32 {
        source, ok := os.read_entire_file(path)
        if !ok {
            fmt.panicf("Failed to read file!")
        }

        shader := gl.CreateShader(shader_type)

        gl.ShaderSource(shader, 1, raw_data([]cstring{ cstring(raw_data(source)) }), nil)
        gl.CompileShader(shader)

        success: i32
        gl.GetShaderiv(shader, gl.COMPILE_STATUS, transmute([^]i32)&success)

        if success == 0 {
            log_len: i32
            gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, transmute([^]i32)&log_len)

            buf, _ := mem.make([dynamic]u8, log_len)

            gl.GetShaderInfoLog(shader, log_len, nil, raw_data(buf))
            fmt.panicf("\n\tShader Compilation Failed:\n{}", cstring(raw_data(buf)))
        }

        return shader
    }

    create_program :: proc(vert_shader, frag_shader: u32) -> u32 {
        program := gl.CreateProgram()
        
        gl.AttachShader(program, vert_shader)
        defer gl.DetachShader(program, vert_shader)
        gl.AttachShader(program, frag_shader)
        defer gl.DetachShader(program, frag_shader)

        gl.LinkProgram(program)

        is_linked: i32
        gl.GetProgramiv(program, gl.LINK_STATUS, transmute([^]i32)&is_linked)
        if is_linked == 0 {
            log_len: i32
            gl.GetProgramiv(program, gl.INFO_LOG_LENGTH, transmute([^]i32)&is_linked)

            buf, _ := mem.make([dynamic]u8, log_len)

            gl.GetProgramInfoLog(program, log_len, nil, raw_data(buf))
            fmt.panicf("\n\tShader Program Creation Failed:\n{}", cstring(raw_data(buf)))
        }

        return program
    }

    vertex_shader := compile_shader("../shaders/shader.vert", gl.VERTEX_SHADER)
    defer gl.DeleteShader(vertex_shader)
    fragment_shader := compile_shader("../shaders/shader.frag", gl.FRAGMENT_SHADER)
    defer gl.DeleteShader(fragment_shader)

    program := create_program(vertex_shader, fragment_shader)
    defer gl.DeleteProgram(program)

    process_input :: proc(window: glfw.WindowHandle) {
        if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
            glfw.SetWindowShouldClose(window, true)
        }
    }

    for glfw.WindowShouldClose(window) != 1 {
        process_input(window)
        
        gl.ClearColor(0.0, 0.0, 0.0, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.UseProgram(program)
        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, 3)

        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}