package com.sundaram.germanreminder.app;

import android.Manifest;
import android.app.*;
import android.content.*;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import org.json.*;
import java.time.ZoneId;
import java.util.*;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/** Device-local alarm registry. No Flutter engine or network is needed at delivery. */
public final class ReminderAlarms {
  private static final String PREFS = "german_reminder_alarms_v1";
  private static final String CHANNEL = "study_reminders_v1";
  private static boolean managed(int id) { return id >= 2100 && id <= 2107; }
  private static SharedPreferences prefs(Context c) { return c.getSharedPreferences(PREFS, Context.MODE_PRIVATE); }
  private static JSONObject plans(Context c) throws JSONException { return new JSONObject(prefs(c).getString("plans", "{}")); }
  private static void save(Context c, JSONObject rows) {
    if (!prefs(c).edit().putString("plans", rows.toString()).commit()) throw new IllegalStateException("Could not persist alarms");
  }
  private static PendingIntent alarmIntent(Context c, int id, JSONObject row) throws JSONException {
    Intent intent = new Intent(c, ReminderReceiver.class).setAction("com.sundaram.germanreminder.ALARM");
    intent.putExtra("id", id).putExtra("revision", row.getString("revision")).putExtra("at", row.getLong("at"));
    return PendingIntent.getBroadcast(c, id, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
  }
  private static void arm(Context c, int id, JSONObject row) throws JSONException {
    long target = Math.max(System.currentTimeMillis()+1000, row.getLong("at"));
    ((AlarmManager)c.getSystemService(Context.ALARM_SERVICE)).setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, target, alarmIntent(c,id,row));
  }
  private static void cancelAlarm(Context c, int id, boolean legacy) {
    Intent intent = legacy
      ? new Intent().setClassName(c,"com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver")
      : new Intent(c, ReminderReceiver.class).setAction("com.sundaram.germanreminder.ALARM");
    PendingIntent pending = PendingIntent.getBroadcast(c,id,intent,PendingIntent.FLAG_NO_CREATE | PendingIntent.FLAG_IMMUTABLE);
    if (pending != null) { ((AlarmManager)c.getSystemService(Context.ALARM_SERVICE)).cancel(pending); pending.cancel(); }
    ((NotificationManager)c.getSystemService(Context.NOTIFICATION_SERVICE)).cancel(id);
  }
  public static synchronized void cancel(Context c, int id) throws JSONException {
    // Legacy ID 0 must not deserialize the notification plugin's Gson cache.
    if(id==0) { cancelAlarm(c,id,true);clearLegacySchedules(c);return; }
    if(!managed(id))return;
    cancelAlarm(c,id,false);
    JSONObject rows=plans(c); rows.remove(String.valueOf(id)); save(c,rows);
  }
  private static void clearLegacySchedules(Context c) {
    // All current schedules use our native registry. Drop only the obsolete
    // plugin execution cache so its boot receiver cannot resurrect old alarms.
    // This is not the user's saved reminder settings.
    if(!c.getSharedPreferences("scheduled_notifications",Context.MODE_PRIVATE)
        .edit().remove("scheduled_notifications").commit())
      throw new IllegalStateException("Legacy reminder cleanup could not be saved");
  }
  public static synchronized void disable(Context c) {
    // This emergency path intentionally works even if the registry JSON is bad.
    boolean persisted=prefs(c).edit().putString("owner","").putString("plans","{}").commit();
    RuntimeException failure=null;
    for(int id=2100;id<=2107;id++) {
      try { cancelAlarm(c,id,false); } catch(RuntimeException e) { failure=e; }
    }
    try { cancelAlarm(c,0,true); } catch(RuntimeException e) { failure=e; }
    try { clearLegacySchedules(c); } catch(RuntimeException e) { failure=e; }
    if(!persisted||failure!=null)throw new IllegalStateException("Reminder shutdown could not be confirmed");
  }
  private static void setOwner(Context c, String owner) throws JSONException {
    if (owner != null && !owner.matches("[a-f0-9]{64}")) throw new IllegalArgumentException("Invalid owner");
    String next=owner==null?"":owner;
    if (!next.equals(prefs(c).getString("owner",""))) {
      // Invalidate the native receiver before removing any old alarms.
      if (!prefs(c).edit().putString("owner",next).commit()) throw new IllegalStateException("Owner could not be saved");
      for(int id=2100;id<=2107;id++) cancel(c,id);
    }
  }
  private static void schedule(Context c, Map<?,?> args) throws JSONException {
    int id=((Number)args.get("id")).intValue();
    if(!managed(id)) throw new IllegalArgumentException("Invalid alarm ID");
    String payload=(String)args.get("payload");
    if(payload==null || payload.length()>1024) throw new IllegalArgumentException("Invalid payload");
    JSONObject data=new JSONObject(payload);
    String owner=prefs(c).getString("owner","");
    String revision=data.getString("revision");
    String kind=data.getString("kind");
    if(owner.isEmpty() || !owner.equals(data.getString("owner")) || data.getInt("v")!=1 ||
      !revision.matches("[a-f0-9]{32}") || !data.getString("level").matches("A1|A2|B1|B2|C1|C2") ||
      !(id==2100?kind.equals("timer"):kind.equals("weekly"))) throw new IllegalArgumentException("Invalid reminder context");
    JSONObject row=new JSONObject(); row.put("owner",owner).put("revision",revision).put("payload",payload);
    if(id==2100) {
      long at=((Number)args.get("at")).longValue();
      if(at<=System.currentTimeMillis() || at>System.currentTimeMillis()+86405000L) throw new IllegalArgumentException("Invalid timer duration");
      row.put("at",at);
    } else {
      int hour=((Number)args.get("hour")).intValue(), minute=((Number)args.get("minute")).intValue();
      row.put("hour",hour).put("minute",minute);
      row.put("at",ReminderClock.next(System.currentTimeMillis(),ZoneId.systemDefault(),id-2100,hour,minute));
    }
    JSONObject rows=plans(c); rows.put(String.valueOf(id),row); save(c,rows);
    try { arm(c,id,row); } catch(RuntimeException e) { rows.remove(String.valueOf(id)); save(c,rows); throw e; }
  }
  public static synchronized void reconcile(Context c) throws JSONException {
    JSONObject rows=plans(c);
    for(int id=2100;id<=2107;id++) {
      JSONObject row=rows.optJSONObject(String.valueOf(id));
      if(row==null) continue;
      if(!row.optString("owner").equals(prefs(c).getString("owner",""))) { cancel(c,id); rows.remove(String.valueOf(id)); continue; }
      if(id!=2100) row.put("at",ReminderClock.next(System.currentTimeMillis(),ZoneId.systemDefault(),id-2100,row.getInt("hour"),row.getInt("minute")));
      rows.put(String.valueOf(id),row);save(c,rows);arm(c,id,row);
    }
  }
  public static synchronized void deliver(Context c, Intent intent) throws JSONException {
    int id=intent.getIntExtra("id",-1);
    if(!managed(id)) return;
    JSONObject rows=plans(c), row=rows.optJSONObject(String.valueOf(id));
    if(row==null || !row.getString("owner").equals(prefs(c).getString("owner","")) ||
      !row.getString("revision").equals(intent.getStringExtra("revision")) ||
      !ReminderClock.isDue(row.getLong("at"),intent.getLongExtra("at",-1),System.currentTimeMillis())) return;
    String payload=row.getString("payload");
    long originalAt=row.getLong("at");
    // Consume first: a duplicate broadcast cannot deliver a second notification.
    if(id==2100) { rows.remove(String.valueOf(id));save(c,rows); }
    else { row.put("at",ReminderClock.next(System.currentTimeMillis(),ZoneId.systemDefault(),id-2100,row.getInt("hour"),row.getInt("minute")));save(c,rows);arm(c,id,row); }
    if(id!=2100 && !java.time.Instant.ofEpochMilli(originalAt).atZone(ZoneId.systemDefault()).toLocalDate()
      .equals(java.time.LocalDate.now())) return; // Do not deliver a backlog of old study days.
    if(Build.VERSION.SDK_INT>=33 && c.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED) return;
    NotificationManager manager=(NotificationManager)c.getSystemService(Context.NOTIFICATION_SERVICE);
    if(Build.VERSION.SDK_INT>=26) manager.createNotificationChannel(new NotificationChannel(CHANNEL,"Study reminders",NotificationManager.IMPORTANCE_DEFAULT));
    // This is the notification plugin's pinned 17.2.4 tap contract. It handles
    // both onNewIntent and getNotificationAppLaunchDetails with the same payload.
    Intent launch=c.getPackageManager().getLaunchIntentForPackage(c.getPackageName());
    if(launch==null) return;
    launch.setAction("SELECT_NOTIFICATION").putExtra("notificationId",id).putExtra("payload",payload);
    launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP);
    PendingIntent tap=PendingIntent.getActivity(c,id,launch,PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    Notification.Builder builder=Build.VERSION.SDK_INT>=26?new Notification.Builder(c,CHANNEL):new Notification.Builder(c);
    builder.setSmallIcon(R.drawable.ic_stat_reminder)
      .setContentTitle("Time for German 🌱").setContentText("A few words today. Tap to review.")
      .setContentIntent(tap).setAutoCancel(true).setColor(Color.rgb(103,84,192)).setVisibility(Notification.VISIBILITY_PRIVATE);
    if(Build.VERSION.SDK_INT<26) builder.setDefaults(Notification.DEFAULT_ALL);
    manager.notify(id,builder.build());
  }
  public static synchronized void handle(Context c, MethodCall call, MethodChannel.Result result) {
    try {
      Map<?,?> args=call.arguments();
      switch(call.method) {
        case "owner":setOwner(c,(String)args.get("owner"));result.success(null);break;
        case "schedule":schedule(c,args);result.success(null);break;
        case "cancel":cancel(c,((Number)args.get("id")).intValue());result.success(null);break;
        case "reconcile":reconcile(c);result.success(null);break;
        case "disable":disable(c);result.success(null);break;
        case "context":
          Map<String,Object> context=new HashMap<>();context.put("packageName",c.getPackageName());
          context.put("debuggable",(c.getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE)!=0);
          result.success(context);break;
        case "pending":
          Map<String,String> pending=new HashMap<>();JSONObject rows=plans(c);
          for(int id=2100;id<=2107;id++) { JSONObject row=rows.optJSONObject(String.valueOf(id));if(row!=null)pending.put(String.valueOf(id),row.getString("payload")); }
          result.success(pending);break;
        default:result.notImplemented();
      }
    } catch(Exception e) { result.error("reminder_update_failed","Could not update local reminders",null); }
  }
}
