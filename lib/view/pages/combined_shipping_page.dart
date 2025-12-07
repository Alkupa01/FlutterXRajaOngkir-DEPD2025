part of 'pages.dart';

class CombinedShippingPage extends StatefulWidget {
  const CombinedShippingPage({super.key});

  @override
  State<CombinedShippingPage> createState() => _CombinedShippingPageState();
}

class _CombinedShippingPageState extends State<CombinedShippingPage> {
  late HomeViewModel homeViewModel;

  final weightController = TextEditingController();
  final searchOriginController = TextEditingController();
  final searchDestController = TextEditingController();

  final List<String> courierOptions = ["jne", "pos", "tiki"];
  String selectedCourier = "jne";

  // Origin/Destination type: 'domestic' or 'international'
  String originType = "domestic";
  String destinationType = "domestic";

  // Domestic selections
  int? selectedProvinceOriginId;
  int? selectedCityOriginId;
  int? selectedProvinceDestId;
  int? selectedCityDestId;

  // International selections
  int? selectedCountryOriginId;
  int? selectedCountryDestId;

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
    searchOriginController.dispose();
    searchDestController.dispose();
    super.dispose();
  }

  void _searchOriginCountry() {
    final query = searchOriginController.text.trim();
    homeViewModel.getOriginInternationalList(search: query);
    setState(() {
      selectedCountryOriginId = null;
    });
  }

  void _searchDestCountry() {
    final query = searchDestController.text.trim();
    homeViewModel.getInternationalDestList(search: query);
    setState(() {
      selectedCountryDestId = null;
    });
  }

  Widget _buildOriginSection() {
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
              // Reset selections
              selectedProvinceOriginId = null;
              selectedCityOriginId = null;
              selectedCountryOriginId = null;
            });
            if (originType == "international" &&
                homeViewModel.originInternationalList.status ==
                    Status.notStarted) {
              homeViewModel.getOriginInternationalList();
            }
          },
        ),
        const SizedBox(height: 12),
        if (originType == "domestic") _buildDomesticOriginFields(),
        if (originType == "international") _buildInternationalOriginFields(),
      ],
    );
  }

  Widget _buildDestinationSection() {
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
              destinationType = value ?? "domestic";
              // Reset selections
              selectedProvinceDestId = null;
              selectedCityDestId = null;
              selectedCountryDestId = null;
            });
            if (destinationType == "international" &&
                homeViewModel.internationalDestList.status ==
                    Status.notStarted) {
              homeViewModel.getInternationalDestList();
            }
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
            // Province dropdown
            _buildProvinceDropdown(vm.provinceList, selectedProvinceOriginId, (
              newId,
            ) {
              setState(() {
                selectedProvinceOriginId = newId;
                selectedCityOriginId = null;
              });
              if (newId != null) {
                vm.getCityOriginList(newId);
              }
            }),
            const SizedBox(height: 12),
            // City dropdown
            _buildCityDropdown(vm.cityOriginList, selectedCityOriginId, (
              newId,
            ) {
              setState(() {
                selectedCityOriginId = newId;
              });
            }),
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
            // Province dropdown
            _buildProvinceDropdown(vm.provinceList, selectedProvinceDestId, (
              newId,
            ) {
              setState(() {
                selectedProvinceDestId = newId;
                selectedCityDestId = null;
              });
              if (newId != null) {
                vm.getCityDestinationList(newId);
              }
            }),
            const SizedBox(height: 12),
            // City dropdown
            _buildCityDropdown(vm.cityDestinationList, selectedCityDestId, (
              newId,
            ) {
              setState(() {
                selectedCityDestId = newId;
              });
            }),
          ],
        );
      },
    );
  }

  Widget _buildInternationalOriginFields() {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchOriginController,
                    decoration: const InputDecoration(
                      labelText: 'Search country',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchOriginCountry(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchOriginCountry,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCountryDropdown(
              vm.originInternationalList,
              selectedCountryOriginId,
              (newId) {
                setState(() {
                  selectedCountryOriginId = newId;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInternationalDestFields() {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchDestController,
                    decoration: const InputDecoration(
                      labelText: 'Search country',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchDestCountry(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchDestCountry,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCountryDropdown(
              vm.internationalDestList,
              selectedCountryDestId,
              (newId) {
                setState(() {
                  selectedCountryDestId = newId;
                });
              },
            ),
          ],
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
    if (provinces.isEmpty) {
      return const Text('No provinces available');
    }

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
    if (cities.isEmpty) {
      return const Text('No cities available');
    }

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

  Widget _buildCountryDropdown(
    ApiResponse<List<City>> countryList,
    int? selectedId,
    Function(int?) onChanged,
  ) {
    if (countryList.status == Status.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (countryList.status == Status.error) {
      return Text(
        countryList.message ?? 'Error',
        style: const TextStyle(color: Colors.red),
      );
    }

    final countries = countryList.data ?? [];
    if (countries.isEmpty) {
      return const Text('No countries available. Try searching.');
    }

    return DropdownButton<int>(
      isExpanded: true,
      value: selectedId,
      hint: const Text('Select country'),
      items: countries
          .map(
            (c) =>
                DropdownMenuItem<int>(value: c.id, child: Text(c.name ?? '')),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  void _calculateShipping() {
    // Validation and calculation logic based on selected types
    // This is a placeholder - implement based on your API requirements
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shipping calculation coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shipping Calculator",
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
                                    child: Text(c.toUpperCase()),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedCourier = v ?? "jne"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (gr)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildOriginSection(),
                    const SizedBox(height: 24),
                    _buildDestinationSection(),
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
                          "Calculate Shipping",
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
          ],
        ),
      ),
    );
  }
}
