var app = Elm.Main.init({
    node: document.getElementById('elm-node')
});

app.ports.loadedMesh.send(read_obj_file());

function read_obj_file() {
    return 'from obj function';
}

function test_out() {
    console.log('test-out');
}