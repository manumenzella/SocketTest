// Twilio Credentials 
var accountSid = 'AC5041f0a00a14a6bb34007e0923329e8d'; 
var authToken = '8bb378dc4a98f0882c8e667e470462c2'; 
 
//require the Twilio module and create a REST client 
var client = require('twilio')(accountSid, authToken);

client.messages.create({ 
	to: "+543416252020", 
	from: "+15089162979", 
	body: "Hello there! This is from Node.JS",   
}, function(err, message) { 
	//console.log(message.sid);
	var util = require('util');
	console.log( util.inspect(err) );
	console.log( util.inspect(message) );
});