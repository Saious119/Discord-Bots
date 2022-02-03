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

    private List<string> CockPosters {get; set;}

    private string cockEmote {get; set;}

    private string bigCock { get; set;}

    private string bigCockPoster { get; set;}

    public async Task MainAsync()
    {
        _client = new DiscordSocketClient();

        CockPosters = new List<string>();
        cockEmote = "<:cock:899135029190475826>";
        bigCock = "BigCock";

        _client.Log += Log;
        _client.MessageReceived += ClientOnMessageReceived;
        _client.MessageReceived += CockRecieved;

        var token = File.ReadAllText("auth.txt");

        await _client.LoginAsync(TokenType.Bot, token);
        await _client.StartAsync();

        ClearList();

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
        if(arg.Content == cock.ToString())
        {
            //arg.Channel.SendMessageAsync($"User '{arg.Author.Username}' sent a cock");
            foreach (var user in CockPosters)
            {
                if(arg.Author.Username == user){
                    arg.Channel.SendMessageAsync($"{arg.Author.Username} has posted multiple cocks today!");
                }
            }
            CockPosters.Add(arg.Author.Username);
        }
        var stickers = arg.Stickers;
        foreach (var s in stickers)
        {
            if (s.Name == bigCock)
            {
                if (bigCockPoster == null)
                {
                    //arg.Channel.SendMessageAsync($"Nice Cock!");
                    arg.Channel.SendFileAsync("nicecock.gif");
                    bigCockPoster = arg.Author.Username;
                }
                else
                {
                    arg.Channel.SendMessageAsync($"{arg.Author.Username} HAS A TINY COCK!");
                }
            }
        }
        return Task.CompletedTask;
    }
    private async Task ClearList()
    {
        DateTime midnight = new System.DateTime(2022, 1, 31, 14, 0, 0, 0);
        while(true){
            if(DateTime.Now.Hour == midnight.Hour)
            {
                Console.WriteLine("It's midnight, clearing list");
                CockPosters = new List<string>();
                bigCockPoster = null;
            }
        }
    }
}
