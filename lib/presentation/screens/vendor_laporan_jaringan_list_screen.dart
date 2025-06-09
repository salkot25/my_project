import 'package:flutter/material.dart';
import 'package:my_project/presentation/widgets/vendor_laporan_jaringan_history_list.dart';
import 'package:table_calendar/table_calendar.dart';

class VendorLaporanJaringanListScreen extends StatefulWidget {
  static const String routeName = '/vendor-laporan-jaringan';
  const VendorLaporanJaringanListScreen({super.key});

  @override
  State<VendorLaporanJaringanListScreen> createState() =>
      _VendorLaporanJaringanListScreenState();
}

class _VendorLaporanJaringanListScreenState
    extends State<VendorLaporanJaringanListScreen> {
  DateTime? selectedDate;
  CalendarFormat calendarFormat = CalendarFormat.week;
  String searchQuery = '';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Laporan Vendor'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari laporan... (nama, alamat, dsb)',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.blueGrey.shade400,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue.shade100),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                              width: 1.5,
                            ),
                          ),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(
                      calendarFormat == CalendarFormat.month
                          ? Icons.calendar_today
                          : Icons.calendar_today,
                      color: Colors.blue.shade700,
                    ),
                    label: Text(
                      calendarFormat == CalendarFormat.week
                          ? 'Mingguan'
                          : 'Bulanan',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        calendarFormat = calendarFormat == CalendarFormat.month
                            ? CalendarFormat.week
                            : CalendarFormat.month;
                      });
                    },
                  ),
                ],
              ),
              TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: selectedDate ?? DateTime.now(),
                selectedDayPredicate: (day) =>
                    selectedDate != null &&
                    day.year == selectedDate!.year &&
                    day.month == selectedDate!.month &&
                    day.day == selectedDate!.day,
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDate = selected;
                  });
                },
                calendarFormat: calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    calendarFormat = format;
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.blue.shade700,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.blue.shade700,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                  weekdayStyle: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendTextStyle: TextStyle(color: Colors.red.shade400),
                  defaultTextStyle: TextStyle(color: Colors.blueGrey.shade900),
                  outsideDaysVisible: false,
                ),
                availableGestures: AvailableGestures.horizontalSwipe,
                pageAnimationEnabled: true,
                pageAnimationCurve: Curves.easeInOut,
                pageAnimationDuration: const Duration(milliseconds: 350),
              ),
              const SizedBox(height: 16),
              VendorLaporanJaringanHistoryList(
                selectedDate: selectedDate,
                searchQuery: searchQuery,
                isMonthly: calendarFormat == CalendarFormat.month,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
