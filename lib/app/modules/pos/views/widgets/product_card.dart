import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/models/product_model.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/helpers/currency_helper.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onDecrease;
  final double? displayPrice;
  final String? levelLabel;
  final int quantity;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onDecrease,
    this.displayPrice,
    this.levelLabel,
    this.quantity = 0,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock == 0;
    final isActive = quantity > 0;
    return GestureDetector(
      onTap: outOfStock ? null : onTap,
      child: AnimatedOpacity(
        opacity: outOfStock ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: AppColors.primary, width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : const [
                    BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 6,
                        offset: Offset(0, 2))
                  ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Card content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image / Emoji area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                      ),
                      child: product.imagePath != null &&
                              File(product.imagePath!).existsSync()
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10)),
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
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
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
              // Quantity control — top right corner: [-] N [+]
              if (isActive)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onDecrease,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Icon(Icons.remove,
                                color: Colors.white, size: 12),
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: outOfStock ? null : onTap,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Icon(Icons.add,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
