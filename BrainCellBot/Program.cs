﻿using System;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using Discord;
using Discord.Commands;
using Discord.WebSocket;
namespace BrainCellBot
{
    class Program
    {
        public static void Main(string[] args) => new Program().MainAsync().GetAwaiter().GetResult();

        private DiscordSocketClient _client;

        private string BrainCellOwner = "BrainCellBot"; //start with a default holder

        private string lastOwnerPath = "/home/pi/Discord-Bots/BrainCellBot/lastOwner.txt";

        public async Task MainAsync()
        {
            _client = new DiscordSocketClient();

            _client.Log += Log;
           // _client.MessageReceived += ClientOnMessageReceived;
            _client.SlashCommandExecuted += SlashCommandHandler;
            _client.Ready += Client_Ready;

            var token = File.ReadAllText("auth.txt");
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
                .WithName("givebraincell")
                .WithDescription("Give the brain cell")
                .AddOption("user", ApplicationCommandOptionType.User, "The users whos you want to give the brain cell", isRequired: true);
            var guildCommand2 = new SlashCommandBuilder()
                .WithName("whohasbraincell")
                .WithDescription("Who has the Brain Cell");
            try
            {
                await _client.Rest.CreateGuildCommand(guildCommand.Build(), guildId);
                await _client.Rest.CreateGuildCommand(guildCommand2.Build(), guildId);
                this.BrainCellOwner = getLastBrainCellOwner();
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
        }
        private async Task SlashCommandHandler(SocketSlashCommand command)
        {
            if (command.CommandName == "givebraincell")
            {
                try
                {
                    await command.DeferAsync();
                }
                catch (Exception e)
                {
                    Console.WriteLine(e);
                }
                var cmdData = command.Data.Options.ToArray();
                var user = cmdData[0].Value;
                BrainCellOwner = user.ToString();
                setLastBrainCellOwner(user.ToString());
                await command.ModifyOriginalResponseAsync(msg => msg.Content = $"You gave the brain cell to {BrainCellOwner}");
            }   
            if (command.CommandName == "whohasbraincell")
            {
                try
                {
                    await command.DeferAsync();
                }
                catch (Exception e)
                {
                    Console.WriteLine(e);
                }
                var msgToSend = BrainCellOwner;
                await command.ModifyOriginalResponseAsync(msg => msg.Content = msgToSend);
            }
            
        }

        private string getLastBrainCellOwner(){
            try
            {
                var user = File.ReadAllText(lastOwnerPath);
                return user;
            }
            catch (Exception e) 
            {
                Console.WriteLine(e.ToString());
            }
            return this.BrainCellOwner;
        }

        private void setLastBrainCellOwner(string user){
            try
            {
                File.WriteAllText(lastOwnerPath, user);
            }
            catch (Exception e) 
            { 
                Console.WriteLine(e.ToString()); 
            }
        }
    }
}