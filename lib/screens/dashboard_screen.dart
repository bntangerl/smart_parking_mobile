import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference slotsRef = FirebaseDatabase.instance.ref('slots');
  final DatabaseReference historyRef = FirebaseDatabase.instance.ref('history');

  Color getSlotColor(String status) {
    return status == 'terisi'
        ? Colors.redAccent.withOpacity(0.7)
        : Colors.greenAccent.withOpacity(0.7);
  }

  // Helper function untuk convert dynamic data ke Map
  Map<String, dynamic>? _convertToMap(dynamic data) {
    if (data == null) return null;
    
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    
    if (data is List) {
      // Convert List to Map with index as key
      Map<String, dynamic> result = {};
      for (int i = 0; i < data.length; i++) {
        if (data[i] != null) {
          result[i.toString()] = data[i];
        }
      }
      return result;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade800, Colors.indigo.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Smart Parking Dashboard",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 10),

                // StreamBuilder untuk menampilkan slot secara real-time
                StreamBuilder(
                  stream: slotsRef.onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    // Handle loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    // Handle error state
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // Handle no data
                    if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: Colors.white70, size: 60),
                            SizedBox(height: 10),
                            Text(
                              'Tidak ada data slot',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    try {
                      // Convert data dengan aman
                      final rawData = snapshot.data!.snapshot.value;
                      final slotsData = _convertToMap(rawData);
                      
                      if (slotsData == null || slotsData.isEmpty) {
                        return Center(
                          child: Text(
                            'Tidak ada data slot',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        );
                      }

                      int totalSlots = slotsData.length;
                      int occupiedSlots = 0;
                      
                      slotsData.forEach((key, value) {
                        if (value is Map) {
                          String status = value['status']?.toString().toLowerCase() ?? 'kosong';
                          if (status == 'terisi') {
                            occupiedSlots++;
                          }
                        }
                      });

                      return Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Slot Terisi: $occupiedSlots / $totalSlots",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 20),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: slotsData.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemBuilder: (context, index) {
                              String key = slotsData.keys.elementAt(index);
                              var slotData = slotsData[key];
                              
                              String status = 'kosong';
                              String lastUpdate = '-';
                              
                              if (slotData is Map) {
                                status = slotData['status']?.toString().toLowerCase() ?? 'kosong';
                                lastUpdate = slotData['lastUpdate']?.toString() ?? '-';
                              }
                              
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: getSlotColor(status),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(2, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Slot $key",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            status == 'terisi' ? "Terisi" : "Kosong",
                                            style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    } catch (e, stackTrace) {
                      print('Error parsing slots: $e');
                      print('StackTrace: $stackTrace');
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[300], size: 60),
                              SizedBox(height: 10),
                              Text(
                                'Error parsing data',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '$e',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),

                SizedBox(height: 20),
                // Divider fade kanan-kiri
                Container(
                  height: 2,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white70,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 10),
                // Riwayat parkir
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.white.withOpacity(0.2),
                        child: Column(
                          children: [
                            Text(
                              "Riwayat Parkir",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: StreamBuilder(
                                stream: historyRef.onValue,
                                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                                  // Handle loading
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    );
                                  }

                                  // Handle error
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Error: ${snapshot.error}',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }

                                  // Handle no data
                                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.history, color: Colors.white70, size: 50),
                                          SizedBox(height: 10),
                                          Text(
                                            'Belum ada riwayat parkir',
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  try {
                                    // Convert data dengan aman
                                    final rawData = snapshot.data!.snapshot.value;
                                    final historyData = _convertToMap(rawData);
                                    
                                    if (historyData == null || historyData.isEmpty) {
                                      return Center(
                                        child: Text(
                                          'Belum ada riwayat parkir',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                      );
                                    }
                                    
                                    final historyList = <Map<String, String>>[];
                                    
                                    historyData.forEach((key, value) {
                                      if (value is Map) {
                                        String waktuKeluar = value['waktuKeluar']?.toString() ?? '-';
                                        // Logika: jika waktuKeluar kosong = terisi, jika ada = kosong
                                        String status = (waktuKeluar == '-' || waktuKeluar.isEmpty) 
                                            ? 'terisi' 
                                            : 'kosong';
                                        
                                        historyList.add({
                                          'slot': value['slot']?.toString() ?? '-',
                                          'status': status,
                                          'waktuMasuk': value['waktuMasuk']?.toString() ?? '-',
                                          'waktuKeluar': waktuKeluar,
                                        });
                                      }
                                    });
                                    
                                    if (historyList.isEmpty) {
                                      return Center(
                                        child: Text(
                                          'Belum ada riwayat parkir',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                      );
                                    }

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: DataTable(
                                          headingRowColor:
                                              MaterialStateProperty.all(
                                            Colors.indigo.shade700
                                                .withOpacity(0.5),
                                          ),
                                          dataRowColor: MaterialStateProperty.all(
                                            Colors.white.withOpacity(0.05),
                                          ),
                                          columns: [
                                            DataColumn(
                                                label: Text('No',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold))),
                                            DataColumn(
                                                label: Text('Slot',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold))),
                                            DataColumn(
                                                label: Text('Status',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold))),
                                            DataColumn(
                                                label: Text('Waktu Masuk',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold))),
                                            DataColumn(
                                                label: Text('Waktu Keluar',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold))),
                                          ],
                                          rows: historyList
                                              .asMap()
                                              .entries
                                              .map((entry) => DataRow(
                                                    cells: [
                                                      DataCell(Text(
                                                        (entry.key + 1).toString(),
                                                        style: TextStyle(
                                                            color: Colors.white),
                                                      )),
                                                      DataCell(Text(
                                                        entry.value['slot']!,
                                                        style: TextStyle(
                                                            color: Colors.white),
                                                      )),
                                                      DataCell(
                                                        Container(
                                                          padding: EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: entry.value['status']?.toLowerCase() == 'terisi'
                                                                ? Colors.red.withOpacity(0.3)
                                                                : Colors.green.withOpacity(0.3),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            entry.value['status']!,
                                                            style: TextStyle(
                                                                color: Colors.white),
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(Text(
                                                        entry.value['waktuMasuk']!,
                                                        style: TextStyle(
                                                            color: Colors.white),
                                                      )),
                                                      DataCell(Text(
                                                        entry.value['waktuKeluar']!,
                                                        style: TextStyle(
                                                            color: Colors.white),
                                                      )),
                                                    ],
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    );
                                  } catch (e, stackTrace) {
                                    print('Error parsing history: $e');
                                    print('StackTrace: $stackTrace');
                                    return Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, 
                                                color: Colors.red[300], size: 50),
                                            SizedBox(height: 10),
                                            Text(
                                              'Error parsing history',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              '$e',
                                              style: TextStyle(
                                                color: Colors.white70, 
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}