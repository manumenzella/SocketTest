window.onload = function() {
    var socket = io.connect('http://50.112.249.164:8080/');
    //var socket = io.connect('http://localhost:8080');

    var connectionTime;
    socket.on('connect', function() {
        connectionTime = new Date().getTime();
        var interval = setInterval( function() {
            var disconnectionTime = new Date().getTime();
            var lengthSec = (disconnectionTime - connectionTime) / 1000.0;
            console.log( 'connected for ' + Math.round(lengthSec) + ' seconds' );
        }, 1000);
        socket.on('disconnect', function() {
            clearInterval(interval);
        })
    });

    socket.on('connectionPing', function(data) {
        console.log('connection ping received');
    })

    socket.on('newImage', function(data) {
        console.log('new image');
        $("#image").attr("src", "/uploads/image.jpg?" + new Date().getTime());
    });
}
