import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/helpers/currency_helper.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final double? displayPrice;
  final String? levelLabel;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.displayPrice,
    this.levelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock == 0;
    return GestureDetector(
      onTap: outOfStock ? null : onTap,
      child: AnimatedOpacity(
        opacity: outOfStock ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 6,
                  offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image / Emoji area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: product.imagePath != null &&
                          File(product.imagePath!).existsSync()
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.file(
                            File(product.imagePath!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(product.emoji,
                              style: const TextStyle(fontSize: 38)),
                        ),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            CurrencyHelper.formatRupiah(
                                displayPrice ?? product.price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (levelLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              levelLabel!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 11,
                          color: product.stock < 5
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          outOfStock ? 'Habis' : 'Stok: ${product.stock}',
                          style: TextStyle(
                            fontSize: 11,
                            color: product.stock < 5
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
