import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import 'give_repository.dart';

class GivePaymentPage extends StatefulWidget {
  const GivePaymentPage({super.key, required this.payload});
  final Map<String, dynamic> payload;
  @override
  State<GivePaymentPage> createState() => _GivePaymentPageState();
}

class _GivePaymentPageState extends State<GivePaymentPage> {
  final repo = GiveRepository();
  String digits = '';
  bool busy = false;
  String? error;
  int get amountKobo => (int.tryParse(digits) ?? 0) * 100;
  String get amountText =>
      NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2)
          .format(amountKobo / 100);
  void press(String value) {
    if (value == 'back') {
      if (digits.isNotEmpty) {
        setState(() => digits = digits.substring(0, digits.length - 1));
      }
      return;
    }
    if (digits.length >= 9) return;
    setState(() => digits = digits == '0' ? value : digits + value);
  }

  Future<void> submit() async {
    if (amountKobo < 10000) {
      setState(() => error = 'Enter an amount of at least ₦100');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await repo.initialize(
          amountKobo: amountKobo,
          givingType: widget.payload['giving_type']?.toString() ?? 'offering',
          projectId: widget.payload['project_id']?.toString());
      final url = Uri.tryParse(result['authorization_url']?.toString() ?? '');
      if (url == null) throw StateError('Payment link was not returned');
      final launched = await launchUrl(url, webOnlyWindowName: '_self');
      if (!launched) throw StateError('Unable to open Paystack');
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(PhosphorIcons.caretLeft(), size: 20)),
          title: Text(widget.payload['title']?.toString() ?? 'Give',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                          child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 12, 18, 22),
                              child: Column(children: [
                                const Spacer(),
                                Text('Enter amount',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: WpccColors.muted)),
                                const SizedBox(height: 10),
                                FittedBox(
                                    child: Text(amountText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -1.4))),
                                const SizedBox(height: 18),
                                Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(22)),
                                    child: Row(children: [
                                      Icon(PhosphorIcons.lockKey(), size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            const Text('Secure payment',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                            Text(
                                                'Continue to Paystack to choose your payment method.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        fontSize: 11,
                                                        color:
                                                            WpccColors.muted))
                                          ]))
                                    ])),
                                if (error != null) ...[
                                  const SizedBox(height: 10),
                                  Semantics(
                                      liveRegion: true,
                                      child: Text(error!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.redAccent)))
                                ],
                                const Spacer(),
                                _Keypad(onKey: press),
                                const SizedBox(height: 16),
                                SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: FilledButton(
                                        onPressed: busy ? null : submit,
                                        style: FilledButton.styleFrom(
                                            backgroundColor: WpccColors.ink,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18))),
                                        child: busy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white))
                                            : const Text('Continue'))),
                              ]))))))));
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});
  final ValueChanged<String> onKey;
  @override
  Widget build(BuildContext context) {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '00',
      '0',
      'back'
    ];
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.7),
        itemBuilder: (context, i) {
          final k = keys[i];
          return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onKey(k),
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: WpccColors.line)),
                  child: Center(
                      child: k == 'back'
                          ? Icon(PhosphorIcons.backspace(), size: 20)
                          : Text(k,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500)))));
        });
  }
}
