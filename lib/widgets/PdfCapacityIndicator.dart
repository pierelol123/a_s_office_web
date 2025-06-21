import 'package:flutter/material.dart';
import 'package:a_s_office_web/services/pdf/pdf_capacity_calculator.dart';

class PdfCapacityIndicator extends StatelessWidget {
  final PdfPageCapacity capacity;
  final bool isCompact;
  final VoidCallback? onTap;
  
  const PdfCapacityIndicator({
    super.key,
    required this.capacity,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactIndicator(context);
    } else {
      return _buildFullIndicator(context);
    }
  }
  
  Widget _buildCompactIndicator(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: capacity.statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: capacity.statusColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              capacity.statusIcon,
              size: 14,
              color: capacity.statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              capacity.statusText,
              style: TextStyle(
                fontSize: 11,
                color: capacity.statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFullIndicator(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: capacity.statusColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: capacity.statusColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  capacity.statusIcon,
                  size: 18,
                  color: capacity.statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'התאמה ל-PDF: ${capacity.statusText}',
                  style: TextStyle(
                    fontSize: 14,
                    color: capacity.statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (capacity.utilizationPercentage / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: capacity.statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ניצול: ${capacity.utilizationPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (capacity.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...capacity.warnings.take(2).map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 12, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        warning,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }
}