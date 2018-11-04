var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");

//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";
//Robot time
var bot = new Discord.Client();
var quotes = ["*Blows Whistle* Rape!", "Slap it on with the might of Zeus", "Paula Dean is the reason all of my friends are dead!", "WHAT!? WHAT THE FUCK!?", "Man, 1910 times were scaaaaary!", "Cars...? Cars?! CAAAAAAARS!!!!! AND IIIIIIIII—HOLY SHIT!—WILL ALWAYS LOVE YOUICAN'TBELIEVEYOUDIDTHISTOMEGODDAMMITHOWCOULDYOUDOTHISTOME?!", "Good one, Bubsy! Hey, wanna be a cast member on Sat-purr-day Night Live? I know you'll make the MEOWST OF IT! [Suddenly distant] I'm leavin' ya, Bubsy!", "Good God, China! All about symbols! Couldn't even make the alphabet!"];
var len = quotes.length;
//var counter = 0;

bot.on("ready",() => {
  logger.info("Connected");
});
bot.on("message",msg => {	
	if(msg.author == bot.user){
		//future work maybe?
	}
	
	else{
		if (msg.content.includes(" JonTron ") || msg.content.includes("JonTron") || msg.content.includes("jontron") || msg.content.includes("Jontron") || msg.content.includes(" jontron ") || msg.content.includes(" Jontron ")){
			msg.channel.send(quotes[getRandomInt(len)]);
		}
	} 
});

function getRandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max));
}


bot.login(auth.token)
