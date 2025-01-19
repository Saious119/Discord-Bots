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
using DickJohnson;

class Program
{
    public static void Main(string[] args) => new Program().MainAsync().GetAwaiter().GetResult();

    private DiscordSocketClient _client;

    private string cockEmote {get; set;}

    private string tinyCock {get; set;}

    private string bigCock { get; set;}

    private Time time = new Time();

    private List<UserData> userDatas = new();

    public async Task MainAsync()
    {
        _client = new DiscordSocketClient();

        time.TimeInit();
        
        cockEmote = "<:cock:899135029190475826>";
        tinyCock = ":tinycock:";
        bigCock = "BigCock";

        _client.Log += Log;
        _client.SlashCommandExecuted += SlashCommandHandler;
        _client.Ready += Client_Ready;
        _client.MessageReceived += ClientOnMessageReceived;
        _client.MessageReceived += CockRecieved;

        var token = File.ReadAllText("auth.txt");

        var json = File.ReadAllText("UserData.json");
        userDatas = JsonConvert.DeserializeObject<List<UserData>>(json);

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
    private async Task SlashCommandHandler(SocketSlashCommand command)
    {
        if (command.CommandName == "cock_leaderboard")
        {
            try
            {
                await command.DeferAsync();
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
            string response = "";
            userDatas.OrderBy(x => x.bigCockCount);
            foreach (var knownUser in userDatas)
            {
                response += $"{knownUser.name} has posted {knownUser.bigCockCount} big cocks!\n";
            }
            await command.FollowupAsync(response);
        }
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
            .WithName("cock_leaderboard")
            .WithDescription("Shows a leaderboard for Big Cock");
        try
        {
            await _client.Rest.CreateGuildCommand(guildCommand.Build(), guildId);
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
        }
    }
    private Task CockRecieved(SocketMessage arg)
    {
        CheckForUser(arg.Author.Username);
        Emote.TryParse(cockEmote, out var cock);
        //Emote.TryParse(tinyCock, out var tinycock);
        if(arg.Content == cock.ToString())
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
                    foreach(var user in userDatas)
                    {
                        if(user.name == arg.Author.Username)
                        {
                            user.bigCockCount++;
                            SaveUserData();
                        }
                    }
                }
                else
                {
                    arg.Channel.SendMessageAsync($"{arg.Author.Username} HAS A TINY COCK!");
                }
            }
        }
        return Task.CompletedTask;
    }
    private void CheckForUser(string user)
    {
        Console.WriteLine("Checking for user: {0}", user);
        bool found = false;
        foreach(var knownUser in userDatas)
        {
            Console.WriteLine("user {0}", knownUser.name);
            if(knownUser.name == user)
            {
                Console.WriteLine("Found user {0}", knownUser.name);
                found = true; 
                return;
            }
        }
        if(found == false)
        {
            Console.WriteLine("Adding new user: {0} to json file...", user);
            userDatas.Add(new UserData { name = user, bigCockCount = 0 });
            SaveUserData();
        }
    }
    private void SaveUserData()
    {
        Console.WriteLine("writing to file");
        var json = JsonConvert.SerializeObject(userDatas, Formatting.Indented);
        File.WriteAllText("UserData.json", json);
        Console.WriteLine("Saved to file");
    }
}
