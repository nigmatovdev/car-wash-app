import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/cards/service_card.dart';

class ServicesList extends StatelessWidget {
  final List<ServiceModel> services;
  final bool isLoading;

  const ServicesList({
    super.key,
    required this.services,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Services',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  context.push(RouteConstants.services);
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (services.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No services available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  child: ServiceCard(
                    title: service.name,
                    description: service.description,
                    price: service.price,
                    image: service.image,
                    onTap: () {
                      context.push(RouteConstants.serviceDetailsPath(service.id));
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

