# 🥊 Genesis MMA

Aplicação mobile desenvolvida em **Flutter** para a academia **Genesis MMA**.

O app contempla funcionalidades para **alunos e administradores**, com foco em gestão de presença, engajamento e acompanhamento de desempenho.

---

# 🚀 Funcionalidades

## 👤 Alunos
- Perfil do aluno
- Check-in na academia
- Feed de conteúdos
- Visualização de atletas
- Autenticação segura (JWT)

## 🛠️ Administradores
- Listagem de alunos
- Check-in manual
- Ranking de alunos
- Gestão de presença

---

# 🧱 Stack utilizada

- **Flutter** (UI mobile)
- **Dart**
- **REST API**
- **JWT Authentication**
- **Secure Storage** (`flutter_secure_storage`)
- **CI/CD com GitHub Actions**
- **Página de download (Firebase Hosting Spark) + APK no GitHub Releases**

---

# ⚙️ Requisitos

- Flutter (canal `stable`)
- Dart (compatível com `pubspec.yaml`)
- JDK **17**
- Android Studio / SDK Android
- Xcode (opcional - iOS)

---

# ▶️ Como rodar o projeto

```bash
flutter pub get
flutter run
```

---

# 📦 Build Android (APK)

```bash
flutter build apk --release
```

O APK sai em `build/app/outputs/flutter-apk/`.

---

# 🌐 Firebase Hosting + download do APK (100% grátis, sem Blaze)

O **Firebase exige plano Blaze** (conta de faturamento) para usar **Cloud Storage** em projetos novos — ver [FAQ oficial](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024). Por isso **não usamos Storage** neste fluxo.

**O que usamos (sem cartão):**

| O quê | Onde | Plano |
|--------|------|--------|
| Página com botão “Baixar APK” | **Firebase Hosting** | **Spark** (grátis) |
| Arquivo `.apk` | **GitHub Releases** | Grátis no GitHub |

No Spark, o Hosting **não aceita** hospedar o `.apk` (executável). O CI publica o APK como release e a página aponta para:

`https://github.com/SEU_USUARIO/SEU_REPO/releases/latest/download/genesismma.apk`

O workflow substitui automaticamente o placeholder `__APK_DOWNLOAD_URL__` em `public/index.html` no deploy.

**Repositório privado:** o link `latest/download/...` só funciona para quem tem acesso ao GitHub. Para alunos baixarem sem conta, use repositório **público** ou outro hospedeiro de arquivo.

### Manual (só Hosting)

1. `npm install -g firebase-tools` e `firebase login`
2. `firebase use meuct-app`
3. Ajuste o `href` do botão em `public/index.html` (ou o placeholder) se for deploy manual
4. `firebase deploy --only hosting`

Site: `https://meuct-app.web.app` (ou `.firebaseapp.com`).

---

# 🔗 API

URL base em `lib/core/api/api_client.dart` (`ApiClient.baseUrl`).

---

# 🤖 CI/CD

Workflow [`.github/workflows/build-and-distribute-apk.yml`](.github/workflows/build-and-distribute-apk.yml):

- `permissions: contents: write` — necessário para criar **GitHub Release** com o APK.
- Build APK → **Release** com anexo `genesismma.apk` (`make_latest: true`).
- Substitui `__APK_DOWNLOAD_URL__` na página → **`firebase deploy --only hosting`**.

**Secret:** `FIREBASE_SERVICE_ACCOUNT` — JSON com permissão de **Firebase Hosting Admin** (ou **Editor** no projeto). **Não** precisa mais de Storage / gcloud.

**GitHub Actions:** [limites gratuitos](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions) conforme o plano do repositório.