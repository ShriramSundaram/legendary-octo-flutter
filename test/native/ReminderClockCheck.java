import java.time.*;
import com.sundaram.germanreminder.app.ReminderClock;
public class ReminderClockCheck {
  private static void check(String now,String zone,int day,int hour,int minute,String expected) {
    long result=ReminderClock.next(Instant.parse(now).toEpochMilli(),ZoneId.of(zone),day,hour,minute);
    if(result!=Instant.parse(expected).toEpochMilli()) throw new AssertionError(zone+" next reminder mismatch");
  }
  public static void main(String[] args) {
    check("2026-11-26T10:00:00Z","Europe/Berlin",4,18,30,"2026-11-26T17:30:00Z");
    check("2026-12-31T17:30:00Z","Europe/Berlin",4,18,30,"2027-01-07T17:30:00Z");
    check("2026-03-28T12:00:00Z","Europe/Berlin",7,2,30,"2026-03-29T01:30:00Z");
    check("2026-03-29T02:00:00Z","Europe/Berlin",7,2,30,"2026-04-05T00:30:00Z");
    check("2026-10-24T12:00:00Z","Europe/Berlin",7,2,30,"2026-10-25T00:30:00Z");
    check("2026-10-25T00:45:00Z","Europe/Berlin",7,2,30,"2026-11-01T01:30:00Z");
    check("2026-11-26T10:00:00Z","Asia/Kolkata",4,18,0,"2026-11-26T12:30:00Z");
    try { ReminderClock.next(0,ZoneId.of("UTC"),8,18,0);throw new AssertionError("Invalid weekday accepted"); }
    catch(IllegalArgumentException expected) {}
    if(ReminderClock.isDue(2000,2000,1000))throw new AssertionError("Early broadcast delivered");
    if(ReminderClock.isDue(3000,2000,4000))throw new AssertionError("Stale broadcast delivered");
    if(!ReminderClock.isDue(2000,2000,2000))throw new AssertionError("Due broadcast rejected");
    System.out.println("11 native reminder-clock checks passed (DST, rollover, timezone, validation and stale/early delivery).");
  }
}
