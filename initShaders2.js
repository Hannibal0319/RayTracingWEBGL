
// Get a file as a string using AJAX
function loadFileAJAX(name) {
    var xhr = new XMLHttpRequest(),
        okStatus = document.location.protocol === "file:" ? 0 : 200;
    xhr.open('GET', name, false);
    xhr.send(null);
    return xhr.status == okStatus ? xhr.responseText : null;
};

function loadShaderSourceRecursive(filePath, alreadyIncluded = {}) {
    if (alreadyIncluded[filePath]) {
        // Prevent infinite loops from circular includes
        return "";
    }
    alreadyIncluded[filePath] = true;

    let source = loadFileAJAX(filePath);
    if (!source) {
        alert("Could not find shader source: " + filePath);
        return null;
    }

    const includeRegex = /#include\s+"([^"]+)"/g;
    let match;
    const shaderDir = filePath.substring(0, filePath.lastIndexOf('/'));

    // Need to use a loop that re-evaluates the regex on the modified string
    while ((match = includeRegex.exec(source)) !== null) {
        const includePath = shaderDir + '/' + match[1];
        const includedSource = loadShaderSourceRecursive(includePath, alreadyIncluded);
        if (includedSource !== null) {
            source = source.replace(match[0], includedSource);
            // Reset regex lastIndex to re-run on the new source string
            includeRegex.lastIndex = 0;
        } else {
            console.error("Could not include shader file: " + includePath);
            // Continue without replacing, or handle error differently
        }
    }

    return source;
}


function initShaders(gl, vShaderName, fShaderName) {
    function getShader(gl, shaderName, type) {
        var shader = gl.createShader(type),
            shaderScript = loadShaderSourceRecursive(shaderName);
        if (!shaderScript) {
            // loadShaderSourceRecursive will show an alert
            return null;
        }
        gl.shaderSource(shader, shaderScript);
        gl.compileShader(shader);

        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            console.error("Shader compilation error in " + shaderName + ":");
            console.error(gl.getShaderInfoLog(shader));
            alert("Shader compilation failed. See console for details.");
            return null;
        }
        return shader;
    }
    var vertexShader = getShader(gl, vShaderName, gl.VERTEX_SHADER),
        fragmentShader = getShader(gl, fShaderName, gl.FRAGMENT_SHADER),
        program = gl.createProgram();

    if (!vertexShader || !fragmentShader) {
        return null;
    }

    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
        alert("Could not initialise shaders");
        return null;
    }

    
    return program;
};
