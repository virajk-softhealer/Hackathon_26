String formatShortDate(DateTime date) => '${date.day} ${monthName(date)}';

String formatFullDate(DateTime date) =>
    '${date.day} ${monthName(date)} ${date.year}';

String monthName(DateTime date) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][date.month - 1];
