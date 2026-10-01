import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// How many approved/pending reservations already exist on a given date —
/// drives the dot color, mirroring church-web's own availability calendar
/// (public/js/reservations.js: approved > 0 = red "Booked", else pending > 0
/// = amber "Pending").
class DayReservationSummary {
  final int approvedCount;
  final int pendingCount;
  const DayReservationSummary({this.approvedCount = 0, this.pendingCount = 0});
}

enum _CalView { day, month, year }

/// Month-grid calendar with a red header (matching church-web's
/// `.res-page-bar` / calendar host styling) and colored dot indicators:
/// green = today, amber = a pending reservation exists, red = an approved
/// reservation exists, gray = past date (not selectable).
///
/// Tapping the month or year in the header drills into a month-grid or
/// year-grid picker (mirroring church-web's own `dob-cal` widget —
/// public/js/reservations.js's dobCalSetView('month'/'year')), so jumping
/// to a date months or years away doesn't require paging one month at a
/// time.
class AvailabilityCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<String, DayReservationSummary> reservationsByDate;
  final bool showLegend;
  final DateTime? minSelectableDate;
  final DateTime? maxSelectableDate;
  /// True (default) blocks dates before today — the usual "book a future
  /// date" calendar. Set false for things like a birth date, where past
  /// dates are exactly what's selectable and today/future should be
  /// blocked instead (via [maxSelectableDate]).
  final bool disablePastDates;

  const AvailabilityCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.reservationsByDate,
    this.showLegend = true,
    this.minSelectableDate,
    this.maxSelectableDate,
    this.disablePastDates = true,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _visibleMonth;
  _CalView _view = _CalView.day;
  late int _yearRangeStart;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  void initState() {
    super.initState();
    final base = widget.selectedDate ?? widget.minSelectableDate ?? DateTime.now();
    _visibleMonth = DateTime(base.year, base.month);
    _yearRangeStart = _visibleMonth.year - 10;
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _canGoPrev {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final lastDayOfPrev = DateTime(prev.year, prev.month + 1, 0);
    if (widget.disablePastDates) {
      final notBeforeToday = lastDayOfPrev.isAfter(_today) || _isSameDay(lastDayOfPrev, _today);
      if (!notBeforeToday) return false;
    }
    if (widget.minSelectableDate == null) return true;
    final min = widget.minSelectableDate!;
    return lastDayOfPrev.isAfter(min) || _isSameDay(lastDayOfPrev, min);
  }

  bool get _canGoNext {
    if (widget.maxSelectableDate == null) return true;
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    final max = widget.maxSelectableDate!;
    return !next.isAfter(DateTime(max.year, max.month));
  }

  void _goPrev() {
    if (!_canGoPrev) return;
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));
  }

  void _goNext() {
    if (!_canGoNext) return;
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));
  }

  bool _monthDisabled(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    if (widget.disablePastDates && lastDay.isBefore(_today)) return true;
    if (widget.minSelectableDate != null && lastDay.isBefore(widget.minSelectableDate!)) return true;
    if (widget.maxSelectableDate != null && firstDay.isAfter(widget.maxSelectableDate!)) return true;
    return false;
  }

  bool _yearDisabled(int year) {
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);
    if (widget.disablePastDates && lastDay.isBefore(_today)) return true;
    if (widget.minSelectableDate != null && lastDay.isBefore(widget.minSelectableDate!)) return true;
    if (widget.maxSelectableDate != null && firstDay.isAfter(widget.maxSelectableDate!)) return true;
    return false;
  }

  bool get _canGoPrevYearPage {
    if (widget.minSelectableDate == null && !widget.disablePastDates) return true;
    final lastYearOfPrevPage = _yearRangeStart - 1;
    if (widget.disablePastDates && lastYearOfPrevPage < _today.year) return false;
    if (widget.minSelectableDate != null && lastYearOfPrevPage < widget.minSelectableDate!.year) return false;
    return true;
  }

  bool get _canGoNextYearPage {
    if (widget.maxSelectableDate == null) return true;
    final firstYearOfNextPage = _yearRangeStart + 12;
    return firstYearOfNextPage <= widget.maxSelectableDate!.year;
  }

  void _openMonthView() => setState(() => _view = _CalView.month);

  void _openYearView() => setState(() {
    _yearRangeStart = _visibleMonth.year - 10;
    _view = _CalView.year;
  });

  void _pickMonth(int month) => setState(() {
    _visibleMonth = DateTime(_visibleMonth.year, month);
    _view = _CalView.day;
  });

  void _pickYear(int year) => setState(() {
    _visibleMonth = DateTime(year, _visibleMonth.month);
    _view = _CalView.month;
  });

  void _goToday() => setState(() {
    final n = DateTime.now();
    _visibleMonth = DateTime(n.year, n.month);
    _view = _CalView.day;
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          switch (_view) {
            _CalView.day => _buildDayView(),
            _CalView.month => _buildMonthView(),
            _CalView.year => _buildYearView(),
          },
        ],
      ),
    );
  }

  Widget _buildHeader() {
    late Widget label;
    late bool canPrev;
    late bool canNext;
    late VoidCallback onPrev;
    late VoidCallback onNext;

    switch (_view) {
      case _CalView.day:
        label = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _openMonthView,
              child: Text(
                _months[_visibleMonth.month - 1],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _openYearView,
              child: Text(
                '${_visibleMonth.year}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        );
        canPrev = _canGoPrev;
        canNext = _canGoNext;
        onPrev = _goPrev;
        onNext = _goNext;
      case _CalView.month:
        label = GestureDetector(
          onTap: _openYearView,
          child: Text(
            '${_visibleMonth.year}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
          ),
        );
        canPrev = !_yearDisabled(_visibleMonth.year - 1) ||
            (widget.minSelectableDate == null && !(widget.disablePastDates && _visibleMonth.year - 1 < _today.year));
        canNext = !_yearDisabled(_visibleMonth.year + 1) ||
            (widget.maxSelectableDate == null);
        onPrev = () => setState(() => _visibleMonth = DateTime(_visibleMonth.year - 1, _visibleMonth.month));
        onNext = () => setState(() => _visibleMonth = DateTime(_visibleMonth.year + 1, _visibleMonth.month));
      case _CalView.year:
        label = Text(
          '$_yearRangeStart–${_yearRangeStart + 11}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
        );
        canPrev = _canGoPrevYearPage;
        canNext = _canGoNextYearPage;
        onPrev = () => setState(() => _yearRangeStart -= 12);
        onNext = () => setState(() => _yearRangeStart += 12);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
      color: AppColors.brand,
      child: Row(
        children: [
          Expanded(child: label),
          _NavButton(icon: Icons.chevron_left, onTap: canPrev ? onPrev : null),
          const SizedBox(width: 8),
          _NavButton(icon: Icons.chevron_right, onTap: canNext ? onNext : null),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7; // 0=Sun

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
          child: Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.82,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox.shrink();
              final day = index - firstWeekday + 1;
              return _DayCell(
                date: DateTime(_visibleMonth.year, _visibleMonth.month, day),
                today: _today,
                selected: widget.selectedDate != null &&
                    _isSameDay(widget.selectedDate!, DateTime(_visibleMonth.year, _visibleMonth.month, day)),
                summary: widget.reservationsByDate[
                    _dateKey(DateTime(_visibleMonth.year, _visibleMonth.month, day))],
                minSelectableDate: widget.minSelectableDate,
                maxSelectableDate: widget.maxSelectableDate,
                disablePastDates: widget.disablePastDates,
                onTap: widget.onDateSelected,
              );
            },
          ),
        ),
        if (widget.showLegend) ...[
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: const [
                _LegendItem(color: Color(0xFF22C55E), label: 'Today'),
                _LegendItem(color: Color(0xFFF59E0B), label: 'Pending'),
                _LegendItem(color: Color(0xFFEF4444), label: 'Has reservation'),
                _LegendItem(color: Color(0xFFCBD5E1), label: 'Past / unavailable'),
              ],
            ),
          ),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final disabled = _monthDisabled(_visibleMonth.year, month);
              final isCurrent = month == _visibleMonth.month;
              return _GridCell(
                label: _monthAbbr[index],
                selected: isCurrent,
                disabled: disabled,
                onTap: disabled ? null : () => _pickMonth(month),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _TodayButton(onTap: _goToday),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildYearView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final year = _yearRangeStart + index;
              final disabled = _yearDisabled(year);
              final isCurrent = year == _visibleMonth.year;
              return _GridCell(
                label: '$year',
                selected: isCurrent,
                disabled: disabled,
                onTap: disabled ? null : () => _pickYear(year),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _TodayButton(onTap: _goToday),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.22 : 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: enabled ? 1 : 0.5), size: 20),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  const _GridCell({required this.label, required this.selected, required this.disabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13.5,
            color: selected ? Colors.white : (disabled ? Colors.grey.shade400 : AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          child: const Text('Today'),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final bool selected;
  final DayReservationSummary? summary;
  final DateTime? minSelectableDate;
  final DateTime? maxSelectableDate;
  final bool disablePastDates;
  final ValueChanged<DateTime> onTap;

  const _DayCell({
    required this.date,
    required this.today,
    required this.selected,
    required this.summary,
    required this.onTap,
    this.minSelectableDate,
    this.maxSelectableDate,
    this.disablePastDates = true,
  });

  bool get _isToday => date.year == today.year && date.month == today.month && date.day == today.day;
  bool get _isPast => disablePastDates && date.isBefore(today);
  bool get _isBeforeMin => minSelectableDate != null && date.isBefore(minSelectableDate!);
  bool get _isAfterMax => maxSelectableDate != null && date.isAfter(maxSelectableDate!);
  bool get _isDisabled => _isPast || _isBeforeMin || _isAfterMax;

  @override
  Widget build(BuildContext context) {
    final hasApproved = (summary?.approvedCount ?? 0) > 0;
    final hasPending = !hasApproved && (summary?.pendingCount ?? 0) > 0;

    Color? bg;
    if (selected) {
      bg = AppColors.brand.withValues(alpha: 0.12);
    } else if (_isToday) {
      bg = const Color(0xFFDCFCE7);
    }

    Color numberColor;
    if (_isDisabled) {
      numberColor = Colors.grey.shade400;
    } else if (_isToday) {
      numberColor = const Color(0xFF15803D);
    } else {
      numberColor = AppColors.ink;
    }

    return GestureDetector(
      onTap: _isDisabled ? null : () => onTap(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: AppColors.brand, width: 1.4) : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 6,
              left: 8,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: numberColor,
                  fontWeight: _isToday ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (_isToday)
              const Positioned(top: 8, right: 8, child: _Dot(color: Color(0xFF22C55E)))
            else if (hasApproved)
              const Positioned(top: 8, right: 8, child: _Dot(color: Color(0xFFEF4444)))
            else if (hasPending)
              const Positioned(top: 8, right: 8, child: _Dot(color: Color(0xFFF59E0B))),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
