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

    //private Time time = new Time();

    public async Task MainAsync()
    {
        _client = new DiscordSocketClient();
        ulong guildID = 792595734985048074;

        //time.TimeInit();

        _client.Log += Log;
        _client.MessageReceived += ClientOnMessageReceived;
        _client.SlashCommandExecuted += SlashCommandHandler;
        _client.Ready += Client_Ready;

        var token = File.ReadAllText("auth.txt");
        await _client.LoginAsync(TokenType.Bot, token);
        
        //Thread timeThread = new Thread(new ThreadStart(time.ClearList));
        //timeThread.IsBackground = true;
        //timeThread.Start();
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

        try
        {
            await _client.Rest.CreateGuildCommand(guildCommand.Build(), guildId);
        }
        catch(Exception e)
        {
            //var json = JsonConvert.SerializeObject(exception.Error, Formatting.Indented);
            Console.WriteLine(e);
        }
    }
    private async Task SlashCommandHandler(SocketSlashCommand command)
    {
        var cmdData = command.Data.Options.ToArray();
        string user = cmdData[0].ToString();
        string series = cmdData[1].ToString();
        await command.RespondAsync($"You executed {command.Data.Name}");
    }
}