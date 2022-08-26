using System;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Discord;
using Discord.Commands;
using Discord.WebSocket;
namespace MangaNotifier {
    class Program
    {
        public static void Main(string[] args) => new Program().MainAsync().GetAwaiter().GetResult();

        private DiscordSocketClient _client;

        private DB DB = new DB();

        //private Notifier notifier = new Notifier();

        private bool NotifyRunning = false;

        //private Time time = new Time();

        public async Task MainAsync()
        {
            _client = new DiscordSocketClient();
            ulong guildID = 792595734985048074;
            ulong botChannel = 792596945322770453;

            //time.TimeInit();

            _client.Log += Log;
           // _client.MessageReceived += ClientOnMessageReceived;
            _client.SlashCommandExecuted += SlashCommandHandler;
            _client.Ready += Client_Ready;

            var token = File.ReadAllText("auth.txt");
            await _client.LoginAsync(TokenType.Bot, token);

            //Thread timeThread = new Thread(new ThreadStart(time.ClearList));
            //timeThread.IsBackground = true;
            //timeThread.Start();
            //Notifier notifier = new Notifier();
            //Thread notifierThread = new Thread(() => notifier.StartNotifier(_client.GetGuild(guildID).GetTextChannel(botChannel)));
            //notifierThread.IsBackground = true;
            //notifierThread.Start();

            await _client.StartAsync();

            //ClearList();

            // Block this task until the program is closed.
            await Task.Delay(-1);
        }
        private static Task Log(LogMessage msg)
        {
            Console.WriteLine(msg.ToString());
            return Task.CompletedTask;
        }

        private static Task ClientOnMessageReceived(SocketMessage arg)
        {
            if (arg.Content.StartsWith("!helloworld"))
            {
                arg.Channel.SendMessageAsync($"User '{arg.Author.Username}' successfully ran helloworld!");
            }
            return Task.CompletedTask;
        }
        public async Task Client_Ready()
        {

            
            ulong guildId = 792595734985048074;

            var guildCommand = new SlashCommandBuilder()
                .WithName("sub")
                .WithDescription("subscribe to notifications for a series")
                .AddOption("user", ApplicationCommandOptionType.User, "The users whos roles you want to be listed", isRequired: true)
                .AddOption("series", ApplicationCommandOptionType.String, "The series to subscribe to", isRequired: true);
            var guildCommand2 = new SlashCommandBuilder()
                .WithName("unsub")
                .WithDescription("subscribe to notifications for a series")
                .AddOption("user", ApplicationCommandOptionType.User, "The users whos roles you want to be listed", isRequired: true)
                .AddOption("series", ApplicationCommandOptionType.String, "The series to unsubscribe to", isRequired: true);
            var guildCommand3 = new SlashCommandBuilder()
                .WithName("listseries")
                .WithDescription("List all series in database");
            var guildCommand4 = new SlashCommandBuilder()
                .WithName("newseries")
                .WithDescription("Add a new series to setup notifications for")
                .AddOption("baseurl", ApplicationCommandOptionType.String, "The url with out the -chapternumber", isRequired: true)
                .AddOption("title", ApplicationCommandOptionType.String, "Title of the series", isRequired: true)
                .AddOption("lastchapter", ApplicationCommandOptionType.String, "The last chapter available", isRequired: true);
            var guildCommand5 = new SlashCommandBuilder()
                .WithName("removeseries")
                .WithDescription("remove series from the database")
                .AddOption("title", ApplicationCommandOptionType.String, "The series to remove from the database PERMINENT", isRequired: true);
            try
            {
                await _client.Rest.CreateGuildCommand(guildCommand.Build(), guildId);
                await _client.Rest.CreateGuildCommand(guildCommand2.Build(), guildId);
                await _client.Rest.CreateGuildCommand(guildCommand3.Build(), guildId);
                await _client.Rest.CreateGuildCommand(guildCommand4.Build(), guildId);
                await _client.Rest.CreateGuildCommand(guildCommand5.Build(), guildId);

            }
            catch (Exception e)
            {
                //var json = JsonConvert.SerializeObject(exception.Error, Formatting.Indented);
                Console.WriteLine(e);
            }
            Console.WriteLine("starting notifier");
            ulong botChannel = 792596945322770453;
            Notifier notifier = new Notifier();
            Thread notifierThread = new Thread(() => notifier.StartNotifier(_client.GetGuild(guildId).GetTextChannel(botChannel)));
            notifierThread.IsBackground = true;
            notifierThread.Start();
        }
        private async Task SlashCommandHandler(SocketSlashCommand command)
        {
            if (command.CommandName == "sub")
            {
                await command.DeferAsync();
                var cmdData = command.Data.Options.ToArray();
                var user = cmdData[0].Value;
                //user = user.Replace("?", "");
                Console.WriteLine(user);
                string series = cmdData[1].Value.ToString();
                Console.WriteLine(series);
                DB.AddSubscriber(user.ToString(), series);
                await command.ModifyOriginalResponseAsync(msg => msg.Content = $"You executed {command.Data.Name}");
            }
            if(command.CommandName == "unsub")
            {
                await command.DeferAsync();
                var cmdData = command.Data.Options.ToArray();
                var user = cmdData[0].Value;
                //user = user.Replace("?", "");
                Console.WriteLine(user);
                string series = cmdData[1].Value.ToString();
                Console.WriteLine(series);
                DB.RemoveSubscriber(user.ToString(), series);
                await command.ModifyOriginalResponseAsync(msg => msg.Content = $"You executed {command.Data.Name}");
            }
            if(command.CommandName == "newseries")
            {
                await command.DeferAsync();
                var cmdData = command.Data.Options.ToArray();
                string baseUrl = cmdData[0].Value.ToString();
                string title = cmdData[1].Value.ToString();
                var lastChapter = cmdData[2].Value.ToString();
                Series newSeries = new Series();
                newSeries.BaseURL = baseUrl;
                newSeries.Title = title;
                newSeries.LastChapter = lastChapter;
                newSeries.Subscribers = new List<string>();
                DB.AddNewSeies(newSeries);
                await command.ModifyOriginalResponseAsync(msg => msg.Content = $"You executed {command.Data.Name}");
            }
            if(command.CommandName == "listseries")
            {
                await command.DeferAsync();
                List<Series> series = DB.GetAllSeries();
                string msgToSend = "";
                foreach(Series s in series)
                {
                    msgToSend += s.Title + "\n";
                }
                await command.ModifyOriginalResponseAsync(msg => msg.Content = msgToSend);
            }
            if(command.CommandName == "removeseries")
            {
                await command.DeferAsync();
                var cmdData = command.Data.Options.ToArray();
                var title = cmdData[0].Value.ToString();
                DB.RemoveSeries(title);
                await command.ModifyOriginalResponseAsync(msg => msg.Content = $"You executed {command.Data.Name}");
            }
   
        }
    }
}