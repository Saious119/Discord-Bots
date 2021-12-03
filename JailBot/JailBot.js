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

bot.on("message", async msg => {
	var membersInCaac = msg.guild.channels.cache.find(c => c.name === 'caac');
	var caacTextChat = msg.guild.channels.cache.find(ctc => ctc.name === 'caac-only'); 
	console.log("Found message");
	if(msg.channel == caacTextChat){
		console.log("in caac only");
		console.log(membersInCaac.members);
		var found = false;
		for([memberID, member] in membersInCaac.members){
			console.log("what bruh");
			console.log(member.user.username);
			if(msg.author.username == member.user.username){
				found = true;
				console.log("found author");
			}
		}
		if(!found){
			console.log("removing");
			msg.delete().then(msg => console.log(`Deleted message from ${msg.author.username}`)).catch(console.error); //Supposed to delete message
			console.log("removed");
		}
	}	
	if(msg.author == bot.user){
		//react to all message here
	}	
	else{
		if(msg.content.includes("UwU") || msg.content.includes("OwO") || msg.content.includes("UwUBot") || msg.content.includes("image") || msg.content.includes("nuggs") || msg.content.includes("ASMR")){
			//let cringerole = msg.guild.roles.get("793708658345246730");
			let cringerole = await msg.guild.roles.find(r => r.name === "Cringe");
			console.log("@ing user");
			let member = msg.mentions.members.first();
			msg.channel.send(msg.author+"");
			let usera = msg.author;
			msg.channel.send("Cringe Detected:");
			//let member = msg.member;
			if(msg.guild.roles.has(r => r.name === "Cringe")) {
				console.log("Silence inmate!");
			} else {
				sleep(5*1000);
				//let member = msg.member;
				msg.author.roles.addRole(cringerole).catch(console.error);
				msg.channel.send("You have interacted with the Cringe UwUBot, you are now Cringe for 1 minute");
				sleep(60*1000);
				msg.member.roles.removeRole(cringerole).catch(console.error);
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
