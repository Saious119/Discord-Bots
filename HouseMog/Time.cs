using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace HouseMog
{
    public class Time
    {
        public DateTime NextPingTime { get; set; }
        public DateTime ActualDeadline { get; set; }

        public Time()
        {
            NextPingTime = DateTime.Now;
            ActualDeadline = NextPingTime.AddDays(10);
        }
    }
}
