var express = require("express");
var formidable = require("formidable");
var fs = require('fs');
var util = require('util');

var app = express();

app.set('views', __dirname + '/tpl');
app.set('view engine', "jade");
app.engine('jade', require('jade').__express);
app.use(express.static(__dirname + '/public'));

app.get('/', function(req, res) {
	res.render('image');
});

var form = '<form action="/upload" enctype="multipart/form-data" method="post">'+
    	   '<input type="file" name="image"><br>'+
           '<input type="submit" value="Upload">'+
           '</form>';

app.get('/form', function (req, res) {
	res.writeHead(200, { 'Content-Type': 'text/html' });
	res.end(form);
});

var appListen = app.listen(8080);

app.post('/upload', function(req, res) {

	var form = new formidable.IncomingForm();
	form.uploadDir = __dirname + '/tempUpload'

	form.parse(req, function(err, fields, files) {
		if(!req.socket.destroyed) {

			if ( req.headers['user-agent'].indexOf('iOS') > (-1) ) {
				console.log('iOS');
				res.setHeader('Content-Type', 'text/json');
			} else {
				res.redirect("/form");
			}

			res.send();
			res.end();
		}

		if (!err) {
			fs.renameSync(files.image.path, __dirname + '/uploads/image.jpg');
		}

		io.sockets.emit('newImage', null);

		console.log("Parsing error: " + util.inspect(err));
		console.log("Parsing complete");
	});
	form.on('progress', function(bytesReceived, bytesExpected) {
		console.log(bytesReceived + '|' + bytesExpected);
		var maxBytes = 200*1024;
		if ((bytesExpected && bytesExpected > maxBytes) | (bytesReceived > maxBytes)) {
			res.status = 413;
        	res.send(413, 'Upload too large');
        	res.end();

			req.destroy();
			console.log('Request destroyed');
		}
	});
	form.on('close', function(){
		res.respond("Success!", 200);
    });
});

app.get('/uploads/:image', function(req, res) {
	fs.readFile(__dirname + '/uploads/' + req.params.image, function (err, data) {
		if (err) throw err;

		res.writeHead('200', {'Content-Type': 'image/jpeg'});
     	res.end(data, 'binary');
	});
});

//app.listen(8080);

/////

var io = require('socket.io').listen( appListen );
console.log("Listening on port " + 8080);

// 3 -> debug
io.set('log level', 3);

io.sockets.on('connection', function (socket) {
	console.log('Connected; sid: ' + socket.store.id)
	io.sockets.emit('connectionPing', null);

	socket.on('disconnect', function (socket) {
		console.log('Disconnected; sid: ' + this.id);
	});
});