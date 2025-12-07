part of 'pages.dart';

class InternationalPage extends StatefulWidget {
  const InternationalPage({super.key});

  @override
  State<InternationalPage> createState() => _InternationalPageState();
}

class _InternationalPageState extends State<InternationalPage> {
  late HomeViewModel homeViewModel;

  final weightController = TextEditingController();

  final List<String> courierOptions = ["jne", "pos", "tiki"];
  String selectedCourier = "jne";

  // Origin/Destination type: 'domestic' or 'international'
  String originType = "domestic";
  String destinationType = "international";

  // Domestic selections
  int? selectedProvinceOriginId;
  int? selectedCityOriginId;
  int? selectedProvinceDestId;
  int? selectedCityDestId;

  // International selections
  int? selectedCountryOriginId;
  int? selectedCountryDestId;

  // Filter text for autocomplete
  String originFilterText = "";
  String destFilterText = "";

  @override
  void initState() {
    super.initState();
    homeViewModel = Provider.of<HomeViewModel>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (homeViewModel.provinceList.status == Status.notStarted) {
        homeViewModel.getProvinceList();
      }
    });
  }

  @override
  void dispose() {
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "International Shipping",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedCourier,
                                items: courierOptions
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c.toUpperCase(),
                                          style: GoogleFonts.roboto(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () => selectedCourier = v ?? "jne",
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: weightController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.roboto(),
                                decoration: InputDecoration(
                                  labelText: 'Berat (gr)',
                                  labelStyle: GoogleFonts.roboto(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // FROM Section
                        _buildFromSection(),
                        const SizedBox(height: 24),
                        // TO Section
                        _buildToSection(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _calculateShipping,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              padding: const EdgeInsets.all(16),
                            ),
                            child: Text(
                              "Hitung Ongkir Internasional",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue[50],
                  elevation: 2,
                  child: Consumer<HomeViewModel>(
                    builder: (context, vm, _) {
                      switch (vm.internationalCostList.status) {
                        case Status.loading:
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            ),
                          );
                        case Status.error:
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                vm.internationalCostList.message ?? 'Error',
                                style: GoogleFonts.roboto(color: Colors.red),
                              ),
                            ),
                          );
                        case Status.completed:
                          if (vm.internationalCostList.data == null ||
                              vm.internationalCostList.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  "Tidak ada data ongkir.",
                                  style: GoogleFonts.roboto(),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                vm.internationalCostList.data?.length ?? 0,
                            itemBuilder: (context, index) => CardCost(
                              vm.internationalCostList.data!.elementAt(index),
                            ),
                          );
                        default:
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                "Pilih lokasi dan klik Hitung Ongkir.",
                                style: GoogleFonts.roboto(color: Colors.black),
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
          Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFromSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "From (Origin)",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          value: originType,
          items: const [
            DropdownMenuItem(value: "domestic", child: Text("Domestic")),
            DropdownMenuItem(
              value: "international",
              child: Text("International"),
            ),
          ],
          onChanged: (value) {
            setState(() {
              originType = value ?? "domestic";
              selectedProvinceOriginId = null;
              selectedCityOriginId = null;
              selectedCountryOriginId = null;
            });
          },
        ),
        const SizedBox(height: 12),
        if (originType == "domestic") _buildDomesticOriginFields(),
        if (originType == "international") _buildInternationalOriginFields(),
      ],
    );
  }

  Widget _buildToSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "To (Destination)",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          value: destinationType,
          items: const [
            DropdownMenuItem(value: "domestic", child: Text("Domestic")),
            DropdownMenuItem(
              value: "international",
              child: Text("International"),
            ),
          ],
          onChanged: (value) {
            setState(() {
              destinationType = value ?? "international";
              selectedProvinceDestId = null;
              selectedCityDestId = null;
              selectedCountryDestId = null;
            });
          },
        ),
        const SizedBox(height: 12),
        if (destinationType == "domestic") _buildDomesticDestFields(),
        if (destinationType == "international") _buildInternationalDestFields(),
      ],
    );
  }

  Widget _buildDomesticOriginFields() {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            _buildProvinceDropdown(vm.provinceList, selectedProvinceOriginId, (
              newId,
            ) {
              setState(() {
                selectedProvinceOriginId = newId;
                selectedCityOriginId = null;
              });
              if (newId != null) vm.getCityOriginList(newId);
            }),
            const SizedBox(height: 12),
            _buildCityDropdown(
              vm.cityOriginList,
              selectedCityOriginId,
              (newId) => setState(() => selectedCityOriginId = newId),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDomesticDestFields() {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            _buildProvinceDropdown(vm.provinceList, selectedProvinceDestId, (
              newId,
            ) {
              setState(() {
                selectedProvinceDestId = newId;
                selectedCityDestId = null;
              });
              if (newId != null) vm.getCityDestinationList(newId);
            }),
            const SizedBox(height: 12),
            _buildCityDropdown(
              vm.cityDestinationList,
              selectedCityDestId,
              (newId) => setState(() => selectedCityDestId = newId),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInternationalOriginFields() {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return _buildFilterableCountryDropdown(
          vm.originInternationalList,
          selectedCountryOriginId,
          originFilterText,
          'Type to search origin country...',
          (newId) => setState(() => selectedCountryOriginId = newId),
          (filterText) {
            setState(() => originFilterText = filterText);
            if (filterText.isNotEmpty) {
              homeViewModel.getOriginInternationalList(search: filterText);
            }
          },
        );
      },
    );
  }

  Widget _buildInternationalDestFields() {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return _buildFilterableCountryDropdown(
          vm.internationalDestList,
          selectedCountryDestId,
          destFilterText,
          'Type to search destination country...',
          (newId) => setState(() => selectedCountryDestId = newId),
          (filterText) {
            setState(() => destFilterText = filterText);
            if (filterText.isNotEmpty) {
              homeViewModel.getInternationalDestList(search: filterText);
            }
          },
        );
      },
    );
  }

  Widget _buildProvinceDropdown(
    ApiResponse<List<Province>> provinceList,
    int? selectedId,
    Function(int?) onChanged,
  ) {
    if (provinceList.status == Status.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provinceList.status == Status.error) {
      return Text(
        provinceList.message ?? 'Error',
        style: const TextStyle(color: Colors.red),
      );
    }

    final provinces = provinceList.data ?? [];
    if (provinces.isEmpty) return const Text('No provinces');

    return DropdownButton<int>(
      isExpanded: true,
      value: selectedId,
      hint: const Text('Select province'),
      items: provinces
          .map(
            (p) =>
                DropdownMenuItem<int>(value: p.id, child: Text(p.name ?? '')),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCityDropdown(
    ApiResponse<List<City>> cityList,
    int? selectedId,
    Function(int?) onChanged,
  ) {
    if (cityList.status == Status.notStarted) {
      return const Text(
        'Select province first',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
    if (cityList.status == Status.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cityList.status == Status.error) {
      return Text(
        cityList.message ?? 'Error',
        style: const TextStyle(color: Colors.red),
      );
    }

    final cities = cityList.data ?? [];
    if (cities.isEmpty) return const Text('No cities');

    final validIds = cities.map((c) => c.id).toSet();
    final validValue = validIds.contains(selectedId) ? selectedId : null;

    return DropdownButton<int>(
      isExpanded: true,
      value: validValue,
      hint: const Text('Select city'),
      items: cities
          .map(
            (c) =>
                DropdownMenuItem<int>(value: c.id, child: Text(c.name ?? '')),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFilterableCountryDropdown(
    ApiResponse<List<City>> countryList,
    int? selectedId,
    String filterText,
    String hint,
    Function(int?) onChanged,
    Function(String) onFilterChanged,
  ) {
    // Get selected country name
    final allCountries = countryList.data ?? [];
    final selectedCountry = selectedId != null
        ? allCountries.firstWhere(
            (c) => c.id == selectedId,
            orElse: () => const City(),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: selectedCountry?.name ?? hint,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: filterText.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => onFilterChanged(''),
                  )
                : null,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          onChanged: onFilterChanged,
        ),
        if (filterText.isNotEmpty) ...[
          const SizedBox(height: 4),
          if (countryList.status == Status.loading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (countryList.status == Status.error)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                countryList.message ?? 'Error loading countries',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            )
          else
            Builder(
              builder: (context) {
                // Filter countries - use startsWith for cleaner results
                final filteredCountries = allCountries
                    .where(
                      (c) =>
                          c.name?.toLowerCase().startsWith(
                            filterText.toLowerCase(),
                          ) ??
                          false,
                    )
                    .toList();

                return Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: filteredCountries.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'No countries found',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredCountries.length,
                          itemBuilder: (context, index) {
                            final country = filteredCountries[index];
                            final isSelected = country.id == selectedId;
                            return InkWell(
                              onTap: () {
                                onChanged(country.id);
                                onFilterChanged(
                                  '',
                                ); // Clear search after selection
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.shade50
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        country.name ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected
                                              ? Colors.blue.shade700
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        color: Colors.blue.shade700,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
        ],
      ],
    );
  }

  void _calculateShipping() {
    // Validate: domestic to domestic not allowed
    if (originType == "domestic" && destinationType == "domestic") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Domestic to Domestic shipping is only available on the Domestic page!',
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Weight validation
    final weight = int.tryParse(weightController.text) ?? 0;
    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berat harus lebih dari 0'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validate selections based on type
    bool validOrigin = originType == "domestic"
        ? (selectedCityOriginId != null)
        : (selectedCountryOriginId != null);
    bool validDest = destinationType == "domestic"
        ? (selectedCityDestId != null)
        : (selectedCountryDestId != null);

    if (!validOrigin || !validDest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all required fields!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // If destination is international, use international cost calculation
    if (destinationType == "international") {
      // Get origin ID based on type
      final originId = originType == "domestic"
          ? selectedCityOriginId!
          : selectedCountryOriginId!;

      homeViewModel.checkInternationalCost(
        originId,
        selectedCountryDestId!,
        weight,
        selectedCourier,
      );
    } else {
      // This would be international to domestic - not yet implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('International to Domestic not yet supported by API'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
