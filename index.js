var express = require("express");
var colors = require("colors");
var port = 3700;

var app = express();

app.set('views', __dirname + '/tpl');
app.set('view engine', "jade");
app.engine('jade', require('jade').__express);
app.get("/", function(req, res){
    res.render("page");
});
app.use(express.static(__dirname + '/public'));

var io = require('socket.io').listen( app.listen(port) );
console.log("Listening on port " + port);

// 3 -> debug
io.set('log level', 3);

// Very harsh heartbeat settings
io.set('heartbeat interval', 12);
io.set('heartbeat timeout', 20);
io.set('close timeout', 20);

var RedisStore = require('socket.io/lib/stores/redis')
  , redis  = require('socket.io/node_modules/redis')
  , pub    = redis.createClient()
  , sub    = redis.createClient()
  , client = redis.createClient();

io.set('store', new RedisStore({
  redisPub : pub
, redisSub : sub
, redisClient : client
}));

io.sockets.on('connection', function (socket) {
	  console.log('Connected; sid: '.blue + socket.store.id.red)
    socket.emit('message', { message: 'Welcome to the chat' });

    socket.set('nickname', 'thisIsANickname', function() {
        //socket.emit('message', { message: 'The nickname has been set' });
    });

    socket.broadcast.emit('message', { message: 'A new user has joined! ' + socket.store.id } );

    //socket.on('send', function (data) {
    //    io.sockets.emit('message', data);
    //});

    socket.on('send', function(data, fn) {
        io.sockets.emit('message', data);
        if (fn && typeof(fn) == 'function') {
            fn('success');
            socket.get('nickname', function(error, data) {
                console.log('Nickname: ' + data);
            });
        }
    });

    socket.on('disconnect', function (socket) {
		    console.log('Disconnected; sid: '.blue + this.id.red);
	  });
});