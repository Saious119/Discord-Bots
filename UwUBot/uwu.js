var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var opus = require('opusscript');
var sleep = require('system-sleep');
const fs = require('fs');
const { exec } = require('child_process');

//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";
//Robot time
var bot = new Discord.Client();
var client = new Discord.Client();
var counter = 0;
var isReady = true;


bot.on("ready",() => {
  logger.info("Connected");
  voiceC = client.channels.find('name', 'General');
});
bot.on("message",msg => {	
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
			msg.channel.send("*Pounces on you, notices your buldge* OwO What's this? UwU");
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
				msg.guild.channels.find('name','nsfw').send("give me a couple minutes to search 4chan");
				//image();
				const dirs = fs.readdirSync('downloads');
				if(dirs.length < 2){
					msg.guild.channels.find('name','nsfw').send("Outta images UwU, gowin' to tha stowe");
					exec('./getImage.sh', (err, stdout, stderr) => {
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
				//msg.channel.send(imgloc);
				msg.guild.channels.find('name','nsfw').send("I found something", {files: [imgloc]}); 
				//msg.client.channels.get("486580756966277120").send("I found something", {files: [imgloc]});

				exec('rm -rf '+imgloc, (err, stdout, stderr) => {
					if (err) {
						console.error(`exec error: ${err}`);
						return;
				  	}
				
				  	console.log(`Number of files ${stdout}`);
				  	console.log(dirs.length);
				});
			
				msg.channel.send("I sent an image, pwobably UwU");
				//msg.guild.channels.find('name','nsfw').send("here you go");
				sleep(1000);
			}
		}
		else {
			counter--;
		}
		
	} 
});

function randint(bound) {
	return Math.round(Math.random()*bound);
}
/*
function sleep(milliseconds) {
  var start = new Date().getTime();
  for (var i = 0; i < 1e7; i++) {
    if ((new Date().getTime() - start) > milliseconds){
      break;
    }
  }
}
*/
/*
function image(){
	exec('./getImage.sh', (err, stdout, stderr) => {
		if (err) {
		  console.error(`exec error: ${err}`);
		  return;
		}
	  
		console.log(`Number of files ${stdout}`);
	});
	const dirs = fs.readdirSync('downloads');
	var fileIndex = randint(dirs.length-1);
	var imgFile = dirs[fileIndex];
	msg.channel.send("Hewwoooooo");
	//client.channels.get("486580756966277120").send("give me a couple minutes to search 4chan");

	exec('rm -r downloads/', (err, stdout, stderr) => {
		if (err) {
		  console.error(`exec error: ${err}`);
		  return;
		}
	  
		console.log(`Number of files ${stdout}`);
	});
}
*/

bot.login(auth.token)
