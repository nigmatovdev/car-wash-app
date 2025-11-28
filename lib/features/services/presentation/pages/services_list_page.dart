import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';

class ServicesListPage extends StatefulWidget {
  const ServicesListPage({super.key});

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  String _sortBy = 'price'; // price, duration, name
  String _sortOrder = 'asc'; // asc, desc

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceModel> _filterAndSortServices(List<ServiceModel> services) {
    var filtered = services;

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((service) {
        return service.name.toLowerCase().contains(query) ||
            service.description.toLowerCase().contains(query);
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'price':
          return _sortOrder == 'asc'
              ? a.price.compareTo(b.price)
              : b.price.compareTo(a.price);
        case 'duration':
          return _sortOrder == 'asc'
              ? a.duration.compareTo(b.duration)
              : b.duration.compareTo(a.duration);
        case 'name':
        default:
          return _sortOrder == 'asc'
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          // View Toggle
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          final services = _filterAndSortServices(homeProvider.services);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),

              // Filter Buttons
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(
                      'Price',
                      _sortBy == 'price',
                      () {
                        setState(() {
                          _sortBy = 'price';
                          _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Duration',
                      _sortBy == 'duration',
                      () {
                        setState(() {
                          _sortBy = 'duration';
                          _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Name',
                      _sortBy == 'name',
                      () {
                        setState(() {
                          _sortBy = 'name';
                          _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Services List/Grid
              Expanded(
                child: homeProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : services.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No services found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => homeProvider.fetchServices(),
                            child: _isGridView
                                ? _buildGridView(services)
                                : _buildListView(services),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _sortOrder == 'asc'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildGridView(List<ServiceModel> services) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(service, isCompact: true);
      },
    );
  }

  Widget _buildListView(List<ServiceModel> services) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildServiceCard(service, isCompact: false);
      },
    );
  }

  Widget _buildServiceCard(ServiceModel service, {required bool isCompact}) {
    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 0 : 12),
      child: InkWell(
        onTap: () {
          context.push(RouteConstants.serviceDetailsPath(service.id));
        },
        borderRadius: BorderRadius.circular(12),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: service.image != null
                        ? Image.network(
                            service.image!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.formatCurrency(service.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${service.duration} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.push(
                                '${RouteConstants.createBooking}?serviceId=${service.id}',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Book Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    child: service.image != null
                        ? Image.network(
                            service.image!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                SizedBox(
                              width: 120,
                              height: 120,
                              child: _buildPlaceholderImage(),
                            ),
                          )
                        : SizedBox(
                            width: 120,
                            height: 120,
                            child: _buildPlaceholderImage(),
                          ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Formatters.formatCurrency(service.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '${service.duration} min',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                context.push(
                                  '${RouteConstants.createBooking}?serviceId=${service.id}',
                                );
                              },
                              child: const Text('Book Now'),
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: const Icon(
        Icons.local_car_wash,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}

