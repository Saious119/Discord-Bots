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
//WARNING: SOME CONTENT IS OFFENSIVE, NO CONTRIBUTOR SUPPORTS TERRY DAVIS' POLITICAL VIEWS (we do find it funny and iconic to his character though)
var quotes = ["What color should I choose? Let's see my floors are brown...God's favorite color is cyan.", "Proffesonals write their own Compilers", "Go download my 2MB Distro at http://www.templeos.org/", "Why can you do it? Cause fuck yeah that's why!", "It's those fuckin' C.I.A N$@!&%s"];
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
		if (msg.content.includes(" Terry Davis ") || msg.content.includes("Terry Davis") || msg.content.includes("terry davis") || msg.content.includes(" terry davis ")){
			msg.channel.send(quotes[getRandomInt(len)]);
		}
	} 
});

function getRandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max));
}


bot.login(auth.token)
