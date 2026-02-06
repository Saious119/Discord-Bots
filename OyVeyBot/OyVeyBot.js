var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");
const { AttachmentBuilder, EmbedBuilder } = require('discord.js');

//discord v14 stuff
const { Client, Message, VoiceChannel, GatewayIntentBits, ChannelType, ApplicationCommandOptionType, InteractionType } = require('discord.js');
const client = new Discord.Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.GuildVoiceStates, GatewayIntentBits.MessageContent] });

//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";

client.on("ready", async () => {
  logger.info("Connected");
});

var images = ["bagel1.jpg", "bagel2.jpg", "bagel3.jpg", "matzo1.jpg", "matzo2.jpg", "bagel4.jpg","bagel5.jpg", "matzo3.jpg", "matzo4.jpg", "matzo5.jpg"];
var leng = images.length;
client.on("messageCreate", async msg => {
  if(msg.content.includes("Oy vey") || msg.content.includes("oy vey") || msg.content.includes(" oy vey ") || msg.content.includes(" oy vey") || msg.content.includes("Oy Vey")){
    var randomOyVey = randint(leng);
    msg.channel.send("Let me comfort you");
    var imgToSend = "./"+[images[randomOyVey]];
    const img = new AttachmentBuilder(imgToSend);
    const imageEmbed = new EmbedBuilder()
      .setImage('attachment://'+imgToSend);
    msg.channel.send({ embeds: [imageEmbed], files: [img] });
  }
});

function randint(bound) {
	return Math.round(Math.random()*bound);
}

client.login(auth.token)
