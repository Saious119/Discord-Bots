var Discord = require("discord.js");
var logger = require("winston");
var auth = require("./auth.json");

const { Client, Message, VoiceChannel, GatewayIntentBits, ChannelType, ApplicationCommandOptionType, InteractionType } = require('discord.js');
const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.GuildVoiceStates, GatewayIntentBits.MessageContent] });
//Logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
  colorize : true
});
logger.level = "debug";
//Robot time
//WARNING: SOME CONTENT IS OFFENSIVE, NO CONTRIBUTOR SUPPORTS TERRY DAVIS' POLITICAL VIEWS (we do find it funny and iconic to his character though)
var quotes = ["I'm the best programmer to ever live, I'm better than anyone else before me.","It's either N!@@*rlisious or Divine Intellect","7-bit signged ASCII is retarded","N*$@!rlishous","Yeah, I killed a CIA n%#$%! with my car in 1999. Score one for the good guys.", "The CIA has a seven-year-old deepthoating a 45 at DMV next to me fucking with me. I'll teach him to pull the trigger", "What color should I choose? Let's see my floors are brown...God's favorite color is cyan.", "Proffesonals write their own Compilers", "Go download my 2MB Distro at http://www.templeos.org/ now on http://mirror.clarkson.edu/templeos/ !!!", "Why can you do it? Cause fuck yeah that's why!", "It's those fuckin' glow in the dark C.I.A N$@!&%s"];
var len = quotes.length;
//var counter = 0;

client.on("ready",() => {
  logger.info("Connected");
});
client.on("messageCreate",async msg => {
	if (msg.content.includes(" Terry Davis ") || msg.content.includes("Terry Davis") || msg.content.includes("terry davis") || msg.content.includes(" terry davis ")){
		try{
			msg.channel.send(quotes[getRandomInt(len)]);
		}
		catch(e){
			console.log(e);
		}
	} 
});

function getRandomInt(max) {
  return Math.floor(Math.random() * Math.floor(max));
}


client.login(auth.token)
