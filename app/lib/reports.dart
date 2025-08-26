import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'entry.dart';
import 'expenses.dart';
import 'homepage.dart';

class ReportsPage extends StatefulWidget {
  final List<Entry> entries;

  const ReportsPage({Key? key, required this.entries}) : super(key: key);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
        ),
        body: Column(
          children: [
            _buildExpenseChart(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 2,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.paid),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Reports',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyHomePage(),
                  ),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpensesPage(
                      entries: [],
                    ),
                  ),
                );
                break;
              case 2:
                // Stay on Reports Page
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildExpenseChart() {
    double maxValue = _getMaxValue();

    List<String> categories = [];
    List<double> totalAmounts = [];

    widget.entries.forEach((entry) {
      int index = categories.indexOf(entry.category!);

      if (index == -1) {
        categories.add(entry.category!);
        totalAmounts.add(entry.amount!);
      } else {
        totalAmounts[index] += entry.amount!;
      }
    });

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: SideTitles(
                      showTitles: true, reservedSize: 30, margin: 10),
                  rightTitles: SideTitles(showTitles: false),
                  bottomTitles: SideTitles(
                      showTitles: true, getTitles: _getCategory, margin: 10),
                  topTitles: SideTitles(showTitles: false),
                ),
                borderData: FlBorderData(show: true),
                barGroups: _getBarGroups(),
                maxY: maxValue +
                    100, // Added some padding to the chart based on the largest value
              ),
            ),
          ),
          SizedBox(height: 8), // Padding between chart and list
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                String category = categories[index];
                double totalAmount = totalAmounts[index];
                return ListTile(
                  title: Text('$category: \$${totalAmount.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
          SizedBox(
              height: 8), // Padding between Total Expenses and Expenses list
          Text(
            'Total Expenses: \$${_getTotalExpenses().toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, // Centered the total expenses text
          ),
          SizedBox(
              height:
                  16), // Padding between Total Expenses and bottom navigation bar
        ],
      ),
    );
  }

  double _getMaxValue() {
    //Method to calculate the largest value in the chart
    double maxValue = 0.0;

    for (Entry entry in widget.entries) {
      if (entry.amount! > maxValue) {
        maxValue = entry.amount!;
      }
    }

    return maxValue;
  }

  List<BarChartGroupData> _getBarGroups() {
    List<BarChartGroupData> barGroups = [];
    List<String> categories = [];
    List<double> totalAmounts = [];

    widget.entries.forEach((entry) {
      int index = categories.indexOf(entry.category!);

      if (index == -1) {
        categories.add(entry.category!);
        totalAmounts.add(entry.amount!);
      } else {
        totalAmounts[index] += entry.amount!;
      }
    });

    for (int i = 0; i < categories.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 8,
          barRods: [
            BarChartRodData(
              y: totalAmounts[i],
              colors: [Colors.blue],
              width: 16,
            ),
          ],
          showingTooltipIndicators: [],
        ),
      );
    }

    return barGroups;
  }

  String _getCategory(double value) {
    List<String> categories = [];

    widget.entries.forEach((entry) {
      if (!categories.contains(entry.category)) {
        categories.add(entry.category!);
      }
    });

    if (!value.isFinite || value < 0 || value >= categories.length) {
      return ''; // Handle Infinity, NaN, or out-of-bounds values
    }

    return categories[value.toInt()];
  }

  double _getTotalExpenses() {
    double totalExpenses = 0.0;

    for (Entry entry in widget.entries) {
      totalExpenses += entry.amount!;
    }

    return totalExpenses;
  }
}
