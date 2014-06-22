var express = require("express");
var formidable = require("formidable");
var fs = require('fs');
var util = require('util');

var app = express();

app.get('/get', function (req, res) {
    fs.readFile(__dirname + '/locationData.txt', function (err, data) {
        if (err) throw err;

        res.writeHead('200', {'Content-Type': 'text/plain'});
        res.end(data);
    });
});

app.get('/map', function (req, res) {
	fs.readFile(__dirname + '/locationData.txt', 'utf-8', function (err, data) {
		var lines = data.trim().split('\n');
		var lastLine = lines.splice(-1)[0];
		var location = /<(.*?)>/g.exec(lastLine)[1];
		var coordinates = location.split(',');
		var lat = coordinates[0];
		var lon = coordinates[1];
		var url = "https://www.google.com/maps/preview#!q=" + lat + "%2C" + lon;

		res.redirect(url);
	});
});

app.get('/clear', function(req, res) {
        fs.writeFile(__dirname + '/locationData.txt', '', function() {
                res.writeHead('200', {'Content-Type': 'text/plain'});
                res.end('Done');
        });
});

app.post('/post', function (req, res) {

        console.log("POST");

        var form = new formidable.IncomingForm();
        form.parse(req, function(err, fields, files) {
                fs.appendFile(__dirname + '/locationData.txt', fields['data']);
                console.log(util.inspect(fields));
                res.end();
        });
        form.on('close', function(){
                res.respond("Success!", 200);
    });
});

app.listen(7400);