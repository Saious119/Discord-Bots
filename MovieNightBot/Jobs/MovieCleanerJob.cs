using MovieNightBot.Services;
using Quartz;

namespace MovieNightBot.Jobs
{
    public class MovieCleanerJob : IJob
    {
        private readonly MovieService _movieService;

        public MovieCleanerJob(MovieService movieService)
        {
            _movieService = movieService;
        }

        public async Task Execute(IJobExecutionContext context)
        {
            try
            {
                Console.WriteLine("Executing Movie Clean Up Job...");
                await CleanOldMoviesAsync();
                Console.WriteLine("Old Movies removed successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in MovieCleanerJob: {ex.Message}");
            }
        }
        public async Task CleanOldMoviesAsync()
        {
            var movies = await _movieService.GetMoviesAsync();
            var cutoffDate = DateTime.Now.AddDays(-1);
            var updatedMovies = movies.Where(m => m.DateToWatch >= cutoffDate).ToList();
            if (updatedMovies.Count != movies.Count)
            {
                await _movieService.SaveMoviesAsync(updatedMovies);
            }
        }
    }
}
