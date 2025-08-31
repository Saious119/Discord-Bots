using Discord;
using Discord.Commands;
using Discord.Net;
using Discord.WebSocket;
using MovieNightBot.Models;
using MovieNightBot.Services;

class Program
{
    public static void Main(string[] args) => new Program().MainAsync().GetAwaiter().GetResult();
    private DiscordSocketClient _client;
    public async Task MainAsync()
    {
        _client = new DiscordSocketClient(new DiscordSocketConfig
        {
            GatewayIntents = GatewayIntents.GuildMessages |
                     GatewayIntents.Guilds
        });
        _client.Log += Log;
        _client.SlashCommandExecuted += SlashCommandHandler;
        _client.Ready += Client_Ready;

        var token = await File.ReadAllTextAsync("auth.txt");

        await _client.LoginAsync(TokenType.Bot, token);
        await _client.StartAsync();
        await Task.Delay(-1);
    }
    private static Task Log(LogMessage msg)
    {
        Console.WriteLine(msg.ToString());
        return Task.CompletedTask;
    }
    private async Task SlashCommandHandler(SocketSlashCommand command)
    {
        if (command.CommandName == "movie_queue")
        {
            try
            {
                await command.DeferAsync();
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
            MovieService MovieFetcher = new MovieService();
            var movieList = await MovieFetcher.GetMoviesAsync();
            string response = "";
            foreach (var movie in movieList.OrderBy(m => m.DateToWatch))
            {
                response += $"{movie.Title} - {movie.DateToWatch:MMMM dd, yyyy}\n";
            }
            await command.FollowupAsync(response);
        }
        if (command.CommandName == "add_movie")
        {
            var movieName = (string)command.Data.Options.First().Value;
            try
            {
                await command.DeferAsync();
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
            MovieService MovieFetcher = new MovieService();
            await MovieFetcher.AddMovieAsync(movieName);
            Movie targetMovie = (await MovieFetcher.GetMoviesAsync()).First(m => m.Title == movieName);
            //var guild = _client.GetGuild(792595734985048074);
            //var guildEvent = await guild.CreateEventAsync(targetMovie.Title, targetMovie.DateToWatch, GuildScheduledEventType.Voice, endTime: targetMovie.DateToWatch.AddHours(2), location: "caac");
            await command.FollowupAsync($"Added {movieName} to the movie queue for date {targetMovie.DateToWatch:MMMM dd, yyyy}");
        }
        if (command.CommandName == "remove_movie")
        {
            var movieName = (string)command.Data.Options.First().Value;
            try
            {
                await command.DeferAsync();
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
            MovieService MovieFetcher = new MovieService();
            await MovieFetcher.RemoveMovieAsync(movieName);
            await command.FollowupAsync($"Removed {movieName} from the movie queue.");
        }
    }
    public async Task Client_Ready()
    {
        ulong guildId = 792595734985048074;

        try
        {
            var guildCommand = new SlashCommandBuilder()
                .WithName("movie_queue")
                .WithDescription("Shows what upcoming movies are being shown");

            // Also register other commands
            var addMovieCommand = new SlashCommandBuilder()
                .WithName("add_movie")
                .WithDescription("Adds a movie to the queue")
                .AddOption("name", ApplicationCommandOptionType.String, "The name of the movie", isRequired: true);

            var removeMovieCommand = new SlashCommandBuilder()
                .WithName("remove_movie")
                .WithDescription("Removes a movie from the queue")
                .AddOption("name", ApplicationCommandOptionType.String, "The name of the movie", isRequired: true);

            await _client.Rest.BulkOverwriteGuildCommands(new[]
            {
            guildCommand.Build(),
            addMovieCommand.Build(),
            removeMovieCommand.Build()
        }, guildId);

            Console.WriteLine("Successfully registered slash commands!");
        }
        catch (HttpException ex)
        {
            Console.WriteLine($"Error registering commands: {ex.Message}");
            if (ex.HttpCode.Equals(50001))
            {
                Console.WriteLine("Bot lacks permissions. Please ensure it has the 'applications.commands' scope and proper permissions in the server.");
            }
        }
    }
}