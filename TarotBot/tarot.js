var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
var sleep = require('system-sleep');
const fs = require('fs');
const majorDir = fs.readdirSync('MajorArcana');
const fullDir = fs.readdirSync('FullDeck');
const dataDir = fs.readdirSync('data');

const { Client, Message, VoiceChannel, GatewayIntentBits, ChannelType, ApplicationCommandOptionType, InteractionType } = require('discord.js');
const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.GuildVoiceStates, GatewayIntentBits.MessageContent] });

//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";

client.on("ready",() => {
  logger.info("Connected");
});

client.on("messageCreate",msg => {	
	if(msg.content.includes("Give me a fortune") || msg.content.includes("give me a fortune") || msg.content.includes(" give me a fortune") || msg.content.includes(" give me a fortune")){
		var fileIndex = randint(dataDir.length-1);
		var fileName = "data/"+dataDir[fileIndex];
		const jsonString = fs.readFileSync(fileName, 'utf8');
		var card = JSON.parse(jsonString);  
		var imgFile = card.img_file;
		var imgloc = './FullDeck/'+imgFile;
		msg.channel.send({files: [imgloc]});
		sleep(1000);
		msg.channel.send(card.meaning);
	}
});

function randint(bound) {
	return Math.round(Math.random()*bound);
}

client.login(auth.token)
