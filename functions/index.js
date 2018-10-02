const functions = require('firebase-functions');
const express = require('express');
var consolidate = require('consolidate')

const app = express();
app.engine("hbs", consolidate.handlebars);
app.set("view engine", "hbs");
app.set('views', './views');

app.get('/', (req, res) => {
    res.render('index.hbs');
});

exports.app = functions.https.onRequest(app);