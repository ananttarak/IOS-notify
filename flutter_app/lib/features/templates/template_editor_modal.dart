import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/template_model.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/widgets/ios_notification_preview_card.dart';

class TemplateEditorModal extends StatefulWidget {
  final TemplateModel? template;
  final ValueChanged<TemplateModel> onSave;

  const TemplateEditorModal({
    super.key,
    this.template,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    TemplateModel? template,
    required ValueChanged<TemplateModel> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TemplateEditorModal(
        template: template,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TemplateEditorModal> createState() => _TemplateEditorModalState();
}

class _TemplateEditorModalState extends State<TemplateEditorModal> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late double _weight;
  late bool _isEnabled;
  late bool _isSimulated;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.template?.title ?? 'Order #{{order_id}}');
    _bodyController = TextEditingController(
        text: widget.template?.body ??
            '{{amount}}, {{items}} item(s) from Online Store · Paya Ecom');
    _weight = (widget.template?.weight ?? 20).toDouble();
    _isEnabled = widget.template?.isEnabled ?? true;
    _isSimulated = widget.template?.isSimulated ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _insertVariable(TextEditingController controller, String variable) {
    final text = controller.text;
    final selection = controller.selection;
    final newText = selection.isValid
        ? text.replaceRange(selection.start, selection.end, variable)
        : '$text $variable';
    controller.text = newText;
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    setState(() {});
  }

  TemplateModel _buildPreviewModel() {
    return TemplateModel(
      id: widget.template?.id ?? 'preview',
      title: _titleController.text.trim().isEmpty
          ? 'Notification Title'
          : _titleController.text.trim(),
      body: _bodyController.text.trim().isEmpty
          ? 'Notification body message'
          : _bodyController.text.trim(),
      weight: _weight.toInt(),
      isEnabled: _isEnabled,
      isSimulated: _isSimulated,
      createdAt: widget.template?.createdAt ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = _buildPreviewModel().render();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.template == null ? 'New Template' : 'Edit Template',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final newTemplate = TemplateModel(
                      id: widget.template?.id ?? const Uuid().v4(),
                      title: _titleController.text.trim(),
                      body: _bodyController.text.trim(),
                      weight: _weight.toInt(),
                      isEnabled: _isEnabled,
                      isSimulated: _isSimulated,
                      createdAt: widget.template?.createdAt ?? DateTime.now(),
                    );
                    widget.onSave(newTemplate);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Preview Card
            const Text(
              'LIVE PREVIEW',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            IosNotificationPreviewCard(
              title: preview['title']!,
              body: preview['body']!,
              isSimulated: _isSimulated,
            ),
            const SizedBox(height: 18),

            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title Template',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Variable chips for Title
            Wrap(
              spacing: 6,
              children: [
                _chip('{{order_id}}', () => _insertVariable(_titleController, '{{order_id}}')),
                _chip('{{store}}', () => _insertVariable(_titleController, '{{store}}')),
              ],
            ),
            const SizedBox(height: 14),

            // Body field
            TextField(
              controller: _bodyController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Body Template',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Variable chips for Body
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip('{{amount}}', () => _insertVariable(_bodyController, '{{amount}}')),
                _chip('{{items}}', () => _insertVariable(_bodyController, '{{items}}')),
                _chip('{{store}}', () => _insertVariable(_bodyController, '{{store}}')),
                _chip('{{currency}}', () => _insertVariable(_bodyController, '{{currency}}')),
              ],
            ),
            const SizedBox(height: 18),

            // Weight Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Random Selection Weight:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_weight.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentBlue),
                ),
              ],
            ),
            Slider(
              value: _weight,
              min: 1,
              max: 100,
              divisions: 99,
              activeColor: AppTheme.accentBlue,
              onChanged: (val) => setState(() => _weight = val),
            ),

            // Simulated switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Simulated Event Label'),
              subtitle: const Text('Ensure disclaimers remain visible'),
              value: _isSimulated,
              activeTrackColor: AppTheme.accentGreen,
              onChanged: (val) => setState(() => _isSimulated = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
