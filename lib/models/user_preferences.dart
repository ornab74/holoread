class UserPreferences {
  const UserPreferences({
    this.preferredGenres = const <String>[],
    this.avoidedGenres = const <String>[],
    this.favoriteAuthors = const <String>[],
    this.preferredBookLength = 360,
    this.preferredDifficulty = 'Medium',
    this.dailyMinutesGoal = 25,
    this.weeklyBooksGoal = 1,
    this.preferredReminderHour = 21,
    this.quietStartHour = 23,
    this.quietEndHour = 8,
    this.maxRemindersPerDay = 2,
    this.currentMood = 'Curious',
    this.learningGoal = '',
  });

  final List<String> preferredGenres;
  final List<String> avoidedGenres;
  final List<String> favoriteAuthors;
  final int preferredBookLength;
  final String preferredDifficulty;
  final int dailyMinutesGoal;
  final int weeklyBooksGoal;
  final int preferredReminderHour;
  final int quietStartHour;
  final int quietEndHour;
  final int maxRemindersPerDay;
  final String currentMood;
  final String learningGoal;
}
