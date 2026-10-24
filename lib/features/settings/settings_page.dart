import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/auth/auth.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../ui/asset_icon.dart';
import '../../ui/layout.dart';
import '../../ui/toast.dart';
import '../../ui/widgets.dart';
import '../shell/panel_shell.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(authProvider)?.isAdmin ?? false)) {
      return const PanelPage(
        children: [PageHeader(title: 'Settings', subtitle: 'Only administrators can change platform settings.')],
      );
    }
    final async = ref.watch(query('/admin/settings'));
    final json = async.value as List?;
    if (json == null) {
      return PanelPage(children: [StateText(async.hasError ? errorMessage(async.error!) : 'Loading…', error: async.hasError)]);
    }
    final tabs = json.map((t) => SettingsTab.fromJson(t as Map<String, dynamic>)).toList();
    if (tabs.isEmpty) return const PanelPage(children: [PageHeader(title: 'Settings')]);
    final current = tabs.firstWhere((t) => t.value == tab, orElse: () => tabs.first);

    Future<void> save(SettingField field, Object value) async {
      final toast = ref.read(toastProvider.notifier);
      try {
        await ref.read(apiProvider).put<dynamic>('/admin/settings', {
          'changes': {field.key: value},
        });
        toast.show('${field.label} updated', message: 'Saved and recorded in the audit log.', tone: ToastTone.success);
      } catch (e) {
        toast.show("Couldn't save", message: errorMessage(e), tone: ToastTone.danger);
      }
      // Either way the screen shows what the API now holds.
      ref.invalidate(query('/admin/settings'));
    }

    final cards = [for (final card in current.cards) _SettingsCard(card: card, onSave: save)];

    return PanelPage(
      children: [
        const PageHeader(title: 'Settings', subtitle: 'Platform-wide configuration. Changes apply immediately.'),
        Chips(
          label: 'Settings sections',
          value: current.value,
          items: [for (final t in tabs) ChipItem(t.value, t.label, href: t.value == 'overview' ? '/settings' : '/settings?tab=${t.value}')],
        ),
        if (context.is2xl)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Gap(24, children: [for (var i = 0; i < cards.length; i += 2) cards[i]])),
              const SizedBox(width: 24),
              Expanded(child: Gap(24, children: [for (var i = 1; i < cards.length; i += 2) cards[i]])),
            ],
          )
        else
          Gap(24, children: cards),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.card, required this.onSave});

  final SettingsCard card;
  final Future<void> Function(SettingField field, Object value) onSave;

  @override
  Widget build(BuildContext context) {
    final line = Dak.border.withValues(alpha: .4);
    return MaxWidth(
      700,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Dak.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: line),
          boxShadow: const [BoxShadow(color: Color(0x332B2B31), offset: Offset(0, 4), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(card.title.toUpperCase(), style: cardTitleStyle()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 18),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: line)),
              ),
              child: Column(
                children: [
                  for (final (i, field) in card.fields.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: i == card.fields.length - 1 ? null : Border(bottom: BorderSide(color: line)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              field.label,
                              style: const TextStyle(fontSize: 14, height: 20 / 14, color: Dak.body),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Keyed on the value so a saved/reverted value resets the field's draft.
                          _FieldControl(key: ValueKey('${field.key}:${field.value}'), field: field, onSave: (v) => onSave(field, v)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text and number fields keep a local draft and save on blur/Enter; toggles and selects save at once.
class _FieldControl extends StatefulWidget {
  const _FieldControl({super.key, required this.field, required this.onSave});

  final SettingField field;
  final ValueChanged<Object> onSave;

  @override
  State<_FieldControl> createState() => _FieldControlState();
}

class _FieldControlState extends State<_FieldControl> {
  late final _draft = TextEditingController(text: _initial);
  final _focus = FocusNode();

  String get _initial {
    final v = widget.field.value;
    return v is num && v == v.roundToDouble() ? '${v.round()}' : '$v';
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && mounted) _commit();
    });
  }

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final draft = _draft.text;
    if (draft == _initial) return;
    if (widget.field.kind == 'number') {
      widget.onSave(num.tryParse(draft.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0);
    } else {
      widget.onSave(draft.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    switch (field.kind) {
      case 'toggle':
        return AdmToggle(label: field.label, value: field.value == true, onChanged: widget.onSave);
      case 'select':
        return _Select(field: field, onChanged: widget.onSave);
      default:
        final number = field.kind == 'number';
        return SizedBox(
          width: number ? 70 : 200,
          child: AdmField(
            controller: _draft,
            focusNode: _focus,
            semanticLabel: field.label,
            height: 40,
            radius: 16,
            borderColor: Dak.muted,
            borderWidth: 1,
            padLeft: number ? 8 : 12,
            padRight: number ? 8 : 12,
            fontSize: 14,
            textAlign: number ? TextAlign.center : TextAlign.right,
            keyboardType: number ? TextInputType.number : null,
            onSubmitted: (_) => _focus.unfocus(),
          ),
        );
    }
  }
}

class _Select extends StatelessWidget {
  const _Select({required this.field, required this.onChanged});

  final SettingField field;
  final ValueChanged<Object> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = '${field.value}';
    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 103),
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Dak.muted),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: field.options.contains(value) ? value : null,
          isDense: true,
          dropdownColor: Dak.surface,
          borderRadius: BorderRadius.circular(12),
          focusColor: Colors.transparent,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 20 / 14, color: Dak.heading),
          icon: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Transform.rotate(angle: -math.pi / 2, child: const AssetIcon('icons/select-chevron.svg', width: 18, height: 18)),
          ),
          items: [for (final o in field.options) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: (v) {
            if (v != null && v != value) onChanged(v);
          },
        ),
      ),
    );
  }
}
