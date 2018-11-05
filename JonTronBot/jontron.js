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
var quotes = ["I'm a brave boy .... NOT A BRAVE ENOUGH BOY FOR THIS!", "Now we're getting into some deep shit I don't know if I'm ready for that, also WHAT WHAT WHAT WHAAT!", "*Blows Whistle* Rape!", "Slap it on with the might of Zeus", "Paula Dean is the reason all of my friends are dead!", "WHAT!? WHAT THE FUCK!?", "Man, 1910 times were scaaaaary!", "Cars...? Cars?! CAAAAAAARS!!!!! AND IIIIIIIII—HOLY SHIT!—WILL ALWAYS LOVE YOUICAN'TBELIEVEYOUDIDTHISTOMEGODDAMMITHOWCOULDYOUDOTHISTOME?!", "Good one, Bubsy! Hey, wanna be a cast member on Sat-purr-day Night Live? I know you'll make the MEOWST OF IT! [Suddenly distant] I'm leavin' ya, Bubsy!", "Good God, China! All about symbols! Couldn't even make the alphabet!", "Oh, you got me Monopoly this year? For the Nintendo 64? Well, this would have been great back in 1864. Y'know, when it was impressive just to not die from being 35.", "Of course, don't forget everyone's favourite crime-fighting alliance, Sense of Right! Everyone's here: Batman, Superman, Shhhrek, a caarrr…ooohh nooo…", "9 is the maximum life you can get.", "I DON'T EVEN CARE.....I care immenseley"];
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
