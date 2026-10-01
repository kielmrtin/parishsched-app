/// Canonical sacrament time windows — the single source of truth mirroring
/// church-web's static Schedule page (resources/views/schedule/index.blade.php).
/// Used by both the Schedule screen (display) and the Reservation screen
/// (to offer only the time slots valid for the sacrament + weekday chosen).
class SacramentWindow {
  final String type; // 'wedding' | 'baptism' | 'funeral'
  final List<int> weekdays; // DateTime.weekday values (1=Mon .. 7=Sun)
  final String dayChip; // display label, e.g. 'Mon – Sat'
  final String time; // display + stored string, e.g. '7:30 – 10:00 AM'
  final String title;
  final List<String> details;

  const SacramentWindow({
    required this.type,
    required this.weekdays,
    required this.dayChip,
    required this.time,
    required this.title,
    required this.details,
  });
}

const sacramentWindows = [
  SacramentWindow(
    type: 'wedding',
    weekdays: [1, 2, 3, 4, 5, 6],
    dayChip: 'Mon – Sat',
    time: '7:30 – 10:00 AM',
    title: 'Morning Wedding Reservations',
    details: [
      'Primary window for nuptial Masses and church ceremonies.',
      'Submit complete wedding requirements through the reservation form.',
      'Coordinate rehearsal details with the parish office after confirmation.',
    ],
  ),
  SacramentWindow(
    type: 'wedding',
    weekdays: [1, 2, 3, 4, 5, 6],
    dayChip: 'Mon – Sat',
    time: '3:00 – 5:00 PM',
    title: 'Overflow Afternoon Weddings',
    details: [
      'Opens when morning schedules are filled to accommodate additional couples.',
      'Ideal for celebrations needing later preparations or travel time.',
      'Confirm availability with the parish office during your reservation.',
    ],
  ),
  SacramentWindow(
    type: 'baptism',
    weekdays: [6, 7],
    dayChip: 'Sat & Sun',
    time: '11:00 AM – 12:00 PM',
    title: 'Weekend Baptism Celebrations',
    details: [
      'Group baptisms take place after the late morning Mass.',
      'Parents and sponsors should review required documents in advance.',
      'Please arrive early for check-in and catechesis before the rite.',
    ],
  ),
  SacramentWindow(
    type: 'funeral',
    weekdays: [7, 1],
    dayChip: 'Sun & Mon',
    time: '1:00 PM',
    title: 'Afternoon Funeral Masses',
    details: [
      'Select a 1:00 PM or 2:00 PM liturgy when coordinating with the parish office.',
      'Ideal for families expecting out-of-town arrivals on the weekend.',
      'Finalize the reservation at least one day before burial to avoid delays.',
    ],
  ),
  SacramentWindow(
    type: 'funeral',
    weekdays: [7, 1],
    dayChip: 'Sun & Mon',
    time: '2:00 PM',
    title: 'Afternoon Funeral Masses',
    details: [
      'Select a 1:00 PM or 2:00 PM liturgy when coordinating with the parish office.',
      'Ideal for families expecting out-of-town arrivals on the weekend.',
      'Finalize the reservation at least one day before burial to avoid delays.',
    ],
  ),
  SacramentWindow(
    type: 'funeral',
    weekdays: [2, 3, 4, 5, 6],
    dayChip: 'Tue – Sat',
    time: '8:00 AM',
    title: 'Morning Funeral Liturgies',
    details: [
      'Three morning slots are offered for weekday funeral Masses.',
      'Choose the time that best aligns with cemetery or memorial plans.',
      'Share any procession details with the office when submitting documents.',
    ],
  ),
  SacramentWindow(
    type: 'funeral',
    weekdays: [2, 3, 4, 5, 6],
    dayChip: 'Tue – Sat',
    time: '9:00 AM',
    title: 'Morning Funeral Liturgies',
    details: [
      'Three morning slots are offered for weekday funeral Masses.',
      'Choose the time that best aligns with cemetery or memorial plans.',
      'Share any procession details with the office when submitting documents.',
    ],
  ),
  SacramentWindow(
    type: 'funeral',
    weekdays: [2, 3, 4, 5, 6],
    dayChip: 'Tue – Sat',
    time: '10:00 AM',
    title: 'Morning Funeral Liturgies',
    details: [
      'Three morning slots are offered for weekday funeral Masses.',
      'Choose the time that best aligns with cemetery or memorial plans.',
      'Share any procession details with the office when submitting documents.',
    ],
  ),
];
