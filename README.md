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
- **Distribuição via Firebase App Distribution**

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

O APK sai em `build/app/outputs/flutter-apk/`. Para a página de download do Hosting, copie renomeando:

```bash
# Windows (PowerShell), ajuste o caminho do APK se for outro nome:
Copy-Item build\app\outputs\flutter-apk\app-release.apk public\downloads\genesismma.apk
```

---

# 🌐 Firebase Hosting (página de download do APK)

Há um site estático em `public/` e a config em `firebase.json` + `.firebaserc` (projeto padrão: **meuct-app**, o mesmo do `google-services.json`).

1. Instale a CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Confirme o projeto: `firebase use meuct-app` (ou o ID do seu projeto Firebase)
4. Coloque o arquivo **`public/downloads/genesismma.apk`** (build release)
5. Publicar: **`firebase deploy --only hosting`**

Depois do deploy, o Firebase mostra a URL (ex.: `https://meuct-app.web.app` ou `https://meuct-app.firebaseapp.com`). Os alunos abrem o link e baixam o APK pelo botão da página.

**Nota:** APKs grandes não entram no Git por padrão (veja `.gitignore`). O **CI** copia o APK para `public/downloads/genesismma.apk` e faz o deploy do Hosting automaticamente.

A pasta antiga `android/web-download/` foi substituída por **`public/`** na raiz do repositório.

---

# 🔗 API

URL base em `lib/core/api/api_client.dart` (`ApiClient.baseUrl`).

---

# 🤖 CI/CD

Workflow [`.github/workflows/build-and-distribute-apk.yml`](.github/workflows/build-and-distribute-apk.yml):

- Dispara em push em **`main`** ou **`master`** (e `workflow_dispatch`).
- Gera APK release e copia para **`public/downloads/genesismma.apk`**.
- Roda **`firebase deploy --only hosting`** no projeto **`meuct-app`**.

**Secret obrigatório no GitHub** (Settings → Secrets → Actions):

| Secret | Descrição |
|--------|-----------|
| `FIREBASE_SERVICE_ACCOUNT` | JSON completo de uma conta de serviço Google com permissão para **Firebase Hosting Admin** (ou papel **Editor** no projeto). |

Crie a chave em: Google Cloud Console → IAM → conta de serviço → Chaves → JSON. No Firebase Console, em **Hosting**, o projeto já deve ter o site criado pelo menos uma vez (deploy manual ou pela CLI).