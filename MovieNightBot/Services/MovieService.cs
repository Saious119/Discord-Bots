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

            List<DateTime> allFridays = new();
            DateTime movieDate;
            // Determine which Friday is the last movie (first or third)
            if (latestDate.Day < 15) //then use the third friday of this month
            {
                allFridays = Enumerable.Range(0, 31)
                    .Select(i => latestDate.AddDays(i))
                    .Where(d => d.Month == latestDate.Month && d.DayOfWeek == DayOfWeek.Friday)
                    .ToList();
                movieDate = allFridays[2];
            }
            else //use the first friday of next month
            {
                // Get first day of next month
                var firstDayOfNextMonth = new DateTime(
                        latestDate.Year,
                        latestDate.Month, 1)
                    .AddMonths(1);

                // Find first and third Fridays of that month
                allFridays = Enumerable.Range(0, 31)
                    .Select(i => firstDayOfNextMonth.AddDays(i))
                    .Where(d => d.Month == firstDayOfNextMonth.Month && d.DayOfWeek == DayOfWeek.Friday)
                    .ToList();
                movieDate = allFridays[0];
            }

            var movie = new Movie
            {
                Title = movieName,
                DateToWatch = movieDate
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

                // Adjust each movie's date
                foreach (var movie in moviesToAdjust)
                {
                    var targetMonth = movie.DateToWatch.AddMonths(-1);
                    var firstDayOfMonth = new DateTime(targetMonth.Year, targetMonth.Month, 1);

                    var allFridays = Enumerable.Range(0, 31)
                        .Select(i => firstDayOfMonth.AddDays(i))
                        .Where(d => d.Month == firstDayOfMonth.Month && d.DayOfWeek == DayOfWeek.Friday)
                        .ToList();

                    // Determine if this should be first or third Friday based on previous movie
                    var previousMovie = movies
                        .Where(m => m.DateToWatch < movie.DateToWatch)
                        .OrderByDescending(m => m.DateToWatch)
                        .FirstOrDefault();

                    movie.DateToWatch = previousMovie != null
                        ? (previousMovie.DateToWatch.Day < 15 ? allFridays[2] : allFridays[0])
                        : allFridays[0];
                }

                await SaveMoviesAsync(movies);
            }
        }
        public async Task SwapMovies(string movieName1, string movieName2)
        {
            var movies = await GetMoviesAsync();
            var movie1 = movies.FirstOrDefault(m => m.Title.Equals(movieName1, StringComparison.OrdinalIgnoreCase));
            var movie2 = movies.FirstOrDefault(m => m.Title.Equals(movieName2, StringComparison.OrdinalIgnoreCase));
            if (movie1 != null && movie2 != null)
            {
                var tempDate = movie1.DateToWatch;
                movie1.DateToWatch = movie2.DateToWatch;
                movie2.DateToWatch = tempDate;
                await SaveMoviesAsync(movies);
            }
        }
    }
}
