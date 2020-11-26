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
//var client = new Discord.Client();
var counter = 0;
var isReady = true;

bot.on("ready",() => {
  logger.info("Connected");
});

var images = ["bagel1.jpg", "bagel2.jpg", "bagel3.jpg", "matzo1.jpg", "matzo2.jpg", "bagel4.jpg","bagel5.jpg", "matzo3.jpg", "matzo4.jpg", "matzo5.jpg"];
var leng = images.length;
bot.on("message",msg => {	
	if(msg.author == bot.user){
		//react to all message here
	}
	
	else{
		if(msg.content.includes("Give me a fortune") || msg.content.includes("give me a fortune") || msg.content.includes(" give me a fortune") || msg.content.includes(" give me a fortune")){
      var fileIndex = randint(dirs.length-1);
			var imgFile = dirs[fileIndex];
			var imgloc = './downloads/'+imgFile;
      msg.channel.send({files: [imgloc]});
      if(imgFile == "TheWorld.png"){
        msg.channel.send("This card represents Assured success and destiny, it also hints at travel and voyage, this is a very good card that insinuates that you will do great things and that your dreams will come true.");
      }
			//msg.guild.channels.find('name','nsfw').send("I found something", {files: [imgloc]}); 
          
    }
  }
});

function randint(bound) {
	return Math.round(Math.random()*bound);
}

bot.login(auth.token)