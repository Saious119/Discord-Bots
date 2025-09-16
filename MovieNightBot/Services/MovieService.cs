using MovieNightBot.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MovieNightBot.Services
{
    public class MovieService
    {
        public MovieService() { }
        public async Task<List<Movie>> GetMoviesAsync()
        {
            var json = await File.ReadAllTextAsync("MovieData.json");
            List<Movie> movies = System.Text.Json.JsonSerializer.Deserialize<List<Movie>>(json);
            return movies;
        }
        public async Task SaveMoviesAsync(List<Movie> movies)
        {
            var json = System.Text.Json.JsonSerializer.Serialize(movies);
            await File.WriteAllTextAsync("MovieData.json", json);
        }
        public async Task AddMovieAsync(string movieName)
        {
            var movies = await GetMoviesAsync();

            // Find the latest movie date or use current date if no movies exist
            var latestDate = movies.Any()
                ? movies.Max(m => m.DateToWatch)
                : DateTime.Now;

            // Get first day of next month
            var firstDayOfNextMonth = new DateTime(
                latestDate.Year,
                latestDate.Month, 1)
                .AddMonths(1);

            // Find first Friday of that month
            var firstFriday = Enumerable.Range(0, 7)
                .Select(i => firstDayOfNextMonth.AddDays(i))
                .First(d => d.DayOfWeek == DayOfWeek.Friday);

            var movie = new Movie
            {
                Title = movieName,
                DateToWatch = firstFriday
            };

            movies.Add(movie);
            await SaveMoviesAsync(movies);
        }
        public async Task RemoveMovieAsync(string movieName)
        {
            var movies = await GetMoviesAsync();
            var movieToRemove = movies.FirstOrDefault(m => m.Title.Equals(movieName, StringComparison.OrdinalIgnoreCase));

            if (movieToRemove != null)
            {
                var removedDate = movieToRemove.DateToWatch;
                movies.Remove(movieToRemove);

                // Get all movies that were scheduled after the removed movie
                var moviesToAdjust = movies
                    .Where(m => m.DateToWatch > removedDate)
                    .OrderBy(m => m.DateToWatch)
                    .ToList();

                // Adjust each movie's date to the first Friday of the previous month
                foreach (var movie in moviesToAdjust)
                {
                    var targetMonth = movie.DateToWatch.AddMonths(-1);
                    var firstDayOfMonth = new DateTime(targetMonth.Year, targetMonth.Month, 1);

                    var firstFriday = Enumerable.Range(0, 7)
                        .Select(i => firstDayOfMonth.AddDays(i))
                        .First(d => d.DayOfWeek == DayOfWeek.Friday);

                    movie.DateToWatch = firstFriday;
                }

                await SaveMoviesAsync(movies);
            }
        }
    }
}
