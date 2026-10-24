import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/auth/auth.dart';
import '../../core/format.dart';
import '../../core/query.dart';
import '../../models/admin.dart';
import '../../theme/tokens.dart';
import '../../ui/layout.dart';
import '../../ui/toast.dart';
import '../../ui/widgets.dart';
import '../shell/panel_shell.dart';

/// Terms & Conditions and Privacy Policy share this layout (Figma 792:7285 / 792:7364): the document
/// in a 770px card, with Edit swapping it for a text area plus Save/Cancel. Saving publishes a new
/// version; the user app's /terms and /privacy pages show the latest one.
class PolicyEditor extends ConsumerStatefulWidget {
  const PolicyEditor({super.key, required this.title, required this.type});

  final String title;

  /// "terms" | "privacy"
  final String type;

  @override
  ConsumerState<PolicyEditor> createState() => _PolicyEditorState();
}

class _PolicyEditorState extends ConsumerState<PolicyEditor> {
  TextEditingController? _draft;
  var _saving = false;

  String get _path => '/admin/policies/${widget.type}';

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  void _edit(String content) => setState(() => _draft = TextEditingController(text: content));

  void _cancel() {
    final draft = _draft;
    setState(() => _draft = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => draft?.dispose());
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || draft.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final toast = ref.read(toastProvider.notifier);
    try {
      final published = Policy.fromJson(await ref.read(apiProvider).put<Map<String, dynamic>>(_path, {'content': draft.text}));
      ref.invalidate(query(_path));
      _cancel();
      toast.show('${widget.title} updated', message: 'Version ${published.version} is live for every user.', tone: ToastTone.success);
    } catch (e) {
      toast.show("Couldn't publish", message: errorMessage(e), tone: ToastTone.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(query(_path));
    final json = async.value;
    final data = json == null ? null : Policy.fromJson(json as Map<String, dynamic>);
    final draft = _draft;

    return PanelPage(
      gap: 32,
      children: [
        PageHeader(
          title: widget.title,
          subtitle: data != null
              ? 'Version ${data.version} · published ${formatDate(data.publishedAt)}'
              : 'Manage your privacy preferences and policies.',
          actions: draft == null
              ? [
                  AdmButton(
                    label: 'Edit',
                    onTap: data == null && !async.hasError ? null : () => _edit(data?.content ?? ''),
                    icon: 'icons/edit-pencil.svg',
                    iconSize: 24,
                    fill: Dak.cta,
                    height: 40,
                    radius: 12,
                    padX: 24,
                  ),
                ]
              : [
                  AdmButton(label: 'Cancel', onTap: _cancel, border: Dak.body, color: Dak.body, height: 40, radius: 12, padX: 24),
                  ListenableBuilder(
                    listenable: draft,
                    builder: (context, _) => AdmButton(
                      label: _saving ? 'Publishing…' : 'Save',
                      onTap: _saving || draft.text.trim().isEmpty ? null : _save,
                      fill: Dak.cta,
                      height: 40,
                      radius: 12,
                      padX: 24,
                    ),
                  ),
                ],
        ),
        MaxWidth(
          770,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Dak.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 1)],
            ),
            child: draft == null
                ? Text(
                    data?.content ?? (async.hasError ? 'No published version yet — click Edit to write the first one.' : 'Loading…'),
                    style: const TextStyle(fontSize: 16, height: 31 / 16, color: Dak.body),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 480),
                    child: AdmField(
                      controller: draft,
                      semanticLabel: '${widget.title} text',
                      autofocus: true,
                      height: null,
                      lines: 15,
                      radius: 8,
                      borderColor: Dak.border,
                      borderWidth: 1,
                      padLeft: 12,
                      padRight: 12,
                      textColor: Dak.body,
                      lineHeight: 31 / 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
