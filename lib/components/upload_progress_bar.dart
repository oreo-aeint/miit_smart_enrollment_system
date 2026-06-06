import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class UploadProgressBar extends StatelessWidget {
  final double progress;
  final int currentPage;
  final int totalPages;

  const UploadProgressBar({
    Key? key,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('uploadProgress'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width: MediaQuery.of(context).size.width * 0.9 * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF87CEFA), Color(0xFFADD8E6), Color(0xFF4169E1)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(totalPages, (index) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index < currentPage
                        ? Colors.indigo
                        : (index == currentPage
                        ? Colors.indigo.withOpacity(0.5)
                        : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('studentPhoto'.tr(), style: const TextStyle(fontSize: 10)),
              Text('idPhotos'.tr(), style: const TextStyle(fontSize: 10)),
              Text('form'.tr(), style: const TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}