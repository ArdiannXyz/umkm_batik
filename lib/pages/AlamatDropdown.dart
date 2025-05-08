import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlamatDropdown extends StatefulWidget {
  final TextEditingController provinsiController;
  final TextEditingController kotaController;
  final TextEditingController kecamatanController;

  const AlamatDropdown({
    super.key,
    required this.provinsiController,
    required this.kotaController,
    required this.kecamatanController,
  });

  @override
  State<AlamatDropdown> createState() => _AlamatDropdownState();
}

class _AlamatDropdownState extends State<AlamatDropdown> {
  List<dynamic> provinsiList = [];
  List<dynamic> kotaList = [];
  List<dynamic> kecamatanList = [];

  String? selectedProvinsiId;
  String? selectedKotaId;

  String? selectedProvinsi;
  String? selectedKota;
  String? selectedKecamatan;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    fetchProvinsi();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if initial values are present and we haven't initialized yet
    if (!_isInitialized &&
        widget.provinsiController.text.isNotEmpty &&
        provinsiList.isNotEmpty) {
      _updateInitialValues();
    }
  }

  // Update UI after fetching provinces
  void _updateInitialValues() async {
    // Find the province with matching name
    final matchingProvince = provinsiList.firstWhere(
      (prov) => prov['name'] == widget.provinsiController.text,
      orElse: () => null,
    );

    if (matchingProvince != null) {
      setState(() {
        selectedProvinsi = matchingProvince['name'];
        selectedProvinsiId = matchingProvince['id'];
      });

      // Now fetch cities for this province
      await fetchKota(selectedProvinsiId!);

      // Find the city with matching name
      if (kotaList.isNotEmpty && widget.kotaController.text.isNotEmpty) {
        final matchingCity = kotaList.firstWhere(
          (kota) => kota['name'] == widget.kotaController.text,
          orElse: () => null,
        );

        if (matchingCity != null) {
          setState(() {
            selectedKota = matchingCity['name'];
            selectedKotaId = matchingCity['id'];
          });

          // Now fetch districts for this city
          await fetchKecamatan(selectedKotaId!);

          // Find the district with matching name
          if (kecamatanList.isNotEmpty &&
              widget.kecamatanController.text.isNotEmpty) {
            final matchingDistrict = kecamatanList.firstWhere(
              (kec) => kec['name'] == widget.kecamatanController.text,
              orElse: () => null,
            );

            if (matchingDistrict != null) {
              setState(() {
                selectedKecamatan = matchingDistrict['name'];
              });
            }
          }
        }
      }

      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> fetchProvinsi() async {
    try {
      final response = await http.get(Uri.parse(
          'https://www.emsifa.com/api-wilayah-indonesia/api/provinces.json'));
      if (response.statusCode == 200) {
        setState(() {
          provinsiList = json.decode(response.body);
        });

        // After getting provinces, check if we need to preset values
        if (!_isInitialized && widget.provinsiController.text.isNotEmpty) {
          _updateInitialValues();
        }
      } else {
        debugPrint('Failed to load provinces: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching provinces: $e');
    }
  }

  Future<void> fetchKota(String provinsiId) async {
    try {
      final response = await http.get(Uri.parse(
          'https://www.emsifa.com/api-wilayah-indonesia/api/regencies/$provinsiId.json'));
      if (response.statusCode == 200) {
        setState(() {
          kotaList = json.decode(response.body);
        });
      } else {
        debugPrint('Failed to load cities: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    }
  }

  Future<void> fetchKecamatan(String kotaId) async {
    try {
      final response = await http.get(Uri.parse(
          'https://www.emsifa.com/api-wilayah-indonesia/api/districts/$kotaId.json'));
      if (response.statusCode == 200) {
        setState(() {
          kecamatanList = json.decode(response.body);
        });
      } else {
        debugPrint('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching districts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Provinsi",
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedProvinsi,
          items: provinsiList.map<DropdownMenuItem<String>>((prov) {
            return DropdownMenuItem(
              value: prov['name'],
              child: Text(prov['name']),
              onTap: () {
                selectedProvinsiId = prov['id'];
              },
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedProvinsi = value;
              widget.provinsiController.text = value ?? '';
              selectedKota = null;
              selectedKecamatan = null;
              kotaList.clear();
              kecamatanList.clear();
              widget.kotaController.text = '';
              widget.kecamatanController.text = '';
            });
            if (selectedProvinsiId != null) {
              fetchKota(selectedProvinsiId!);
            }
          },
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            border: UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text("Kota/Kabupaten",
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedKota,
          items: kotaList.map<DropdownMenuItem<String>>((kota) {
            return DropdownMenuItem(
              value: kota['name'],
              child: Text(kota['name']),
              onTap: () {
                selectedKotaId = kota['id'];
              },
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedKota = value;
              widget.kotaController.text = value ?? '';
              selectedKecamatan = null;
              kecamatanList.clear();
              widget.kecamatanController.text = '';
            });
            if (selectedKotaId != null) {
              fetchKecamatan(selectedKotaId!);
            }
          },
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            border: UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text("Kecamatan",
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedKecamatan,
          items: kecamatanList.map<DropdownMenuItem<String>>((kec) {
            return DropdownMenuItem(
              value: kec['name'],
              child: Text(kec['name']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedKecamatan = value;
              widget.kecamatanController.text = value ?? '';
            });
          },
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            border: UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
