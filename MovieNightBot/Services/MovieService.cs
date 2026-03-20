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
        private DateTime GetNextMovieDate(DateTime fromDate)
        {
            List<DateTime> allFridays;

            if (fromDate.Day < 15) // use the third friday of this month
            {
                allFridays = Enumerable.Range(0, 31)
                    .Select(i => fromDate.AddDays(i))
                    .Where(d => d.Month == fromDate.Month && d.DayOfWeek == DayOfWeek.Friday)
                    .ToList();
                return allFridays[2];
            }
            else // use the first friday of next month
            {
                var firstDayOfNextMonth = new DateTime(fromDate.Year, fromDate.Month, 1).AddMonths(1);
                allFridays = Enumerable.Range(0, 31)
                    .Select(i => firstDayOfNextMonth.AddDays(i))
                    .Where(d => d.Month == firstDayOfNextMonth.Month && d.DayOfWeek == DayOfWeek.Friday)
                    .ToList();
                return allFridays[0];
            }
        }
        public async Task AddMovieAsync(string movieName)
        {
            var movies = await GetMoviesAsync();

            var latestDate = movies.Any()
                ? movies.Max(m => m.DateToWatch)
                : DateTime.Now;

            var movie = new Movie
            {
                Title = movieName,
                DateToWatch = GetNextMovieDate(latestDate)
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
                    var previousMovie = movies
                        .Where(m => m.DateToWatch < movie.DateToWatch)
                        .OrderByDescending(m => m.DateToWatch)
                        .FirstOrDefault();

                    movie.DateToWatch = previousMovie != null
                        ? GetNextMovieDate(previousMovie.DateToWatch)
                        : GetNextMovieDate(new DateTime(movie.DateToWatch.Year, movie.DateToWatch.Month, 1).AddMonths(-1));
                }

                await SaveMoviesAsync(movies);
            }
        }
        public async Task AddToTopOfQueueAsync(string movieName)
        {
            var movies = await GetMoviesAsync();
            movies = movies.OrderBy(m => m.DateToWatch).ToList();

            DateTime newMovieDate;
            if (movies.Any())
            {
                newMovieDate = movies.First().DateToWatch;

                // Shift each existing movie forward by one Friday slot
                for (int i = 0; i < movies.Count; i++)
                {
                    movies[i].DateToWatch = GetNextMovieDate(movies[i].DateToWatch);
                }
            }
            else
            {
                newMovieDate = GetNextMovieDate(DateTime.Now);
            }

            movies.Insert(0, new Movie { Title = movieName, DateToWatch = newMovieDate });
            await SaveMoviesAsync(movies);
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
