import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../department_repository.dart';

class DepartmentWalletPage extends StatefulWidget {
  const DepartmentWalletPage({super.key, required this.departmentId});
  final String departmentId;
  @override
  State<DepartmentWalletPage> createState() => _DepartmentWalletPageState();
}

class _DepartmentWalletPageState extends State<DepartmentWalletPage> {
  final repo = DepartmentRepository();
  final wallet = TextEditingController(),
      bank = TextEditingController(),
      number = TextEditingController(),
      holder = TextEditingController(),
      purpose = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    for (final c in [wallet, bank, number, holder, purpose]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (wallet.text.trim().length < 2 ||
        bank.text.trim().length < 2 ||
        !RegExp(r'^\d{6,20}$').hasMatch(number.text.trim()) ||
        holder.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the required wallet fields.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await repo.createWallet(
        departmentId: widget.departmentId,
        walletName: wallet.text.trim(),
        bankName: bank.text.trim(),
        accountNumber: number.text.trim(),
        accountName: holder.text.trim(),
        purpose: purpose.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Department wallet created')),
        );
        context.pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create the wallet. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'New wallet',
    onSave: busy ? null : save,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'Create department wallet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add a wallet profile for offerings, dues or internal department funding.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: WpccColors.inkSoft,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: WpccColors.line),
          ),
          child: Column(
            children: [
              _GroupedField(controller: wallet, label: 'Wallet name'),
              _GroupedField(controller: bank, label: 'Bank name'),
              _GroupedField(
                controller: number,
                label: 'Account number',
                keyboardType: TextInputType.number,
              ),
              _GroupedField(controller: holder, label: 'Account holder'),
              _GroupedField(
                controller: purpose,
                label: 'Purpose',
                maxLines: 3,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: busy ? null : save,
          style: _blackButton(),
          child: busy
              ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                )
              : const Text('Create wallet'),
        ),
      ],
    ),
  );
}

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({
    required this.title,
    required this.child,
    required this.onSave,
  });
  final String title;
  final Widget child;
  final VoidCallback? onSave;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(PhosphorIcons.caretLeft(), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: onSave,
          child: const Text(
            'Save',
            style: TextStyle(fontSize: 12, color: Color(0xFF7D46B4)),
          ),
        ),
      ],
    ),
    body: SafeArea(child: child),
  );
}

class _GroupedField extends StatelessWidget {
  const _GroupedField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.isLast = false,
  });
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(bottom: BorderSide(color: WpccColors.line)),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      style: const TextStyle(fontSize: 14),
    ),
  );
}

ButtonStyle _blackButton() => FilledButton.styleFrom(
  backgroundColor: WpccColors.ink,
  minimumSize: const Size.fromHeight(50),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
);
