import 'package:flutter/material.dart';
import '../../domain/entities/restaurant_entity.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final RestaurantEntity restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
      ),
      body: Center(
        child: Text('Details for ${restaurant.name}'),
      ),
    );
  }
}
