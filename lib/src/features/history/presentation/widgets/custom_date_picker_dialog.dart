import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog>
    with TickerProviderStateMixin {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  bool _showYearPicker = false;
  bool _showManualInput = false;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
    _controller.text = DateFormat("dd/MM/yyyy").format(_selectedDay);
  }

  void _parseManualDate(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length >= 8) {
      final day = int.tryParse(cleaned.substring(0, 2));
      final month = int.tryParse(cleaned.substring(2, 4));
      final year = int.tryParse(cleaned.substring(4, 8));

      if (day != null && month != null && year != null) {
        final newDate = DateTime(year, month, day);
        if (newDate.isAfter(widget.firstDate) &&
            newDate.isBefore(widget.lastDate)) {
          setState(() {
            _selectedDay = newDate;
            _focusedDay = newDate;
            _controller.text =
                DateFormat("dd/MM/yyyy").format(newDate);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildBody(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat("EEE, MMM d").format(_selectedDay),
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () {
            setState(() {
              _showManualInput = !_showManualInput;
              _showYearPicker = false;
            });
          },
        )
      ],
    );
  }

  Widget _buildBody() {
    if (_showManualInput) {
      return TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: "Enter date",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: _parseManualDate,
      );
    }

    if (_showYearPicker) {
      return SizedBox(
        height: 250,
        child: GridView.builder(
          itemCount:
              widget.lastDate.year - widget.firstDate.year + 1,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
          ),
          itemBuilder: (context, index) {
            final year = widget.firstDate.year + index;
            final selected = year == _selectedDay.year;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = DateTime(
                    year,
                    _selectedDay.month,
                    _selectedDay.day,
                  );
                  _focusedDay = _selectedDay;
                  _showYearPicker = false;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF4F8F83)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  "$year",
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFF374151),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return TableCalendar(
      firstDay: widget.firstDate,
      lastDay: widget.lastDate,
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) =>
          isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon:
            const Icon(Icons.chevron_left, color: Colors.grey),
        rightChevronIcon:
            const Icon(Icons.chevron_right, color: Colors.grey),
      ),
      onHeaderTapped: (focusedDay) {
        setState(() {
          _showYearPicker = true;
          _showManualInput = false;
        });
      },
      calendarStyle: const CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Color(0xFF4F8F83),
          shape: BoxShape.circle,
        ),
        selectedTextStyle:
            TextStyle(color: Colors.white),
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xFF4F8F83)),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _selectedDay),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
