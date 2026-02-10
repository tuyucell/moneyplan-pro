import 'package:moneyplan_pro/features/search/data/models/asset.dart';
import 'package:moneyplan_pro/features/exchanges/data/models/exchange.dart';

class AssetExchange {
  final String id;
  final String assetId;
  final String exchangeId;

  // Trading pair
  final String? tradingPair;
  final String? baseCurrency;
  final String? quoteCurrency;

  // Volume & Liquidity
  final double? volume24hUsd;
  final double? liquidityScore;

  // Trading details
  final double? minTradeAmount;
  final String? minTradeAmountCurrency;
  final double? lotSize;
  final String? lotSizeUnit;

  // Fees
  final double? makerFeePercent;
  final double? takerFeePercent;

  // Price cache
  final double? currentPrice;
  final DateTime? lastPriceUpdate;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Related data
  final Asset? asset;
  final Exchange? exchange;

  AssetExchange({
    required this.id,
    required this.assetId,
    required this.exchangeId,
    this.tradingPair,
    this.baseCurrency,
    this.quoteCurrency,
    this.volume24hUsd,
    this.liquidityScore,
    this.minTradeAmount,
    this.minTradeAmountCurrency,
    this.lotSize,
    this.lotSizeUnit,
    this.makerFeePercent,
    this.takerFeePercent,
    this.currentPrice,
    this.lastPriceUpdate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.asset,
    this.exchange,
  });

  factory AssetExchange.fromJson(Map<String, dynamic> json) {
    return AssetExchange(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      exchangeId: json['exchange_id'] as String,
      tradingPair: json['trading_pair'] as String?,
      baseCurrency: json['base_currency'] as String?,
      quoteCurrency: json['quote_currency'] as String?,
      volume24hUsd: json['volume_24h_usd'] != null
          ? double.tryParse(json['volume_24h_usd'].toString())
          : null,
      liquidityScore: json['liquidity_score'] != null
          ? double.tryParse(json['liquidity_score'].toString())
          : null,
      minTradeAmount: json['min_trade_amount'] != null
          ? double.tryParse(json['min_trade_amount'].toString())
          : null,
      minTradeAmountCurrency: json['min_trade_amount_currency'] as String?,
      lotSize: json['lot_size'] != null
          ? double.tryParse(json['lot_size'].toString())
          : null,
      lotSizeUnit: json['lot_size_unit'] as String?,
      makerFeePercent: json['maker_fee_percent'] != null
          ? double.tryParse(json['maker_fee_percent'].toString())
          : null,
      takerFeePercent: json['taker_fee_percent'] != null
          ? double.tryParse(json['taker_fee_percent'].toString())
          : null,
      currentPrice: json['current_price'] != null
          ? double.tryParse(json['current_price'].toString())
          : null,
      lastPriceUpdate: json['last_price_update'] != null
          ? DateTime.tryParse(json['last_price_update'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      asset: json['asset'] != null
          ? Asset.fromJson(json['asset'] as Map<String, dynamic>)
          : null,
      exchange: json['exchange'] != null
          ? Exchange.fromJson(json['exchange'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'exchange_id': exchangeId,
      'trading_pair': tradingPair,
      'base_currency': baseCurrency,
      'quote_currency': quoteCurrency,
      'volume_24h_usd': volume24hUsd,
      'liquidity_score': liquidityScore,
      'min_trade_amount': minTradeAmount,
      'min_trade_amount_currency': minTradeAmountCurrency,
      'lot_size': lotSize,
      'lot_size_unit': lotSizeUnit,
      'maker_fee_percent': makerFeePercent,
      'taker_fee_percent': takerFeePercent,
      'current_price': currentPrice,
      'last_price_update': lastPriceUpdate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
