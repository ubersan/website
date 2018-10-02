const functions = require('firebase-functions');
const express = require('express');
var consolidate = require('consolidate');
var fs = require('fs');
var path = require('path');

const app = express();
app.engine("hbs", consolidate.handlebars);
app.set("view engine", "hbs");
app.set('views', './views');

app.get('/', (req, res) => {
    fs.readFile('./meshes/suzanne.obj', (err, data) => {
        if (err) {
            throw err
        };
      });
    /*res.render('index.hbs', {
        title: 'My About Title Page'
    });*/
    res.sendFile(__dirname + '/test.html');
});

app.get('/data', (req, res) => {
    res.send('this is a test response from the backend 2');
})

exports.app = functions.https.onRequest(app);