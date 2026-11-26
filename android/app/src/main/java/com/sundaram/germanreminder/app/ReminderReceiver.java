package com.sundaram.germanreminder.app;
import android.content.*;
import android.util.Log;
public final class ReminderReceiver extends BroadcastReceiver {
  @Override public void onReceive(Context context, Intent intent) {
    try {
      if("com.sundaram.germanreminder.ALARM".equals(intent.getAction())) ReminderAlarms.deliver(context,intent);
      else if(Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction()) || Intent.ACTION_MY_PACKAGE_REPLACED.equals(intent.getAction()) ||
          Intent.ACTION_TIMEZONE_CHANGED.equals(intent.getAction()) || Intent.ACTION_TIME_CHANGED.equals(intent.getAction()) ||
          "android.intent.action.QUICKBOOT_POWERON".equals(intent.getAction())) ReminderAlarms.reconcile(context);
    } catch(Exception e) { Log.e("GermanReminder","Local reminder restoration failed"); }
  }
}
