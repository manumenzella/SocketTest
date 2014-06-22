window.onload = function() {
 
    var messages = [];
    var socket = io.connect('http://50.112.249.164:3700/');
    //var socket = io.connect('http://localhost:3700');
    var field = document.getElementById("field");
    var sendButton = document.getElementById("send");
    var content = document.getElementById("content");
    var name = document.getElementById("name");
 
    $(document).ready(function() {
        $("#flasher").fadeOut('slow');
    })

    socket.on('message', function (data) {
        if(data.message) {
            messages.push(data);
            var html = '';
            for(var i=0; i<messages.length; i++) {
                html += '<b>' + (messages[i].username ? messages[i].username : 'Server') + ': </b>';
                //html += messages[i].message + '<br />';
                html += messages[i].message;
                html += (messages[i].socketID ? '&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#AAA">' + messages[i].socketID + '</span>' : '') + '<br />'; 
            }
            content.innerHTML = html;
            content.scrollTop = content.scrollHeight;
        } else {
            console.log("There is a problem: ", data);
        }
    });

    socket.on('disconnect', function () {
        content.innerHTML = "CONNECTION FAILED";
    });
 
    sendButton.onclick = sendMessage = function() {
        if(name.value == "") {
            alert("Please type your name!");
            name.focus();
        } else {
            //socket.emit('send', { message: field.value, username: name.value, socketID: socket.socket.sessionid });
            socket.emit('send', { message: field.value, username: name.value, socketID: socket.socket.sessionid }, function(data) {
                if (data == 'success') {
                    $("#flasher").fadeIn('fast').fadeOut('slow');
                }
            });
            field.value = '';
            field.focus();
        }
    };

    $(document).ready(function() {
        $("#field").keyup(function(e) {
            if(e.keyCode == 13) {
                sendMessage();
            }
        });
    });
}