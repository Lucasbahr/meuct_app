import 'package:flutter/material.dart';
import '../services/admin_service.dart';

/// Diálogo + chamada à API para o professor registrar presença do aluno.
Future<void> registerStudentAttendance({
  required BuildContext context,
  required AdminService service,
  required Map<String, dynamic> student,
  void Function(bool busy)? onBusy,
  VoidCallback? onSuccess,
}) async {
  final rawId = student['id'];
  final id = rawId is int
      ? rawId
      : rawId is num
          ? rawId.toInt()
          : null;
  if (id == null) return;
  final nome = (student['nome'] ?? 'Aluno').toString();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Registrar presença'),
      content: Text(
        'Registrar presença de "$nome" para hoje?\n\n'
        'Use quando o aluno não puder usar o app no celular.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  onBusy?.call(true);
  try {
    await service.checkInForStudent(id);
    if (!context.mounted) return;
    onSuccess?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Presença de $nome registrada.')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
      ),
    );
  } finally {
    onBusy?.call(false);
  }
}
