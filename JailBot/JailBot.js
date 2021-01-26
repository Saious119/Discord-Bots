var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var sleep = require('system-sleep');


//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";
//Robot time
var bot = new Discord.Client();
//var client = new Discord.Client();
var counter = 0;
var isReady = true;

bot.on("ready",() => {
  logger.info("Connected");
});

bot.on("message",msg => {	
	if(msg.author == bot.user){
		//react to all message here
	}	
	else{
		if(msg.content.includes("UwU") || msg.content.includes("OwO") || msg.content.includes("UwUBot") || msg.content.includes("image") || msg.content.includes("nuggs") || msg.content.includes("ASMR")){
			let cringerole = msg.guild.roles.get("793708658345246730");
			let member = msg.member;
			if(member.roles.has(cringerole)) {
				console.log("Silence inmate!");
			} else {
				msg.channel.send(msg.author+"");
				msg.channel.send("Cringe Detected:");
				sleep(5*1000);
				//let member = msg.member;
				member.addRole(cringerole).catch(console.error);
				msg.channel.send("You have interacted with the Cringe UwUBot, you are now Cringe for 1 minute");
				sleep(60*1000);
				member.removeRoles(cringerole).catch(console.error);
				sleep(5*1000);
				msg.channel.send(msg.author + " has been freed from the prison that is cringe, I wish you a sucessful rehabilitation back into society");
				sleep(5*1000);
			}	
    	}
  	}
});

function randint(bound) {
	return Math.round(Math.random()*bound);
}

bot.login(auth.token)
