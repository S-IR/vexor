package shader


cubeVertexSource := `#version 460 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 instanceOffset;
layout (location = 2) in vec3 instanceColor;

out vec3 ourColor;


uniform mat4 view;
uniform mat4 projection;

void main() {
    mat4 model =  mat4(
    1.0, 0.0, 0.0, 0,
    0.0, 1.0, 0.0, 0,
    0.0, 0.0, 1.0, 0,
    instanceOffset.x, instanceOffset.y, instanceOffset.z, 1.0
    );
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    ourColor = instanceColor;
}
`


cubeFragmentSource := `#version 460 core
out vec4 FragColor;
in vec3 ourColor;

void main() {
    FragColor = vec4(ourColor, 1.0);
}
`


// vertexShaderSource := `#version 460 core
// layout (location = 0) in vec3 aPos;
// layout (location = 1) in vec2 aTexCoord;
// out vec2 TexCoord;

// uniform mat4 model;
// uniform mat4 view;
// uniform mat4 projection;

// void main() {
//     gl_Position = projection * view * model * vec4(aPos, 1.0);
//     TexCoord = vec2(aTexCoord.x, aTexCoord.y);
// }`


// fragmentShaderSource := `#version 460 core
// out vec4 FragColor;
// in vec2 TexCoord;
// uniform sampler2D texture1;
// uniform sampler2D texture2;

// uniform vec3 lightColor;
// uniform vec3 objectColor;

// void main() {
//  FragColor = vec4(lightColor * objectColor, 1.0);
// }`
