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

class Program
{
    public static void Main(string[] args) => new Program().MainAsync().GetAwaiter().GetResult();

    private DiscordSocketClient _client;

    private string cockEmote {get; set;}

    private string tinyCock {get; set;}

    private string bigCock { get; set;}

    private Time time = new Time();

    public async Task MainAsync()
    {
        _client = new DiscordSocketClient();

        time.TimeInit();
        
        cockEmote = "<:cock:899135029190475826>";
        tinyCock = "<:tinycock:1153862591983132712>";
        bigCock = "BigCock";

        _client.Log += Log;
        _client.MessageReceived += ClientOnMessageReceived;
        _client.MessageReceived += CockRecieved;

        var token = File.ReadAllText("auth.txt");

        Thread timeThread = new Thread(new ThreadStart(time.ClearList));
        timeThread.IsBackground = true;
        timeThread.Start();
        await _client.LoginAsync(TokenType.Bot, token);
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
    private Task CockRecieved(SocketMessage arg)
    {
        Emote.TryParse(cockEmote, out var cock);
        Emote.TryParse(tinyCock, out var tinycock);
        if(arg.Content == cock.ToString() || arg.Content == tinycock.ToString())
        {
            //arg.Channel.SendMessageAsync($"User '{arg.Author.Username}' sent a cock");
            bool foundUser = false;
            foreach (var user in time.CockPosters)
            {
                if(arg.Author.Username == user){
                    arg.Channel.SendMessageAsync($"{arg.Author.Username} has posted multiple cocks today!");
                    foundUser = true;
                }
            }
            if(foundUser == false){
                time.CockPosters.Add(arg.Author.Username);
            }
        }
        var stickers = arg.Stickers;
        foreach (var s in stickers)
        {
            if (s.Name == bigCock)
            {
                if (time.bigCockPoster == null)
                {
                    //arg.Channel.SendMessageAsync($"Nice Cock!");
                    arg.Channel.SendFileAsync("nicecock.gif");
                    time.bigCockPoster = arg.Author.Username;
                }
                else
                {
                    arg.Channel.SendMessageAsync($"{arg.Author.Username} HAS A TINY COCK!");
                }
            }
        }
        return Task.CompletedTask;
    }
}
