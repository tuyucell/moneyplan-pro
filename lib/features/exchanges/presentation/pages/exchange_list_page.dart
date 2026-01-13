import 'package:flutter/material.dart';
import 'package:invest_guide/features/search/data/models/asset.dart';

class ExchangeListPage extends StatelessWidget {
  final Asset asset;

  const ExchangeListPage({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${asset.name} Exchanges'),
      ),
      body: const Center(
        child: Text('Exchange List'),
      ),
    );
  }
}
