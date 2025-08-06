using System;
using System.Data;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using System.Timers;
using Discord;
using Discord.Commands;
using Discord.WebSocket;
using Newtonsoft.Json;

namespace HouseMog
{
    class Program
    {
        public static void Main(string[] args) => new Program().MainAsync().GetAwaiter().GetResult();

        private DiscordSocketClient _client;
        private Time nextPingTime;

        public async Task MainAsync()
        {
            _client = new DiscordSocketClient();

            _client.Log += Log;
            // _client.MessageReceived += ClientOnMessageReceived;
            _client.SlashCommandExecuted += SlashCommandHandler;
            _client.Ready += Client_Ready;

            var token = File.ReadAllText("auth.txt");

            try
            {
                var json = File.ReadAllText("time.txt");
                nextPingTime = JsonConvert.DeserializeObject<Time>(json);
            }
            catch (Exception e)
            {
                //Console.WriteLine(e);
                nextPingTime = new Time { NextPingTime = DateTime.Now };
            }

            Thread timeThread = new Thread(new ThreadStart(StartTimer));
            timeThread.IsBackground = true;
            timeThread.Start();

            await _client.LoginAsync(TokenType.Bot, token);

            await _client.StartAsync();

            // Block this task until the program is closed.
            await Task.Delay(-1);
        }
        private static Task Log(LogMessage msg)
        {
            Console.WriteLine(msg.ToString());
            return Task.CompletedTask;
        }

        public async Task Client_Ready()
        {
            ulong guildId = 792595734985048074;

            var guildCommand = new SlashCommandBuilder()
                .WithName("ivisited")
                .WithDescription("You visited the house");
            var guildCommand2 = new SlashCommandBuilder()
                .WithName("deadline")
                .WithDescription("Tells the next deadline to visit the house");
            var guildCommand3 = new SlashCommandBuilder()
                .WithName("lastvisted")
                .WithDescription("Tells when the last time ivisted was used");
            try
            {
                await _client.Rest.CreateGuildCommand(guildCommand.Build(), guildId);
                await _client.Rest.CreateGuildCommand(guildCommand2.Build(), guildId);
                await _client.Rest.CreateGuildCommand(guildCommand3.Build(), guildId);
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }

        private async Task SlashCommandHandler(SocketSlashCommand cmd)
        {
            if (cmd.Data.Name == "ivisited")
            {
                try
                {
                    await cmd.DeferAsync();
                    await ResetTimer();
                    await cmd.ModifyOriginalResponseAsync(msg => msg.Content = "You visited the house Kupo!");
                }
                catch (Exception e)
                {
                    Console.WriteLine(e);
                }
            }
            if(cmd.Data.Name == "deadline")
            {
                try
                {
                    await cmd.DeferAsync();
                    await cmd.ModifyOriginalResponseAsync(msg => msg.Content = $"Please go visit the house before {nextPingTime.NextPingTime.ToString()}, Kupo!");
                }
                catch (Exception e)
                {
                    Console.WriteLine(e);
                }
            }
            if(cmd.Data.Name == "lastvisted")
            {
                try
                {
                    await cmd.DeferAsync();
                    await cmd.ModifyOriginalResponseAsync(msg => msg.Content = $"Last time ivisited was used: {nextPingTime.NextPingTime.AddDays(-20)}, Kupo!");
                }
                catch (Exception e)
                {
                    Console.WriteLine(e);
                }
            }
        }
        private async void StartTimer()
        {
            Thread.Sleep(60000); // Sleep for 5 minutes to avoid firing before bot is online
            while (true)
            {
                if (DateTime.Now >= nextPingTime.NextPingTime)
                {
                    Console.WriteLine("Time to ping!");
                    await SendMessageToChannel(792595734985048074, 1334015676855091251, $"Please go visit the house before {nextPingTime.NextPingTime.ToString()}, Kupo!");
                    await WaitADay();
                }
                Thread.Sleep(60000); // Sleep for 1 minute to avoid tight loop
            }
        }

        private async Task SendMessageToChannel(ulong guildId, ulong channelId, string message)
        {
            var guild = _client.GetGuild(guildId);
            if (guild != null)
            {
                Console.WriteLine("Got Guild");
                var channel = guild.GetTextChannel(channelId) as ISocketMessageChannel;
                if (channel != null)
                {
                    Console.WriteLine("Sending to Channel");
                    var warriorsOfLight = guild.GetRole(1189687666556551259);
                    await channel.SendMessageAsync($"{warriorsOfLight.Mention} {message}");
                }
            }
        }
        private async Task ResetTimer()
        {
            nextPingTime.NextPingTime = DateTime.Now.AddDays(20);
            var json = JsonConvert.SerializeObject(nextPingTime);
            File.WriteAllText("time.txt", json);
        }
        private async Task WaitADay()
        {
            nextPingTime.NextPingTime = DateTime.Now.AddDays(1);
            var json = JsonConvert.SerializeObject(nextPingTime);
            File.WriteAllText("time.txt", json);
        }
    }
}