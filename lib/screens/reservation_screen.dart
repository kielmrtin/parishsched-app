import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/sacrament_windows.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/availability_calendar.dart';
import '../widgets/boxed_field.dart';
import '../widgets/hero_kicker.dart';
import '../widgets/hero_wave.dart';
import '../widgets/logout_button.dart';
import '../widgets/notification_bell.dart';
import '../widgets/sacrament_badge.dart';

/// Mirrors church-web's Reservation flow (resources/views/reservation/index.blade.php
/// + ReservationController) as closely as a mobile form allows: the same
/// applicant name breakdown, wedding couple + requirements checklist,
/// funeral deceased details, and required-document uploads — written
/// directly to the shared `reservations` / `reservation_attachments`
/// tables and the `reservation-attachments` Storage bucket, the same ones
/// the website itself uses.
///
/// Duplicate-entry and time-slot-conflict checks reproduce the same logic
/// as ReservationController::store. Admin/customer notification emails are
/// no longer sent from Laravel request code at all — a Supabase Database
/// Webhook fires on every `reservations` INSERT (from either this app or
/// the website) and a small Laravel endpoint sends them from there, so no
/// Flutter-side change is needed for this screen to trigger them.
class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

const _weddingRequirementChecklist = {
  'baptismal-certificate': 'Baptismal Certificate (for marriage purposes)',
  'confirmation-certificate': 'Confirmation Certificate (for marriage purposes)',
  'marriage-permit': 'Marriage Permit',
  'marriage-banns': 'Marriage Banns',
  'marriage-license': 'Marriage License',
  'seminar-certificate': 'Certificate of Seminar',
  'sponsors-list': 'Listahan ng Ninong at Ninang (apat na pares na minimum)',
};

const _funeralMaritalStatusOptions = {
  'married_not_baptized': 'Married (not baptized in the church)',
  'single': 'Single / Unmarried',
};

const _baptismNotes = [
  'Choose one godfather and one godmother as major sponsors (proxies are not allowed).',
  'Major sponsors must be practicing Catholics in good standing.',
  'Suggested church donation: P800.',
  'Please bring original documents to the parish office on the day of baptism.',
];

const _typeSubtitles = {
  'wedding': 'Celebrating your union',
  'baptism': 'Welcoming a new soul',
  'funeral': 'Honoring a life lived',
};

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Applicant
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _suffix = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  // Wedding
  final _brideFirst = TextEditingController();
  final _brideMiddle = TextEditingController();
  final _brideLast = TextEditingController();
  final _brideSuffix = TextEditingController();
  final _groomFirst = TextEditingController();
  final _groomMiddle = TextEditingController();
  final _groomLast = TextEditingController();
  final _groomSuffix = TextEditingController();
  DateTime? _seminarDate;
  final _sacramentDetails = TextEditingController();
  final Set<String> _weddingRequirements = {};
  PlatformFile? _weddingFile1;
  PlatformFile? _weddingFile2;

  // Funeral
  final _deceasedFirst = TextEditingController();
  final _deceasedMiddle = TextEditingController();
  final _deceasedLast = TextEditingController();
  final _deceasedSuffix = TextEditingController();
  String? _maritalStatus;
  PlatformFile? _funeralFile;

  // Baptism
  final _childFirst = TextEditingController();
  final _childMiddle = TextEditingController();
  final _childLast = TextEditingController();
  final _childSuffix = TextEditingController();
  DateTime? _childDob;
  final _fatherName = TextEditingController();
  final _motherName = TextEditingController();
  PlatformFile? _baptismFile;

  DateTime? _selectedDate;
  String? _selectedType;
  String? _selectedTime;
  bool _submitting = false;
  String? _extraError;
  Map<String, DayReservationSummary> _reservationsByDate = {};

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefill();
    _loadCalendarData();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _suffix.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    _brideFirst.dispose();
    _brideMiddle.dispose();
    _brideLast.dispose();
    _brideSuffix.dispose();
    _groomFirst.dispose();
    _groomMiddle.dispose();
    _groomLast.dispose();
    _groomSuffix.dispose();
    _sacramentDetails.dispose();
    _deceasedFirst.dispose();
    _deceasedMiddle.dispose();
    _deceasedLast.dispose();
    _deceasedSuffix.dispose();
    _childFirst.dispose();
    _childMiddle.dispose();
    _childLast.dispose();
    _childSuffix.dispose();
    _fatherName.dispose();
    _motherName.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarData() async {
    try {
      final todayStr = _dateKey(DateTime.now());
      final rows = await Supabase.instance.client
          .from('reservations')
          .select('reservation_date,status')
          .gte('reservation_date', todayStr)
          .inFilter('status', ['approved', 'pending']);

      final map = <String, DayReservationSummary>{};
      for (final r in (rows as List)) {
        final date = r['reservation_date'] as String?;
        final status = (r['status'] as String?)?.toLowerCase();
        if (date == null || status == null) continue;
        final existing = map[date] ?? const DayReservationSummary();
        map[date] = DayReservationSummary(
          approvedCount: existing.approvedCount + (status == 'approved' ? 1 : 0),
          pendingCount: existing.pendingCount + (status == 'pending' ? 1 : 0),
        );
      }
      if (!mounted) return;
      setState(() => _reservationsByDate = map);
    } catch (_) {
      // Calendar dots are a nice-to-have; silently skip if the fetch fails.
    }
  }

  Future<void> _loadPrefill() async {
    final user = AuthService().currentUser;
    _email.text = user?.email ?? '';
    final metaName = (user?.userMetadata?['full_name'] as String?)?.trim();
    var name = metaName ?? '';

    final customer = await AuthService().fetchCurrentCustomer();
    if (name.isEmpty) name = (customer?['name'] as String?)?.trim() ?? '';
    if (!mounted) return;
    setState(() {
      final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) _firstName.text = parts.first;
      if (parts.length > 1) _lastName.text = parts.last;
      if (parts.length > 2) _middleName.text = parts.sublist(1, parts.length - 1).join(' ');
      _phone.text = (customer?['phone'] as String?)?.trim() ?? '';
    });
  }

  String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _normalizeTime(String s) => s.toLowerCase().trim().replaceAll('–', '-');

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _fullName(String first, String middle, String last, String suffix) {
    return [first, middle, last, suffix].map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');
  }

  /// Same red-header/day-grid calendar used for picking the reservation
  /// date itself, so the seminar-date picker matches the rest of the app
  /// instead of Flutter's default system date picker. Mirrors church-web's
  /// getWeddingSeminarRange() (public/js/reservations.js): the seminar must
  /// fall 1-5 days before the chosen wedding date.
  Future<DateTime?> _pickSeminarDate(BuildContext context) {
    DateTime? picked = _seminarDate;
    final weddingDate = _selectedDate!;
    final minDate = weddingDate.subtract(const Duration(days: 5));
    final maxDate = weddingDate.subtract(const Duration(days: 1));
    if (picked == null || picked.isBefore(minDate) || picked.isAfter(maxDate)) {
      picked = null;
    }
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select seminar date',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AvailabilityCalendar(
                      selectedDate: picked,
                      reservationsByDate: const {},
                      showLegend: false,
                      minSelectableDate: minDate,
                      maxSelectableDate: maxDate,
                      onDateSelected: (d) => setSheetState(() => picked = d),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Must be between ${_formatDate(minDate)} and ${_formatDate(maxDate)}.',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: picked == null ? null : () => Navigator.of(sheetContext).pop(picked),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm Date',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// A birth date can be decades in the past with no fixed window, so this
  /// relies on the calendar's own month/year quick-jump (tap the month or
  /// year in its header) rather than paging one month at a time.
  /// [AvailabilityCalendar.disablePastDates] is flipped off here — a
  /// birthday is exactly the kind of date that's normally blocked.
  Future<DateTime?> _pickDateOfBirth(BuildContext context) {
    DateTime? picked = _childDob;
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select child's date of birth",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AvailabilityCalendar(
                      selectedDate: picked,
                      reservationsByDate: const {},
                      showLegend: false,
                      disablePastDates: false,
                      minSelectableDate: DateTime(1900),
                      maxSelectableDate: DateTime.now(),
                      onDateSelected: (d) => setSheetState(() => picked = d),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: picked == null ? null : () => Navigator.of(sheetContext).pop(picked),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm Date',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _resetTypeSpecificFields() {
    _brideFirst.clear();
    _brideMiddle.clear();
    _brideLast.clear();
    _brideSuffix.clear();
    _groomFirst.clear();
    _groomMiddle.clear();
    _groomLast.clear();
    _groomSuffix.clear();
    _seminarDate = null;
    _sacramentDetails.clear();
    _weddingRequirements.clear();
    _weddingFile1 = null;
    _weddingFile2 = null;
    _deceasedFirst.clear();
    _deceasedMiddle.clear();
    _deceasedLast.clear();
    _deceasedSuffix.clear();
    _maritalStatus = null;
    _funeralFile = null;
    _childFirst.clear();
    _childMiddle.clear();
    _childLast.clear();
    _childSuffix.clear();
    _childDob = null;
    _fatherName.clear();
    _motherName.clear();
    _baptismFile = null;
    _extraError = null;
  }

  Future<PlatformFile?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  /// Validates the parts of the form a plain [Form] can't (files, checkbox
  /// groups, dropdowns) — mirrors the `data-wedding-required` /
  /// `data-funeral-required` attributes on church-web's own fields.
  String? _validateExtra() {
    if (_selectedType == 'wedding') {
      if (_groomFirst.text.trim().isEmpty || _groomLast.text.trim().isEmpty) {
        return "Please enter the groom's first and last name.";
      }
      if (_brideFirst.text.trim().isEmpty || _brideLast.text.trim().isEmpty) {
        return "Please enter the bride's first and last name.";
      }
      if (_seminarDate == null) return 'Please select a seminar date.';
      if (_weddingRequirements.length < _weddingRequirementChecklist.length) {
        return 'Please confirm all wedding requirements.';
      }
      if (_weddingFile1 == null || _weddingFile2 == null) {
        return 'Please upload both wedding requirement documents.';
      }
    } else if (_selectedType == 'baptism') {
      if (_childFirst.text.trim().isEmpty || _childLast.text.trim().isEmpty) {
        return "Please enter the child's first and last name.";
      }
      if (_childDob == null) return "Please enter the child's date of birth.";
      if (_fatherName.text.trim().isEmpty || _motherName.text.trim().isEmpty) {
        return "Please enter the parents' full names.";
      }
      if (_baptismFile == null) return 'Please upload the baptism document.';
    } else if (_selectedType == 'funeral') {
      if (_deceasedFirst.text.trim().isEmpty || _deceasedLast.text.trim().isEmpty) {
        return 'Please enter the first and last name of the deceased.';
      }
      if (_maritalStatus == null) return 'Please select the marital status of the deceased.';
      if (_funeralFile == null) return 'Please upload the funeral document.';
    }
    return null;
  }

  Future<void> _openDateSheet(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _selectedType = null;
      _selectedTime = null;
      _resetTypeSpecificFields();
    });

    // Snapshot of everyone already booked on this date, so the time list can
    // show which slots are taken instead of only failing at final submit.
    List<Map<String, dynamic>> dayReservations = [];
    try {
      final rows = await Supabase.instance.client
          .from('reservations')
          .select('event_type,reservation_time,status')
          .eq('reservation_date', _dateKey(date))
          .inFilter('status', ['approved', 'pending', 'booked']);
      dayReservations = (rows as List).cast<Map<String, dynamic>>();
    } catch (_) {
      // Best-effort — if this fails, slots just show as available; the
      // conflict check at submit time still guards against double-booking.
    }

    // Baptism is a group slot (up to 5), so it shows a running "3/5 booked"
    // count instead of a flat booked/available flag — mirrors the website's
    // reservations.js ("(" + baptismBookingCount + "/5 booked)").
    int? baptismCountFor(SacramentWindow w) {
      if (w.type != 'baptism') return null;
      final selNorm = _normalizeTime(w.time);
      return dayReservations.where((r) {
        return (r['event_type'] as String?)?.toLowerCase() == 'baptism' &&
            _normalizeTime((r['reservation_time'] as String?) ?? '') == selNorm;
      }).length;
    }

    bool isWindowBooked(SacramentWindow w) {
      final selNorm = _normalizeTime(w.time);
      final sameTimeSlot = dayReservations
          .where((r) => _normalizeTime((r['reservation_time'] as String?) ?? '') == selNorm)
          .toList();
      if (w.type == 'baptism') {
        final baptismsAtTime =
            sameTimeSlot.where((r) => (r['event_type'] as String?)?.toLowerCase() == 'baptism').toList();
        final otherAtTime =
            sameTimeSlot.where((r) => (r['event_type'] as String?)?.toLowerCase() != 'baptism').toList();
        return baptismsAtTime.length >= 5 || otherAtTime.isNotEmpty;
      }
      return sameTimeSlot.isNotEmpty;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final matchingWindows = _selectedType == null
                ? const <SacramentWindow>[]
                : sacramentWindows
                      .where(
                        (w) => w.type == _selectedType && w.weekdays.contains(date.weekday),
                      )
                      .toList();
            final readyToSubmit = _selectedType != null && _selectedTime != null;

            Future<void> pickInto(void Function(PlatformFile) assign) async {
              final f = await _pickFile();
              if (f != null) setSheetState(() => assign(f));
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _RedSectionLabel('Choose a sacrament'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final t in const ['wedding', 'baptism', 'funeral']) ...[
                                Expanded(
                                  child: _TypeCard(
                                    type: t,
                                    selected: _selectedType == t,
                                    onTap: () => setSheetState(() {
                                      _selectedType = t;
                                      _selectedTime = null;
                                      _resetTypeSpecificFields();
                                    }),
                                  ),
                                ),
                                if (t != 'funeral') const SizedBox(width: 10),
                              ],
                            ],
                          ),
                          if (_selectedType != null) ...[
                            const SizedBox(height: 22),
                            const _RedSectionLabel('Available times'),
                            const SizedBox(height: 12),
                            if (matchingWindows.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.scaffold,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'No ${typeLabel(_selectedType!).toLowerCase()} time windows are offered on this day of the week. Please choose another date.',
                                  style: const TextStyle(fontSize: 13, height: 1.55, color: AppColors.inkSoft),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  for (final w in matchingWindows) ...[
                                    _TimeOption(
                                      window: w,
                                      selected: _selectedTime == w.time,
                                      booked: isWindowBooked(w),
                                      baptismCount: baptismCountFor(w),
                                      onTap: () => setSheetState(() => _selectedTime = w.time),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                          ],
                          if (readyToSubmit) ...[
                            const SizedBox(height: 22),
                            const _RedSectionLabel('Your information'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: BoxedField(
                                    controller: _firstName,
                                    label: 'FIRST NAME',
                                    required: true,
                                    hint: 'First name',
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: BoxedField(
                                    controller: _lastName,
                                    label: 'LAST NAME',
                                    required: true,
                                    hint: 'Last name',
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: BoxedField(
                                    controller: _middleName,
                                    label: 'MIDDLE NAME',
                                    hint: 'Optional',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: BoxedField(
                                    controller: _suffix,
                                    label: 'SUFFIX',
                                    hint: 'Jr., III, etc.',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            BoxedField(
                              controller: _email,
                              label: 'EMAIL',
                              required: true,
                              hint: 'name@example.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter your email.';
                                if (!v.contains('@')) return 'Please enter a valid email.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            BoxedField(
                              controller: _phone,
                              label: 'CONTACT NUMBER',
                              required: true,
                              hint: '(042) 545-9244',
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Please enter your contact number.'
                                  : null,
                            ),
                            if (_selectedType == 'wedding') ...[
                              const SizedBox(height: 24),
                              _PersonNameFields(
                                title: "Groom's name",
                                first: _groomFirst,
                                middle: _groomMiddle,
                                last: _groomLast,
                                suffix: _groomSuffix,
                              ),
                              const SizedBox(height: 18),
                              _PersonNameFields(
                                title: "Bride's name",
                                first: _brideFirst,
                                middle: _brideMiddle,
                                last: _brideLast,
                                suffix: _brideSuffix,
                              ),
                              const SizedBox(height: 18),
                              const _RedSectionLabel('Pre-Cana seminar date'),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await _pickSeminarDate(context);
                                  if (picked != null) setSheetState(() => _seminarDate = picked);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _seminarDate == null ? 'MM/DD/YYYY' : _formatDate(_seminarDate!),
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            color: _seminarDate == null ? Colors.grey.shade400 : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade500),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Must be between one and five days before your wedding.',
                                style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                              ),
                              const SizedBox(height: 18),
                              const _RedSectionLabel('Kumpisal / Kumpil / Binyag details'),
                              const SizedBox(height: 12),
                              BoxedField(
                                controller: _sacramentDetails,
                                label: '',
                                hint: 'Parishes or dates for confession, confirmation, and baptism',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 20),
                              const _RedSectionLabel('Mga kailangan bago ikasal'),
                              const SizedBox(height: 8),
                              const Text(
                                'Confirm you have prepared the following requirements.',
                                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                              ),
                              const SizedBox(height: 8),
                              for (final entry in _weddingRequirementChecklist.entries)
                                _CheckRow(
                                  label: entry.value,
                                  checked: _weddingRequirements.contains(entry.key),
                                  onChanged: (v) => setSheetState(() {
                                    if (v) {
                                      _weddingRequirements.add(entry.key);
                                    } else {
                                      _weddingRequirements.remove(entry.key);
                                    }
                                  }),
                                ),
                              const SizedBox(height: 20),
                              const _RedSectionLabel('Required wedding documents'),
                              const SizedBox(height: 8),
                              const Text(
                                'Upload scanned copies of the following pre-marriage requirements. Accepted formats: PDF, JPG, PNG (max 5MB each).',
                                style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.inkSoft),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.scaffold,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FilePickerField(
                                      label: 'Wedding Requirement 1 / Baptismal certificate',
                                      file: _weddingFile1,
                                      onPick: () => pickInto((f) => _weddingFile1 = f),
                                    ),
                                    const SizedBox(height: 14),
                                    _FilePickerField(
                                      label: 'Wedding Requirement 2 / Marriage license or seminar certificate',
                                      file: _weddingFile2,
                                      onPick: () => pickInto((f) => _weddingFile2 = f),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Submit photocopies with the original documents to the parish office when requested.',
                                      style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_selectedType == 'baptism') ...[
                              const SizedBox(height: 24),
                              _PersonNameFields(
                                title: "Child's information",
                                first: _childFirst,
                                middle: _childMiddle,
                                last: _childLast,
                                suffix: _childSuffix,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'DATE OF BIRTH',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await _pickDateOfBirth(context);
                                  if (picked != null) setSheetState(() => _childDob = picked);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _childDob == null ? 'MM/DD/YYYY' : _formatDate(_childDob!),
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            color: _childDob == null ? Colors.grey.shade400 : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade500),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const _RedSectionLabel('Parents'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: BoxedField(
                                      controller: _fatherName,
                                      label: "FATHER'S FULL NAME",
                                      hint: 'Full name',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: BoxedField(
                                      controller: _motherName,
                                      label: "MOTHER'S FULL NAME",
                                      hint: 'Full name',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const _RedSectionLabel('Required baptism documents'),
                              const SizedBox(height: 8),
                              const Text(
                                'Upload clear scans or photos of the following requirements. Accepted formats: PDF, JPG, PNG (max 5MB each).',
                                style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.inkSoft),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.scaffold,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FilePickerField(
                                      label: 'Birth certificate / Baptism document (PDF, JPG, PNG)',
                                      file: _baptismFile,
                                      onPick: () => pickInto((f) => _baptismFile = f),
                                    ),
                                    const SizedBox(height: 12),
                                    for (final n in _baptismNotes) _NoteBullet(n),
                                  ],
                                ),
                              ),
                            ],
                            if (_selectedType == 'funeral') ...[
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.scaffold,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionLabel('Funeral information'),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Arrange the funeral schedule at the parish office at least one day before burial.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFFB45309),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'NAME OF THE DECEASED',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: BoxedField(controller: _deceasedFirst, label: 'FIRST', hint: 'First')),
                                        const SizedBox(width: 10),
                                        Expanded(child: BoxedField(controller: _deceasedMiddle, label: 'MIDDLE', hint: 'Middle')),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: BoxedField(controller: _deceasedLast, label: 'LAST', hint: 'Last')),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: BoxedField(
                                            controller: _deceasedSuffix,
                                            label: 'SUFFIX (OPTIONAL)',
                                            hint: 'Optional',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'MARITAL STATUS OF THE DECEASED',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _maritalStatus,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        hintText: 'Select status',
                                        hintStyle: TextStyle(fontSize: 14.5, color: Colors.grey.shade400),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: AppColors.border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
                                        ),
                                      ),
                                      items: [
                                        for (final entry in _funeralMaritalStatusOptions.entries)
                                          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                                      ],
                                      onChanged: (v) => setSheetState(() => _maritalStatus = v),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const _RedSectionLabel('Required funeral documents'),
                              const SizedBox(height: 8),
                              const Text(
                                'Upload the document that matches the marital status selected above. Accepted formats: PDF, JPG, PNG (max 5MB).',
                                style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.inkSoft),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.scaffold,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: _FilePickerField(
                                  label: 'Funeral document / Marriage contract or baptismal certificate',
                                  file: _funeralFile,
                                  onPick: () => pickInto((f) => _funeralFile = f),
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            const _RedSectionLabel('Additional notes'),
                            const SizedBox(height: 12),
                            BoxedField(
                              controller: _notes,
                              label: 'NOTES',
                              hint: 'Tell us about your celebration',
                              maxLines: 4,
                              textInputAction: TextInputAction.done,
                            ),
                            if (_extraError != null) ...[
                              const SizedBox(height: 14),
                              Text(
                                _extraError!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _submit(sheetContext, setSheetState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brand,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  elevation: 0,
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                      )
                                    : const Text('SUBMIT RESERVATION REQUEST'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Mirrors ReservationController::store's `$folder = strtolower($event_type)`
  /// prefix, so app uploads land in the same wedding/baptism/funeral
  /// folders as website uploads instead of sitting flat at the bucket root.
  Future<void> _uploadAttachment(
    int reservationId,
    PlatformFile file,
    String fieldKey,
    String label,
    String type,
  ) async {
    final bytes = file.bytes;
    if (bytes == null) return;
    final storage = Supabase.instance.client.storage.from('reservation-attachments');
    final fileName = '$type/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    await storage.uploadBinary(fileName, bytes);
    final url = storage.getPublicUrl(fileName);
    await Supabase.instance.client.from('reservation_attachments').insert({
      'reservation_id': reservationId,
      'file_url': url,
      'field_key': fieldKey,
      'label': label,
    });
  }

  Future<void> _submit(BuildContext sheetContext, StateSetter setSheetState) async {
    if (_selectedDate == null || _selectedType == null || _selectedTime == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final extraError = _validateExtra();
    if (extraError != null) {
      setSheetState(() => _extraError = extraError);
      return;
    }
    setSheetState(() {
      _extraError = null;
      _submitting = true;
    });

    final client = Supabase.instance.client;
    final dateStr = _dateKey(_selectedDate!);
    final email = _email.text.trim();
    final type = _selectedType!;
    final time = _selectedTime!;
    final fullName = _fullName(_firstName.text, _middleName.text, _lastName.text, _suffix.text);

    try {
      final dup = await client
          .from('reservations')
          .select('id,status')
          .eq('email', email)
          .eq('event_type', type)
          .eq('reservation_date', dateStr)
          .inFilter('status', ['approved', 'pending', 'booked']);

      if ((dup as List).isNotEmpty) {
        final status = (dup.first['status'] as String?) ?? 'pending';
        if (!mounted) return;
        await showAppAlert(
          context,
          type: AppAlertType.warning,
          title: 'Already Reserved',
          message:
              'You already have a ${_cap(status)} ${typeLabel(type)} reservation on this date. Please contact the parish office if you need to make changes.',
        );
        return;
      }

      final sameDate = await client
          .from('reservations')
          .select('id,event_type,reservation_time,status')
          .eq('reservation_date', dateStr)
          .inFilter('status', ['approved', 'pending', 'booked']);

      final selNorm = _normalizeTime(time);
      final sameTimeSlot = (sameDate as List).where((r) {
        return _normalizeTime((r['reservation_time'] as String?) ?? '') == selNorm;
      }).toList();

      if (type == 'baptism') {
        final baptismsAtTime = sameTimeSlot
            .where((r) => (r['event_type'] as String?)?.toLowerCase() == 'baptism')
            .toList();
        if (baptismsAtTime.length >= 5) {
          if (!mounted) return;
          await showAppAlert(
            context,
            type: AppAlertType.warning,
            title: 'Time Slot Full',
            message: 'Baptism slots for this time are full (max 5). Please choose another date.',
          );
          return;
        }
        final otherAtTime = sameTimeSlot
            .where((r) => (r['event_type'] as String?)?.toLowerCase() != 'baptism')
            .toList();
        if (otherAtTime.isNotEmpty) {
          if (!mounted) return;
          await showAppAlert(
            context,
            type: AppAlertType.warning,
            title: 'Time Slot Taken',
            message: 'This time slot is already reserved for another event. Please choose a different time.',
          );
          return;
        }
      } else if (sameTimeSlot.isNotEmpty) {
        final conflictType = (sameTimeSlot.first['event_type'] as String?) ?? 'event';
        if (!mounted) return;
        await showAppAlert(
          context,
          type: AppAlertType.warning,
          title: 'Time Slot Taken',
          message:
              'This time slot already has a ${_cap(conflictType)} reservation. Please choose another available time.',
        );
        return;
      }

      // `customers` itself is locked down to "your own row only" via RLS, and
      // this lookup is intentionally for *whatever* email was typed into the
      // form (not necessarily the signed-in user's own — you can reserve on
      // behalf of someone else). A narrow security-definer function returns
      // just the id, nothing else, without needing to open the table itself.
      final customerId = await client.rpc(
        'get_customer_id_by_email',
        params: {'p_email': email},
      );

      final notes = _notes.text.trim();
      final details = <String, dynamic>{
        'name': fullName,
        'first_name': _firstName.text.trim(),
        'middle_name': _middleName.text.trim(),
        'last_name': _lastName.text.trim(),
        'suffix': _suffix.text.trim(),
        'email': email,
        'phone': _phone.text.trim(),
        'notes': notes,
      };
      if (type == 'wedding') {
        details.addAll({
          'bride_name': _fullName(_brideFirst.text, _brideMiddle.text, _brideLast.text, _brideSuffix.text),
          'groom_name': _fullName(_groomFirst.text, _groomMiddle.text, _groomLast.text, _groomSuffix.text),
          'seminar_date': _seminarDate == null ? null : _dateKey(_seminarDate!),
          'sacrament_details': _sacramentDetails.text.trim(),
          'requirements_confirmed': _weddingRequirements.toList(),
        });
      } else if (type == 'funeral') {
        details.addAll({
          'deceased_name': _fullName(
            _deceasedFirst.text,
            _deceasedMiddle.text,
            _deceasedLast.text,
            _deceasedSuffix.text,
          ),
          'marital_status': _maritalStatus,
        });
      } else if (type == 'baptism') {
        details.addAll({
          'child_name': _fullName(_childFirst.text, _childMiddle.text, _childLast.text, _childSuffix.text),
          'child_dob': _childDob == null ? null : _dateKey(_childDob!),
          'father_name': _fatherName.text.trim(),
          'mother_name': _motherName.text.trim(),
        });
      }

      final inserted = await client
          .from('reservations')
          .insert({
            'customer_id': customerId,
            'name': fullName,
            'email': email,
            'phone': _phone.text.trim(),
            'notes': notes.isEmpty ? null : notes,
            'event_type': type,
            'reservation_date': dateStr,
            'reservation_time': time,
            'status': 'pending',
            'details': details,
          })
          .select('id')
          .single();

      final reservationId = inserted['id'] as int;

      if (type == 'wedding') {
        if (_weddingFile1 != null) {
          await _uploadAttachment(reservationId, _weddingFile1!, 'wedding_file1', 'Wedding Requirement 1', type);
        }
        if (_weddingFile2 != null) {
          await _uploadAttachment(reservationId, _weddingFile2!, 'wedding_file2', 'Wedding Requirement 2', type);
        }
      } else if (type == 'baptism' && _baptismFile != null) {
        await _uploadAttachment(reservationId, _baptismFile!, 'baptism_file', 'Baptism requirement', type);
      } else if (type == 'funeral' && _funeralFile != null) {
        await _uploadAttachment(reservationId, _funeralFile!, 'funeral_file', 'Funeral requirement', type);
      }

      if (!mounted) return;
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      await showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Reservation Submitted',
        message: 'Your reservation request has been submitted successfully. Please wait for parish confirmation.',
      );
      _loadCalendarData();
    } catch (e) {
      if (!mounted) return;
      await showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'Something Went Wrong',
        message: 'We could not submit your reservation right now. Please try again later.',
      );
    } finally {
      // On success the sheet is already popped (and its StatefulBuilder
      // disposed) by the time this runs — only the error path still needs
      // the spinner turned off.
      if (sheetContext.mounted) setSheetState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ParishSched'),
        automaticallyImplyLeading: false,
        actions: const [NotificationBell(), SizedBox(width: 4), LogoutButton()],
      ),
      bottomNavigationBar: const AppBottomNav(current: null),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Hero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
              child: AvailabilityCalendar(
                selectedDate: _selectedDate,
                reservationsByDate: _reservationsByDate,
                onDateSelected: _openDateSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/reservation.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F0508).withValues(alpha: 0.82),
                  const Color(0xFF6E0F1C).withValues(alpha: 0.78),
                  const Color(0xFF0F0508).withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeroKicker(icon: Icons.event_available_outlined, label: 'PARISH RESERVATIONS'),
              const SizedBox(height: 14),
              const Text(
                'Reserve a sacrament',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pick an open date on the calendar below to begin your reservation request.',
                style: TextStyle(fontSize: 13.5, height: 1.6, color: Colors.white),
              ),
            ],
          ),
        ),
        const Positioned(left: 0, right: 0, bottom: -1, child: HeroWave()),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
    );
  }
}

/// Red uppercase label with a trailing divider line — matches church-web's
/// `.res-section-lbl` (used for "Your Information", "Available Times",
/// "Groom's Name", "Required Wedding Documents", etc). "Funeral information"
/// is deliberately excluded on the website (a plain `<h6>` there instead),
/// so it keeps using [_SectionLabel].
class _RedSectionLabel extends StatelessWidget {
  final String text;
  const _RedSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.1,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(height: 1, color: AppColors.border)),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = typeAccent(type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? typeBg(type) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? accent : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            typeIcon(type, size: 22, color: accent),
            const SizedBox(height: 8),
            Text(
              typeLabel(type),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: selected ? accent : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _typeSubtitles[type] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeOption extends StatelessWidget {
  final SacramentWindow window;
  final bool selected;
  final bool booked;
  final int? baptismCount;
  final VoidCallback onTap;
  const _TimeOption({
    required this.window,
    required this.selected,
    required this.onTap,
    this.booked = false,
    this.baptismCount,
  });

  @override
  Widget build(BuildContext context) {
    final accent = typeAccent(window.type);
    final showBaptismCount = baptismCount != null && baptismCount! > 0;
    final timeLabel = showBaptismCount ? '${window.time} ($baptismCount/5 booked)' : window.time;
    return GestureDetector(
      onTap: booked ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: booked
              ? Colors.grey.shade100
              : (selected ? typeBg(window.type) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: booked ? AppColors.border : (selected ? accent : AppColors.border),
            width: selected && !booked ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              booked
                  ? Icons.block
                  : (selected ? Icons.radio_button_checked : Icons.radio_button_off),
              size: 19,
              color: booked ? Colors.grey.shade400 : (selected ? accent : Colors.grey.shade400),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: booked ? Colors.grey.shade500 : AppColors.ink,
                    ),
                  ),
                  Text(
                    window.title,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: booked ? Colors.grey.shade400 : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (booked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Booked',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PersonNameFields extends StatelessWidget {
  final String title;
  final TextEditingController first;
  final TextEditingController middle;
  final TextEditingController last;
  final TextEditingController suffix;
  const _PersonNameFields({
    required this.title,
    required this.first,
    required this.middle,
    required this.last,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final row1 = [
      Expanded(child: BoxedField(controller: first, label: 'FIRST', hint: 'First')),
      const SizedBox(width: 10),
      Expanded(child: BoxedField(controller: last, label: 'LAST', hint: 'Last')),
    ];
    final row2 = [
      Expanded(child: BoxedField(controller: middle, label: 'MIDDLE', hint: 'Optional')),
      const SizedBox(width: 10),
      Expanded(child: BoxedField(controller: suffix, label: 'SUFFIX', hint: 'Optional')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RedSectionLabel(title),
        const SizedBox(height: 12),
        Row(children: row1),
        const SizedBox(height: 12),
        Row(children: row2),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  const _CheckRow({required this.label, required this.checked, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: checked ? AppColors.brand : Colors.grey.shade400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 12.8, height: 1.4, color: AppColors.ink)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteBullet extends StatelessWidget {
  final String text;
  const _NoteBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 4, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.inkSoft)),
          ),
        ],
      ),
    );
  }
}

class _FilePickerField extends StatelessWidget {
  final String label;
  final PlatformFile? file;
  final VoidCallback onPick;
  const _FilePickerField({required this.label, required this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
            children: const [TextSpan(text: ' *', style: TextStyle(color: AppColors.brand))],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: file == null ? AppColors.border : AppColors.brand),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  file == null ? Icons.upload_file_outlined : Icons.check_circle,
                  size: 18,
                  color: file == null ? Colors.grey.shade500 : AppColors.brand,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file?.name ?? 'PDF, JPG, or PNG · max 5MB',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: file == null ? Colors.grey.shade400 : AppColors.ink,
                      fontWeight: file == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  file == null ? 'CHOOSE' : 'CHANGE',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.brand),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
