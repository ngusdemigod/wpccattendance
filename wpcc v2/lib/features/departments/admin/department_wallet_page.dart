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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complete the required wallet fields.')));
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
          purpose: purpose.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Department wallet created')));
        context.pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to create the wallet. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
      title: 'New wallet',
      child: ListView(padding: const EdgeInsets.all(18), children: [
        const SizedBox(height: 20),
        Center(
            child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24)),
                child: Icon(PhosphorIcons.wallet(), size: 28))),
        const SizedBox(height: 14),
        Text('Set up departmental wallet',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        TextField(
            controller: wallet,
            decoration: const InputDecoration(labelText: 'Wallet name')),
        const SizedBox(height: 10),
        TextField(
            controller: bank,
            decoration: const InputDecoration(labelText: 'Bank')),
        const SizedBox(height: 10),
        TextField(
            controller: number,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Account number')),
        const SizedBox(height: 10),
        TextField(
            controller: holder,
            decoration: const InputDecoration(labelText: 'Account holder')),
        const SizedBox(height: 10),
        TextField(
            controller: purpose,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Purpose (optional)')),
        const SizedBox(height: 18),
        FilledButton(
            onPressed: busy ? null : save,
            style: _blackButton(),
            child: busy
                ? const CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)
                : const Text('Create wallet'))
      ]));
}

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(PhosphorIcons.caretLeft(), size: 20)),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      body: SafeArea(child: child));
}

ButtonStyle _blackButton() => FilledButton.styleFrom(
    backgroundColor: WpccColors.ink,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)));
