package com.sundaram.germanreminder.app;

import java.time.*;

/** Weekly wall-clock time uses device zone rules; the timer keeps a UTC instant. */
public final class ReminderClock {
  public static boolean isDue(long planned, long incoming, long now) {
    return planned > 0 && planned == incoming && planned <= now;
  }
  public static long next(long nowMillis, ZoneId zone, int weekday, int hour, int minute) {
    if (weekday < 1 || weekday > 7 || hour < 0 || hour > 23 || minute < 0 || minute > 59)
      throw new IllegalArgumentException("Invalid reminder time");
    ZonedDateTime now = Instant.ofEpochMilli(nowMillis).atZone(zone);
    for (int offset = 0; offset <= 7; offset++) {
      LocalDate day = now.toLocalDate().plusDays(offset);
      ZonedDateTime candidate = day.atTime(hour, minute).atZone(zone);
      if (day.getDayOfWeek().getValue() == weekday && candidate.toInstant().toEpochMilli() > nowMillis)
        return candidate.toInstant().toEpochMilli();
    }
    throw new IllegalStateException("No next reminder time");
  }
}
