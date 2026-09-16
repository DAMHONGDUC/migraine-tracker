import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Every icon the app draws, named for what it MEANS rather than for the glyph it happens to be.
final class AppIconConstant {
  // --- Navigation and chrome ---------------------------------------------

  /// The Home tab, and anything meaning "back to the dashboard".
  static const IconData home = Symbols.home_rounded;

  /// The History tab: attacks over time.
  static const IconData history = Symbols.calendar_month_rounded;

  /// The Insights tab: what the data says.
  static const IconData insights = Symbols.insights_rounded;

  /// The Medications tab, and every medication anywhere else.
  static const IconData medication = Symbols.medication_rounded;

  /// The Settings tab.
  static const IconData settings = Symbols.settings_rounded;

  /// A row opens something. Paired with [AppIconSize.small] — it says "tappable" and must never outweigh the glyph naming the row.
  static const IconData disclosure = Symbols.chevron_right_rounded;

  /// Step back — the calendar's previous month.
  static const IconData previous = Symbols.chevron_left_rounded;

  /// Dismiss a sheet, clear a field.
  static const IconData close = Symbols.close_rounded;

  /// Search within a list.
  static const IconData search = Symbols.search_rounded;

  /// Narrow a list down.
  static const IconData filter = Symbols.filter_alt_rounded;

  /// More actions on this row, in a menu.
  static const IconData more = Symbols.more_horiz_rounded;

  /// Leaves the app for a browser or the App Store.
  static const IconData externalLink = Symbols.open_in_new_rounded;

  // --- Logging an attack -------------------------------------------------

  /// Add anything: the log button, a new medication, a new reminder.
  static const IconData add = Symbols.add_rounded;

  /// Logging an attack, where the action needs a shape of its own.
  static const IconData attackLog = Symbols.add_circle_rounded;

  /// The list of logged attacks.
  static const IconData attackList = Symbols.event_note_rounded;

  /// Visual aura — flashes, blind spots.
  static const IconData auraVisual = Symbols.visibility_rounded;

  /// Sensory aura — tingling, numbness.
  static const IconData auraSensory = Symbols.back_hand_rounded;

  /// Speech aura — trouble finding words.
  static const IconData auraSpeech = Symbols.record_voice_over_rounded;

  /// Motor aura — weakness on one side.
  static const IconData auraMotor = Symbols.accessibility_new_rounded;

  /// Physical exertion: none — resting.
  static const IconData exertionNone = Symbols.self_improvement_rounded;

  /// Physical exertion: light.
  static const IconData exertionLight = Symbols.directions_walk_rounded;

  /// Physical exertion: moderate.
  static const IconData exertionModerate = Symbols.directions_run_rounded;

  /// Physical exertion: severe.
  static const IconData exertionSevere = Symbols.fitness_center_rounded;

  /// The medication helped.
  static const IconData effectHelped = Symbols.sentiment_very_satisfied_rounded;

  /// The medication helped a little.
  static const IconData effectPartly = Symbols.sentiment_neutral_rounded;

  /// The medication did nothing.
  static const IconData effectNone = Symbols.sentiment_dissatisfied_rounded;

  /// "No medication" in the log flow's picker — an option, not a failure.
  static const IconData noMedication = Symbols.block_rounded;

  /// The attack is saved.
  static const IconData saved = Symbols.check_circle_rounded;

  /// Confirm an inline edit.
  static const IconData confirm = Symbols.check_rounded;

  /// Change a saved value.
  static const IconData edit = Symbols.edit_rounded;

  /// Remove one record.
  static const IconData delete = Symbols.delete_rounded;

  /// Erase everything, permanently — the GDPR wipe, deleting an account.
  static const IconData deleteForever = Symbols.delete_forever_rounded;

  /// Send an attack out of the app.
  static const IconData share = Symbols.ios_share_rounded;

  // --- Medications and reminders -----------------------------------------

  /// A scheduled dose.
  static const IconData reminder = Symbols.alarm_rounded;

  /// Schedule a new dose.
  static const IconData reminderAdd = Symbols.alarm_add_rounded;

  /// Reminders as a feature — the ones that fire, not the ones scheduled.
  static const IconData reminderActive = Symbols.notifications_active_rounded;

  // --- Weather and pressure ----------------------------------------------

  /// Barometric pressure — the thing this app is actually about.
  static const IconData pressure = Symbols.compress_rounded;

  /// A pressure drop, and any figure that fell.
  static const IconData trendDown = Symbols.trending_down_rounded;

  /// A figure that rose.
  static const IconData trendUp = Symbols.trending_up_rounded;

  /// A figure that held steady.
  static const IconData trendFlat = Symbols.trending_flat_rounded;

  /// A storm, and the pressure alert that warns of one.
  static const IconData storm = Symbols.storm_rounded;

  /// Clear sky, day.
  static const IconData weatherClear = Symbols.wb_sunny_rounded;

  /// Clear sky, night.
  static const IconData weatherClearNight = Symbols.nightlight_rounded;

  /// Cloud cover.
  static const IconData weatherCloudy = Symbols.cloud_rounded;

  /// Cloud cover at night.
  static const IconData weatherCloudyNight = Symbols.nights_stay_rounded;

  /// Partly cloudy, day.
  static const IconData weatherPartlyCloudy = Symbols.wb_cloudy_rounded;

  /// Rain.
  static const IconData weatherRain = Symbols.cloudy_snowing_rounded;

  /// Sleet.
  static const IconData weatherSleet = Symbols.grain_rounded;

  /// Snow.
  static const IconData weatherSnow = Symbols.ac_unit_rounded;

  /// Thunderstorms.
  static const IconData weatherThunderstorms = Symbols.thunderstorm_rounded;

  /// Wind, and the wind-speed reading.
  static const IconData weatherWindy = Symbols.air_rounded;

  /// Fog.
  static const IconData weatherFog = Symbols.foggy_rounded;

  /// Haze.
  static const IconData weatherHazy = Symbols.blur_on_rounded;

  /// A condition the API sent that we have no glyph for.
  static const IconData weatherUnknown = Symbols.help_rounded;

  /// Relative humidity.
  static const IconData humidity = Symbols.water_drop_rounded;

  /// Chance of rain.
  static const IconData precipitation = Symbols.umbrella_rounded;

  /// Rainfall amount.
  static const IconData rainfall = Symbols.water_rounded;

  /// UV index.
  static const IconData uvIndex = Symbols.wb_sunny_rounded;

  /// How far you can see.
  static const IconData visibility = Symbols.visibility_rounded;

  /// Sunrise and sunset.
  static const IconData daylight = Symbols.wb_twilight_rounded;

  /// Where the reading was taken.
  static const IconData location = Symbols.location_on_rounded;

  /// Location is off, so there is no reading.
  static const IconData locationOff = Symbols.location_off_rounded;

  /// The place could not be resolved.
  static const IconData locationUnknown = Symbols.wrong_location_rounded;

  // --- Insights and charts -----------------------------------------------

  /// A correlation — the app's own reading of the data.
  static const IconData correlation = Symbols.timeline_rounded;

  /// The deeper analysis behind a card.
  static const IconData analysis = Symbols.analytics_rounded;

  /// A line chart: the pressure forecast, the history deck.
  static const IconData lineChart = Symbols.show_chart_rounded;

  /// A bar chart, and History's chart view.
  static const IconData barChart = Symbols.bar_chart_rounded;

  /// History's calendar view.
  static const IconData calendarView = Symbols.calendar_view_month_rounded;

  /// History's list view.
  static const IconData listView = Symbols.list_alt_rounded;

  // --- The daily check-in ------------------------------------------------

  /// The check-in itself: the dashboard card and the screen it opens.
  static const IconData dailyLog = Symbols.event_available_rounded;

  /// Stress, on the check-in's second question.
  static const IconData stress = Symbols.mood_bad_rounded;

  static const IconData factorSkippedMeal = Symbols.no_meals_rounded;
  static const IconData factorDehydration = Symbols.water_drop_rounded;
  static const IconData factorCaffeine = Symbols.local_cafe_rounded;
  static const IconData factorAlcohol = Symbols.wine_bar_rounded;
  static const IconData factorScreenTime = Symbols.devices_rounded;
  static const IconData factorIntenseExercise = Symbols.fitness_center_rounded;
  static const IconData factorTravel = Symbols.flight_rounded;
  static const IconData factorStrongSmell = Symbols.air_rounded;
  static const IconData factorBrightLight = Symbols.brightness_high_rounded;
  static const IconData factorLoudNoise = Symbols.volume_up_rounded;
  static const IconData factorNeckTension = Symbols.accessibility_new_rounded;
  static const IconData factorMissedMedication = Symbols.pill_off_rounded;

  static const IconData symptomNausea = Symbols.sick_rounded;
  static const IconData symptomVomiting =
      Symbols.sentiment_very_dissatisfied_rounded;
  static const IconData symptomLightSensitivity = Symbols.light_mode_rounded;
  static const IconData symptomSoundSensitivity = Symbols.hearing_rounded;
  static const IconData symptomSmellSensitivity = Symbols.masks_rounded;
  static const IconData symptomDizziness = Symbols.rotate_right_rounded;
  static const IconData symptomNeckPain = Symbols.self_improvement_rounded;
  static const IconData symptomBlurredVision = Symbols.blur_on_rounded;

  // --- Apple Health ------------------------------------------------------

  /// Apple Health itself, where the app asks to connect.
  static const IconData health = Symbols.favorite_rounded;

  /// The menstrual cycle, read from Apple Health and never stored.
  static const IconData cycle = Symbols.calendar_month_rounded;

  /// Sleep — last night, and the sleep correlation.
  static const IconData sleep = Symbols.bedtime_rounded;

  /// Steps and daily activity.
  static const IconData steps = Symbols.directions_walk_rounded;

  /// How long something lasted.
  static const IconData duration = Symbols.hourglass_empty_rounded;

  /// A budget running out — the free plan's log countdown.
  static const IconData runningOut = Symbols.hourglass_bottom_rounded;

  // --- Notifications -----------------------------------------------------

  /// The notification list, and its app-bar way in.
  static const IconData notifications = Symbols.notifications_rounded;

  /// Notifications are turned off at the OS.
  static const IconData notificationsOff = Symbols.notifications_off_rounded;

  /// Ask for notification permission.
  static const IconData notificationAdd = Symbols.notification_add_rounded;

  /// The notification inbox as a feature.
  static const IconData inbox = Symbols.inbox_rounded;

  // --- Premium -----------------------------------------------------------

  /// Premium is on.
  static const IconData premium = Symbols.workspace_premium_rounded;

  /// Behind the paywall — every lock in the app is this one.
  static const IconData locked = Symbols.lock_rounded;

  /// What premium lifts: unlimited records.
  static const IconData unlimited = Symbols.all_inclusive_rounded;

  /// The selected plan on the paywall.
  static const IconData radioSelected = Symbols.radio_button_checked_rounded;

  /// A plan not selected.
  static const IconData radioUnselected =
      Symbols.radio_button_unchecked_rounded;

  // --- Account and sync --------------------------------------------------

  /// The signed-in account.
  static const IconData account = Symbols.account_circle_rounded;

  /// The account holder's name.
  static const IconData profileName = Symbols.badge_rounded;

  /// Their email address.
  static const IconData profileEmail = Symbols.alternate_email_rounded;

  /// When the account was created.
  static const IconData profileCreated = Symbols.event_rounded;

  /// Sign out.
  static const IconData signOut = Symbols.logout_rounded;

  /// Everything is synced — the login pitch's promise.
  static const IconData synced = Symbols.cloud_done_rounded;

  /// The same account on another device.
  static const IconData devices = Symbols.devices_rounded;

  /// Get your records back after a reinstall.
  static const IconData restore = Symbols.restore_rounded;

  /// Pull data down from the cloud.
  static const IconData cloudDownload = Symbols.cloud_download_rounded;

  // --- Export and data ---------------------------------------------------

  /// Send data out of the app.
  static const IconData export = Symbols.ios_share_rounded;

  /// A JSON export.
  static const IconData exportJson = Symbols.data_object_rounded;

  /// A CSV export.
  static const IconData exportCsv = Symbols.table_chart_rounded;

  /// The PDF doctor report.
  static const IconData exportPdf = Symbols.picture_as_pdf_rounded;

  /// Save a file to the device.
  static const IconData download = Symbols.download_rounded;

  /// No export matches the filter.
  static const IconData noMatch = Symbols.event_busy_rounded;

  // --- Settings and system -----------------------------------------------

  /// What this app is, and any explanatory note.
  static const IconData info = Symbols.info_rounded;

  /// Something failed and the user is being told — the startup error screen.
  static const IconData error = Symbols.error_rounded;

  /// The privacy policy and the terms.
  static const IconData document = Symbols.description_rounded;

  /// Write to support.
  static const IconData email = Symbols.email_rounded;

  /// The app's language.
  static const IconData language = Symbols.language_rounded;

  /// Dark mode, and the calm-by-default promise.
  static const IconData darkMode = Symbols.dark_mode_rounded;

  /// The iOS home screen widget.
  static const IconData homeWidget = Symbols.widgets_rounded;

  /// A new version is required before the app will run.
  static const IconData appUpdate = Symbols.system_update_alt_rounded;

  /// Start over — the onboarding replay.
  static const IconData reset = Symbols.restart_alt_rounded;

  /// Debug-only tools, never shipped to a user.
  static const IconData devTool = Symbols.science_rounded;
}
