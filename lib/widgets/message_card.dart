import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageCard extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MessageCard({
    super.key,
    required this.message,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (message.images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.image, size: 18, color: Colors.grey[600]),
                    ),
                  if (message.files.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.attach_file, size: 18, color: Colors.grey[600]),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
              if (message.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: message.tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    final colors = {
      '欢迎语': Colors.green,
      '咨询': Colors.orange,
      '售后': Colors.red,
      '活动': Colors.purple,
      '常用': Colors.blue,
    };
    final color = colors[tag] ?? Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
