using Discord;
using Discord.Net;
using Discord.WebSocket;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using MovieNightBot.Jobs;
using MovieNightBot.Models;
using MovieNightBot.Services;
using Quartz;

class Program
{
    public static async Task Main(string[] args)
    {
        var host = Host.CreateDefaultBuilder(args)
            .ConfigureServices((context, services) =>
            {
                // Register your services
                services.AddSingleton<MovieService>();
                services.AddSingleton<DiscordSocketClient>();
                services.AddSingleton<Program>();

                // Register Quartz and your job
                services.AddQuartz(q =>
                {
                    var jobKey = new JobKey("movieCleanerJob");
                    q.AddJob<MovieCleanerJob>(opts => opts.WithIdentity(jobKey));
                    q.AddTrigger(opts => opts
                        .ForJob(jobKey)
                        .WithIdentity("movieCleanerTrigger")
                        .WithCronSchedule("0 0 0 * * ?")); // Every minute at 0 seconds
                });
                services.AddQuartzHostedService(q => q.WaitForJobsToComplete = true);
            })
            .Build();

        // Start the Discord bot and host for job concurrently
        var program = host.Services.GetRequiredService<Program>();
        await Task.WhenAll(
            program.MainAsync(),
            host.RunAsync()
        );
    }

    private readonly DiscordSocketClient _client;
    private readonly MovieService _movieService;

    public Program(DiscordSocketClient client, MovieService movieService)
    {
        _client = client;
        _movieService = movieService;
    }

    public async Task MainAsync()
    {
        _client.Log += Log;
        _client.SlashCommandExecuted += SlashCommandHandler;
        _client.Ready += Client_Ready;

        var token = await File.ReadAllTextAsync("auth.txt");
        await _client.LoginAsync(TokenType.Bot, token);
        await _client.StartAsync();
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
        if (command.CommandName == "swap_movies")
        {
            var movieName1 = (string)command.Data.Options.First().Value;
            var movieName2 = (string)command.Data.Options.ElementAt(1).Value;
            try
            {
                await command.DeferAsync();
            }
            catch (Exception e)
            {
                Console.WriteLine(e);
            }
            MovieService MovieFetcher = new MovieService();
            await MovieFetcher.SwapMovies(movieName1, movieName2);
            await command.FollowupAsync($"Swapped {movieName1} and {movieName2} in the movie queue.");
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

            var swapMoviesCommand = new SlashCommandBuilder()
                .WithName("swap_movies")
                .WithDescription("Swaps the dates of two movies in the queue")
                .AddOption("movie1", ApplicationCommandOptionType.String, "The name of the first movie", isRequired: true)
                .AddOption("movie2", ApplicationCommandOptionType.String, "The name of the second movie", isRequired: true);

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