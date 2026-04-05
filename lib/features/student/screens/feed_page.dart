import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/graduacao/bjj_graduacao.dart';
import '../../../core/auth/session_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../widgets/cached_auth_network_image.dart';
import '../../../widgets/loading_overlay.dart';
import '../../feed/services/feed_service.dart';
import '../services/student_service.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _feedService = FeedService();
  final _sessionService = SessionService();
  final _tokenStorage = TokenStorage();
  late Future<List<Map<String, dynamic>>> _feedFuture;
  bool _isAdmin = false;
  String? _token;
  Map<String, dynamic>? _me;
  int? _myTokenUserId;
  Map<String, String> _nameByUserId = {};
  /// Publicar, editar, excluir post (API + refresh).
  String? _blockingMessage;
  int? _pendingLikePostId;

  @override
  void initState() {
    super.initState();
    _feedFuture = _feedService.listFeed();
    _loadRole();
    _loadToken();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final uid = await _sessionService.getTokenUserId();
    Map<String, dynamic>? me;
    try {
      me = await StudentService().getMe();
    } catch (_) {
      me = null;
    }
    final names = <String, String>{};
    try {
      final students = await StudentService().listStudentsForNameLookup();
      for (final s in students) {
        final nome = (s['nome'] ?? '').toString().trim();
        if (nome.isEmpty) continue;
        for (final key in ['user_id', 'usuario_id']) {
          final v = s[key];
          if (v != null) names[v.toString()] = nome;
        }
        final sid = s['id'];
        if (sid != null) {
          names.putIfAbsent(sid.toString(), () => nome);
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _myTokenUserId = uid;
      _me = me;
      _nameByUserId = names;
    });
  }

  Future<void> _loadRole() async {
    final isAdmin = await _sessionService.isAdmin();
    if (!mounted) return;
    setState(() => _isAdmin = isAdmin);
  }

  Future<void> _loadToken() async {
    final t = await _tokenStorage.getToken();
    if (!mounted) return;
    setState(() => _token = t);
  }

  Future<void> _refresh() async {
    setState(() => _feedFuture = _feedService.listFeed());
  }

  String _normalizeDescription(String raw) {
    var s = raw.replaceAll('\r\n', '\n').replaceAll(r'\n', '\n');
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s.replaceAll('\u2028', '\n').replaceAll('\u2029', '\n');
    return s.trim();
  }

  Widget _buildFeedDescription(String desc) {
    final text = _normalizeDescription(desc);
    if (text.isEmpty) return const SizedBox.shrink();
    const style = TextStyle(
      color: Colors.white70,
      height: 1.4,
      fontSize: 14.5,
    );
    final lines = text.split(RegExp(r'\r\n|\n|\r'));
    if (lines.length <= 1) {
      return SizedBox(
        width: double.infinity,
        child: Text(text, style: style, softWrap: true),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            Text(
              lines[i].isEmpty ? '\u00A0' : lines[i],
              style: style,
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }

  String _displayNameFromPersonMap(Map<String, dynamic> m) {
    const keys = [
      'nome',
      'name',
      'user_name',
      'usuario_nome',
      'full_name',
      'email',
    ];
    for (final key in keys) {
      final v = m[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    final id = m['id'] ?? m['user_id'];
    if (id != null) return 'Usuário #$id';
    return 'Usuário';
  }

  String _commentAuthorLabel(Map<String, dynamic> c) {
    final cUser = c['user_id'] ?? c['usuario_id'];
    if (cUser != null) {
      final cached = _nameByUserId[cUser.toString()];
      if (cached != null && cached.isNotEmpty) return cached;
      if (_myTokenUserId != null &&
          cUser.toString() == _myTokenUserId.toString()) {
        final n = (_me?['nome'] ?? '').toString().trim();
        if (n.isNotEmpty) return n;
      }
    }
    const keys = [
      'nome',
      'user_name',
      'nome_usuario',
      'usuario_nome',
      'aluno_nome',
      'name',
      'author_name',
      'autor',
      'autor_nome',
    ];
    for (final key in keys) {
      final v = c[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    if (_me != null) {
      final myNome = (_me!['nome'] ?? '').toString().trim();
      if (myNome.isNotEmpty) {
        final mySid = _me!['id'];
        final myUid = _me!['user_id'] ?? _me!['usuario_id'];
        final cAluno = c['aluno_id'] ?? c['student_id'];
        if (mySid != null &&
            cAluno != null &&
            mySid.toString() == cAluno.toString()) {
          return myNome;
        }
        if (myUid != null &&
            cUser != null &&
            myUid.toString() == cUser.toString()) {
          return myNome;
        }
      }
    }
    for (final nestedKey in ['user', 'usuario', 'aluno', 'student', 'author']) {
      final nested = c[nestedKey];
      if (nested is Map) {
        return _displayNameFromPersonMap(Map<String, dynamic>.from(nested));
      }
    }
    final id = c['user_id'] ?? c['usuario_id'];
    if (id != null) return 'Usuário #$id';
    return 'Usuário';
  }

  String? _feedImageLink(Map<String, dynamic> item) {
    for (final k in [
      'imagem_link',
      'link_imagem',
      'image_link',
      'url_imagem',
      'link',
    ]) {
      final v = item[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  Future<void> _openExternalUrl(String raw) async {
    var s = raw.trim();
    if (s.isEmpty) return;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    final u = Uri.tryParse(s);
    if (u == null) return;
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  void _onFeedImageTap(String imageUrl, Map<String, dynamic> item) {
    final link = _feedImageLink(item);
    if (link != null) {
      _openExternalUrl(link);
    } else {
      _openImageFullScreen(imageUrl);
    }
  }

  void _openImageFullScreen(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.6,
                maxScale: 4,
                child: SizedBox(
                  width: MediaQuery.sizeOf(ctx).width,
                  height: MediaQuery.sizeOf(ctx).height,
                  child: CachedAuthNetworkImage(
                    imageUrl: imageUrl,
                    token: _token,
                    fit: BoxFit.contain,
                    memCacheWidth: 1600,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(ctx).top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id is! int) return;
    if (_pendingLikePostId != null) return;
    final likedBefore = item['liked_by_me'] == true;
    final countBefore = (item['like_count'] as num?)?.toInt() ?? 0;

    setState(() {
      _pendingLikePostId = id;
      item['liked_by_me'] = !likedBefore;
      item['like_count'] = likedBefore ? countBefore - 1 : countBefore + 1;
    });

    try {
      if (likedBefore) {
        await _feedService.unlike(id);
      } else {
        await _feedService.like(id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        item['liked_by_me'] = likedBefore;
        item['like_count'] = countBefore;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _pendingLikePostId = null);
    }
  }

  bool _canDeleteComment(Map<String, dynamic> c) {
    if (_isAdmin) return true;
    final u = c['user_id'] ?? c['usuario_id'];
    if (u == null || _myTokenUserId == null) return false;
    return u.toString() == _myTokenUserId.toString();
  }

  bool _canDeletePost(Map<String, dynamic> item) {
    if (_isAdmin) return true;
    final u = item['user_id'] ??
        item['created_by_user_id'] ??
        item['author_user_id'];
    if (u == null || _myTokenUserId == null) return false;
    return u.toString() == _myTokenUserId.toString();
  }

  Future<void> _confirmDeletePost(Map<String, dynamic> item) async {
    final pid = item['id'];
    if (pid is! int) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir post'),
        content: const Text(
          'Tem certeza? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _blockingMessage = 'Excluindo post...');
    try {
      await _feedService.deleteItem(pid);
      if (!mounted) return;
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post excluído.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _blockingMessage = null);
    }
  }

  Future<void> _showComments(Map<String, dynamic> item) async {
    final id = item["id"];
    if (id is! int) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _FeedCommentsSheet(
            itemId: id,
            feedService: _feedService,
            authorLabel: _commentAuthorLabel,
            canDeleteComment: _canDeleteComment,
            onFeedNeedRefresh: _refresh,
          ),
        );
      },
    );
  }

  Future<void> _createOrEdit({Map<String, dynamic>? existing}) async {
    final titleController =
        TextEditingController(text: (existing?["titulo"] ?? "").toString());
    final descController =
        TextEditingController(text: (existing?["descricao"] ?? "").toString());
    final localController =
        TextEditingController(text: (existing?["local"] ?? "").toString());
    final modalidadeController =
        TextEditingController(text: (existing?["modalidade"] ?? "").toString());
    String graduacaoPost =
        graduacaoSelecionavelInicial(existing?["graduacao"]?.toString());
    final eventoDataController =
        TextEditingController(text: (existing?["evento_data"] ?? "").toString());
    final linkImagemController = TextEditingController(
      text: (existing?["imagem_link"] ??
              existing?["link_imagem"] ??
              existing?["image_link"] ??
              "")
          .toString(),
    );

    String tipo = (existing?["tipo"] ?? "evento").toString();
    String? imagePath;

    String? formError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(existing == null ? "Novo post" : "Editar post"),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (formError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            formError!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        initialValue: tipo,
                        items: const [
                          DropdownMenuItem(value: "luta", child: Text("Luta")),
                          DropdownMenuItem(value: "evento", child: Text("Evento")),
                          DropdownMenuItem(
                            value: "graduacao",
                            child: Text("Graduação"),
                          ),
                        ],
                        onChanged: (v) => setLocal(() => tipo = v ?? "evento"),
                        decoration: const InputDecoration(labelText: "Tipo"),
                      ),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: "Título"),
                      ),
                      TextField(
                        controller: descController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 3,
                        maxLines: 12,
                        decoration: const InputDecoration(
                          labelText: "Descrição",
                          alignLabelWithHint: true,
                          hintText: "Use Enter para nova linha",
                        ),
                      ),
                      TextField(
                        controller: eventoDataController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Data evento (YYYY-MM-DD)",
                        ),
                        onTap: () async {
                          DateTime initialDate = DateTime.now();
                          final current = DateTime.tryParse(
                            eventoDataController.text.trim(),
                          );
                          if (current != null) initialDate = current;
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            final month = picked.month.toString().padLeft(2, "0");
                            final day = picked.day.toString().padLeft(2, "0");
                            setLocal(() {
                              eventoDataController.text =
                                  "${picked.year}-$month-$day";
                            });
                          }
                        },
                      ),
                      TextField(
                        controller: localController,
                        decoration: const InputDecoration(labelText: "Local"),
                      ),
                      TextField(
                        controller: modalidadeController,
                        decoration: const InputDecoration(labelText: "Modalidade"),
                      ),
                      if (tipo == "graduacao") ...[
                        DropdownButtonFormField<String>(
                          value: alignGraduacaoDropdownValue(
                            graduacaoPost,
                            graduacoesDropdownItens(valorAtual: graduacaoPost),
                          ),
                          decoration:
                              const InputDecoration(labelText: "Graduação"),
                          items: graduacoesDropdownItens(valorAtual: graduacaoPost)
                              .map(
                                (g) => DropdownMenuItem<String>(
                                  value: g,
                                  child: Text(formatGraduacaoDisplay(g)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setLocal(
                            () => graduacaoPost =
                                v ?? graduacaoInicialAluno,
                          ),
                        ),
                      ],
                      TextField(
                        controller: linkImagemController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: "Link ao tocar na imagem (opcional)",
                          hintText: "https://...",
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 82,
                          );
                          if (img != null) {
                            setLocal(() => imagePath = img.path);
                          }
                        },
                        icon: const Icon(Icons.photo),
                        label: Text(
                          imagePath == null ? "Selecionar imagem" : "Imagem selecionada",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      setLocal(() {
                        formError = "Título é obrigatório.";
                      });
                      return;
                    }
                    final data = eventoDataController.text.trim();
                    if (data.isNotEmpty && DateTime.tryParse(data) == null) {
                      setLocal(() {
                        formError = "Data inválida. Use YYYY-MM-DD.";
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    setState(() {
      _blockingMessage =
          existing == null ? 'Publicando...' : 'Atualizando post...';
    });

    final payload = <String, dynamic>{
      "tipo": tipo,
      "titulo": titleController.text.trim(),
      if (descController.text.trim().isNotEmpty) "descricao": descController.text.trim(),
      if (eventoDataController.text.trim().isNotEmpty)
        "evento_data": eventoDataController.text.trim(),
      if (localController.text.trim().isNotEmpty) "local": localController.text.trim(),
      if (modalidadeController.text.trim().isNotEmpty)
        "modalidade": modalidadeController.text.trim(),
      if (tipo == "graduacao")
        "graduacao":
            canonicalGraduacaoBjj(graduacaoPost) ?? graduacaoPost.trim(),
      if (linkImagemController.text.trim().isNotEmpty)
        "imagem_link": linkImagemController.text.trim(),
    };

    try {
      if (existing == null) {
        final created = await _feedService.createItem(payload);
        final id = created["id"];
        if (id is int && imagePath != null) {
          await _feedService.uploadPhoto(id, imagePath!);
        }
      } else {
        final id = existing["id"];
        if (id is int) {
          await _feedService.updateItem(id, payload);
          if (imagePath != null) {
            await _feedService.uploadPhoto(id, imagePath!);
          }
        }
      }
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _blockingMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feed"),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => _createOrEdit(),
              child: const Icon(Icons.add),
            )
          : null,
      body: LoadingOverlay(
        visible: _blockingMessage != null,
        message: _blockingMessage ?? '',
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _feedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    snapshot.error.toString().replaceFirst("Exception: ", ""),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(child: Text("Sem publicações."));
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final postId = item["id"];
                final title = (item["titulo"] ?? "").toString();
                final type = (item["tipo"] ?? "").toString();
                final desc = (item["descricao"] ?? "").toString();
                final imageUrl = _feedService.resolveImageUrl(item["image_url"]);
                final likes = (item["like_count"] as num?)?.toInt() ?? 0;
                final comments = (item["comment_count"] as num?)?.toInt() ?? 0;
                final liked = item["liked_by_me"] == true;

                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(type.toUpperCase()),
                          ),
                          const Spacer(),
                          if (_isAdmin)
                            IconButton(
                              onPressed: () => _createOrEdit(existing: item),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar',
                            ),
                          if (_canDeletePost(item))
                            IconButton(
                              onPressed: () => _confirmDeletePost(item),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Excluir post',
                            ),
                        ],
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildFeedDescription(desc),
                      ],
                      if (imageUrl != null) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _onFeedImageTap(imageUrl, item),
                          onLongPress: _feedImageLink(item) != null
                              ? () => _openImageFullScreen(imageUrl)
                              : null,
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              CachedAuthNetworkImage(
                                imageUrl: imageUrl,
                                token: _token,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(10),
                                memCacheWidth: 900,
                              ),
                              if (_feedImageLink(item) != null)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Material(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.open_in_new,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_feedImageLink(item) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Toque: abrir o link · Toque longo: ver imagem em tela cheia',
                              style: TextStyle(
                                color: Colors.blue.shade200,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            tooltip: liked ? 'Descurtir' : 'Curtir',
                            onPressed: _pendingLikePostId != null
                                ? null
                                : () => _toggleLike(item),
                            icon: postId is int &&
                                    _pendingLikePostId == postId
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: liked ? Colors.red : null,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            child: Text(
                              '$likes',
                              style: TextStyle(
                                color: likes > 0
                                    ? Colors.white70
                                    : Colors.white38,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showComments(item),
                            icon: const Icon(Icons.comment_outlined),
                            label: Text("$comments"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
          },
        ),
      ),
    );
  }
}

class _FeedCommentsSheet extends StatefulWidget {
  const _FeedCommentsSheet({
    required this.itemId,
    required this.feedService,
    required this.authorLabel,
    required this.canDeleteComment,
    required this.onFeedNeedRefresh,
  });

  final int itemId;
  final FeedService feedService;
  final String Function(Map<String, dynamic>) authorLabel;
  final bool Function(Map<String, dynamic>) canDeleteComment;
  final Future<void> Function() onFeedNeedRefresh;

  @override
  State<_FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<_FeedCommentsSheet> {
  late Future<List<Map<String, dynamic>>> _future;
  final _controller = TextEditingController();
  bool _sending = false;
  String? _sheetOverlayMsg;

  @override
  void initState() {
    super.initState();
    _future = widget.feedService.listComments(widget.itemId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.feedService.listComments(widget.itemId);
    });
  }

  Object? _commentRowId(Map<String, dynamic> c) {
    return c['id'] ?? c['comment_id'] ?? c['pk'];
  }

  Future<void> _sendComment() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _sheetOverlayMsg = 'Enviando comentário...';
    });
    try {
      await widget.feedService.addComment(widget.itemId, txt);
      if (!mounted) return;
      _controller.clear();
      _reload();
      await widget.onFeedNeedRefresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _sheetOverlayMsg = null;
        });
      }
    }
  }

  Future<void> _confirmDeleteComment(Map<String, dynamic> c) async {
    final cid = _commentRowId(c);
    if (cid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir comentário'),
        content: const Text('Remover este comentário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _sheetOverlayMsg = 'Removendo comentário...');
    try {
      await widget.feedService.deleteComment(widget.itemId, cid);
      if (!mounted) return;
      _reload();
      await widget.onFeedNeedRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentário excluído.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sheetOverlayMsg = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: LoadingOverlay(
        visible: _sheetOverlayMsg != null,
        message: _sheetOverlayMsg ?? '',
        child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'Comentários',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        snapshot.error.toString().replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('Nenhum comentário ainda.'),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    final showDel = widget.canDeleteComment(c);
                    return ListTile(
                      title: Text((c['conteudo'] ?? '').toString()),
                      subtitle: Text(widget.authorLabel(c)),
                      trailing: showDel
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Excluir',
                              onPressed: () => _confirmDeleteComment(c),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Comentar...',
                    ),
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _sendComment,
                  icon: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

