//var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var opus = require('opusscript');
var sleep = require('system-sleep');
const fs = require('fs');
const { exec } = require('child_process');
//const { channel } = require("diagnostic_channel");
const { Client, Intents } = require('discord.js');
const client = new Client({ intents: [Intents.FLAGS.GUILDS, Intents.FLAGS.GUILD_MESSAGES] });
//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";
//Robot time
//var bot = new Client({ intents: [Intents.FLAGS.GUILDS, Intents.FLAGS.GUILD_MESSAGES] });
//var client = new Discord.Client();
var counter = 0;
var isReady = true;


client.on("ready",() => {
  logger.info("Connected");
  //voiceC = client.channels.find('name', 'General');
});
bot.on("message", async msg => {	
	var NSFW_Channel = msg.guild.channels.cache.find(NSFWch => NSFWch.name === 'nsfw');
	var voiceC = msg.guild.channels.cache.find(Voice => Voice.name === 'General');
	//NSFW_Channel.send("HERE!!!!");
	if(msg.author == bot.user){
		//msg.react('OwO')
		//msg.channel.send("UwU");
	}
	else{
		if(msg.content.includes("sugma") || msg.content.includes("chokonma")|| msg.content.includes("boffa")){
			msg.channel.send("no UwU");
		}
		else if(msg.content.includes("UwUBot help") || msg.content.includes("UwUBot what can you do")){
			msg.channel.send("I can do wots of thingy wingys, wike:");
			msg.channel.send("UwUify <statement> : make yoo woods kawaii UwU");
			msg.channel.send("Woice chat : go to tha Genewaw woice chat and send me what you wanna hewe UwU");
			msg.channel.send("		ASMR");
			msg.channel.send("		UwUBot are you drunk?");
			msg.channel.send("		nuggs");
			msg.channel.send("		UwUBot sing me some country music");
			msg.channel.send("		ASMR");
			msg.channel.send("		UwUBot rap");
			msg.channel.send("ask for an image or picture by saying image or picture OwO");
			msg.channel.send("ok bye. UwU.");
		}
		else if(msg.content.includes("UwUsend") || msg.content.includes("uwusend")){
			var msgSplit = msg.content.split(" ");
			if(msgSplit.length < 4){
				msg.channel.send("Pweese use da fowmat \'UwUsend <guildID> <channel ID> message\' k thx UwU");
			}
			var guildID = msgSplit[1]
			var channelID = msgSplit[2];
			var messageToSend = msgSplit[3];
			for(var i = 3; i < msgSplit.length; i++){
				messageToSend += msgSplit[i];
			}
			client.guilds.fetch(guildID).then(guild => guild.channels.fetch(channelID).then(channel => channel.send(messageToSend)));
		}
		else if(msg.content.includes("UwUify")||msg.content.includes(" UwUify ")){//||msg.content.includes(" ")){
			var cont = msg.content;
			var uwu1 = cont.replace("l","w");
			//var uwu2 = uwu1.replace("L","W");
			//msg.channel.send(uwu2);
			for(var i=0;i<cont.length;i++){
				uwu1=uwu1.replace("l","w");
				uwu1=uwu1.replace("L","W");
				uwu1=uwu1.replace("er","a");
				uwu1=uwu1.replace("er","a");
				uwu1=uwu1.replace("r","w");
				uwu1=uwu1.replace("R","W");
			}
			msg.channel.send(uwu1+" UwU");
		}
		else if(msg.content.includes("ASMR")){
			msg.channel.send("Pwease go to tha Genewaw woice chat. UwU");
			var voiceChannel = msg.member.voiceChannel;
			voiceChannel.join().then(connection =>
			{
				const dispatcher = connection.playFile('/home/andym/Discord-Bots/UwUBot/ASMR.mp3');
				dispatcher.on("end", end => {
					voiceChannel.leave();
				});
			}).catch(err => console.log(err));
			isReady = true;
		}
		else if(msg.content.includes("UwUBot are you drunk?")){
			msg.channel.send("Pwease go to tha Genewaw woice chat. UwU");
			var voiceChannel = msg.member.voiceChannel;
			voiceChannel.join().then(connection =>
			{
				const dispatcher = connection.playFile('/home/andym/Discord-Bots/UwUBot/drunk.mp3');
				dispatcher.on("end", end => {
					voiceChannel.leave();
				});
			}).catch(err => console.log(err));
			isReady = true;
		}
		else if(msg.content.includes("nuggets") || msg.content.includes("nuggs")){
			msg.channel.send("Pwease go to tha Genewaw woice chat. UwU");
			var voiceChannel = msg.member.voiceChannel;
			voiceChannel.join().then(connection =>
			{
				const dispatcher = connection.playFile('/home/andym/Discord-Bots/UwUBot/theMcnugRap.mp3');
				dispatcher.on("end", end => {
					voiceChannel.leave();
				});
			}).catch(err => console.log(err));
			isReady = true;
		}
		else if(msg.content.includes("UwUBot sing me some country music")){
			msg.channel.send("Pwease go to tha Genewaw woice chat. UwU");
			var voiceChannel = msg.member.voiceChannel;
			voiceChannel.join().then(connection => 
			{
				const dispatcher = connection.playFile('/home/andym/Discord-Bots/UwUBot/countryroads.mp3');
				dispatcher.on("end", end => {
					voiceChannel.leave();
				});
			}).catch(err => console.log(err));
			isReady = true;
		}
		else if(msg.content.includes("UwUBot rap")){
			msg.channel.send("Pwease go to that Genewaw woice chat. UwU");
			var voiceChannel = msg.member.voiceChannel;
			voiceChannel.join().then(connection =>
			{
				const dispatcher = connection.playFile('/home/andym/Discord-Bots/UwUBot/rap.mp3')
				dispatcher.on("end",end => {
					voiceChannel.leave();
				});
			}).catch(err => console.log(err));
			isReady = true;
		}
		else if(msg.content.includes("UwU Bot what are your voice options?")){
			msg.channel.send("ASMR, nuggets, UwU Bot sing me country music, UwU Bot Rap, UwU Bot are you drunk?");
			msg.channel.send("UwU");
		}
		else if (randint(13) == 2){
			msg.channel.send("*Pounces on you, notices your buldge* OwO, what's this? UwU");
		}
		else if(randint(25) == 2){
			msg.channel.send("*REEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE*");
			msg.channel.send("UwU");
		}
		else if (msg.content.includes(" is ") || msg.content.includes("'s ")){
		//	msg.react('UwU')
			if(randint(16) == 2){
				msg.channel.send("UwU What's this? A MAnthony Foot?");
			}
			else{
				msg.channel.send("UwU what's this? "+msg.author);
				//sleep(5000);
			}
			if(counter == 0){ counter = randint(10)+5;}
		}
		else if(msg.content.includes("UwU Bot") || msg.content.includes(" UwU Bot ")){
                        msg.channel.send("*Is nervous* H-Hewwo UwU");
			//sleep(5000);
                }
		else if(msg.content.includes(" anime ") || msg.content.includes(" anime's ")){
		//	msg.react('UwU')
			msg.channel.send("OwO what's this? "+msg.author);
			//sleep(5000);
			if(counter == 0){ counter = randint(10)+5;}
		}
		else if(msg.content.includes(" UwU ") || msg.content.includes("UwU")){
	//		msg.react('UwU')
			msg.channel.send("Uwufu desu "+msg.author);
			//sleep(5000);
			if(counter == 0){ counter = randint(10)+5;}	
		}
		else if(msg.content.includes("Fuck") || msg.content.includes(" fuck ") || msg.content.includes(" fucking ") || msg.content.includes("Fucking") || msg.content.includes("fuck")){
			msg.channel.send("Oopsie woopsie, looks like we made a little fuckey wuckey, a little fucko boingo UwU");
			//sleep(5000);
			if(counter == 0){counter = randint(10)+5;}
		}
        	else if(msg.content.includes(" woops ") || msg.content.includes("Woops") || msg.content.includes("woops") || msg.content.includes("whoops") || msg.content.includes("Whoops")){
            		msg.channel.send("Oopsie woopsie UwU! It UwU looks like UwU I've dropped UwU some UwUs all over the UwU place UwU");
			//sleep(5000);
       		}
		else if(msg.content.includes("Hey")|| msg.content.includes("hey")){
			msg.channel.send("Pwease give me huggie wuggies "+msg.author);
			msg.channel.send("UwU");
			//sleep(5000);
		}
		else if(msg.content.includes("Cute") || msg.content.includes("cute") || msg.content.includes(" cute ")){
			msg.channel.send("*Pounces on you* OwO What's this? *Notices your bulge*");
			//sleep(5000);
		}
		else if(msg.author.username === "Isabelle"){
			msg.channel.send("H-Hewwo IsaBewwe UwU");
			//sleep(5000);
		}
		else if(msg.content.includes("image") || msg.content.includes("picture") || msg.content.includes(" image ") || msg.content.includes(" picture ") || msg.content.includes("Image")){
			var msgSplit = msg.content.split(" ");
			var numImg = 1;
			if(msgSplit.length > 1){
				numImg = parseInt(msgSplit[1]);
			}
			msg.channel.send("pwease wook in nsf-doub-UwU");
			for(var i = 0; i < numImg; i++){
				//msg.guild.channels.find('name','nsfw').send("give me a couple minutes to search 4chan");
				//var NSFW_Channel = await msg.guild.channels.find(NSFWch => NSFWch.name === 'nsfw');
				NSFW_Channel.send("give me a couple minutes to search 4chan");
				var imgloc = await getImage(NSFW_Channel);
				if(imgloc != null){
					console.log("Image found!");
					await NSFW_Channel.send("I found something", {files: [imgloc]});
					sleep(2000);
				}
				var removeImageStatus = await removeImage(imgloc);
				if(removeImageStatus == 0){
					console.log("removing image successful");
				}
				sleep(1000);
			}
		}
		else {
			/*
			var membersInCaac = msg.guild.channels.find(c => c.name === 'caac');
			var caacTextChat = msg.guild.channels.find(ctc => ctc.name === 'caac-only'); 
			console.log("Found message");
			if(msg.channel == caacTextChat){
				console.log("in caac only");
				console.log(membersInCaac.members);
				var found = false;
				for(var item in membersInCaac.members){
					//console.log(item);
					if(msg.author == item.user.username){
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
			*/
			counter--;
		}
		
	} 
});

async function getImage(NSFW_Channel){
	const dirs = fs.readdirSync('downloads');
	if(dirs.length < 2){
		NSFW_Channel.send("Outta images UwU, gowin' to tha stowe");
		//msg.guild.channels.find(NSFWch => NSFWch.name === 'nsfw').send("Outta images UwU, gowin' to tha stowe");
		exec('./getImage.sh', function (err, stdout, stderr) {
			if (err) {
				console.error(`exec error: ${err}`);
				return;
			}  
			console.log(`Number of files ${stdout}`);
		});
		sleep(240*1000);
	}
	//const dirs = fs.readdirSync('downloads');
	var fileIndex = randint(dirs.length-1);
	var imgFile = dirs[fileIndex];
	var imgloc = './downloads/'+imgFile;
	return imgloc;
}

async function removeImage(imgloc){
	const dirs = fs.readdirSync('downloads');
	exec('rm -rf '+imgloc, function (err, stdout, stderr) {
		if (err) {
			console.error(`exec error: ${err}`);
			return;
		}
		console.log(`Number of files ${stdout}`);
		console.log(dirs.length);
	});
	return 0;
}

function randint(bound) {
	return Math.round(Math.random()*bound);
}

client.login(auth.token)
