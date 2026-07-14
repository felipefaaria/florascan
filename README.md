# 🌿 FloraScan

Aplicativo móvel (Flutter) para **identificar plantas a partir de fotos** e
**aprender a cuidar delas**. O usuário fotografa uma planta, o app a identifica
via API do PlantNet e gera dicas de cuidado (água, solo, bioma e plantas
compatíveis) usando IA. As plantas podem ser salvas e organizadas em "jardins".

---

## ✨ Funcionalidades

- 📷 **Identificação de plantas** por câmera ou galeria (API PlantNet).
- 🤖 **Dicas de cuidado geradas por IA** (Azure OpenAI): rega, solo, bioma e
  harmonização com outras plantas.
- 🪴 **Meus Jardins**: crie categorias e organize suas plantas salvas.
- 🔐 **Autenticação** de usuários com Firebase Auth (login/cadastro e modo convidado).
- 💾 **Persistência local** das plantas e do perfil com SQLite (`sqflite`).
- 🖥️ Suporte a **Android, iOS, Web, Windows, macOS e Linux** (foco em mobile).

---

## 🛠️ Tecnologias

| Área            | Ferramenta                               |
| --------------- | ---------------------------------------- |
| Framework       | Flutter / Dart                           |
| Autenticação    | Firebase Auth + Firebase Core            |
| Banco local     | sqflite / sqflite_common_ffi             |
| Identificação   | [PlantNet API](https://my.plantnet.org/) |
| IA de cuidados  | Azure OpenAI                             |
| Imagens         | image_picker                             |
| Config/Segredos | flutter_dotenv (`.env`)                  |
| Fontes          | google_fonts                             |

---

## 📁 Estrutura do projeto

```
FloraScan/
├── lib/
│   ├── main.dart                 # Ponto de entrada, tema, AuthGate e navegação
│   ├── firebase_options.dart     # Configuração gerada pelo FlutterFire
│   ├── database/
│   │   └── db.dart               # Camada SQLite (plantas, categorias, usuários)
│   ├── screens/                  # Telas do app
│   │   ├── welcome_screen.dart
│   │   ├── login_choice_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── initial_home.dart
│   │   ├── my_garden.dart
│   │   ├── camera.dart
│   │   ├── caretips.dart
│   │   └── profile.dart
│   ├── widgets/                  # Componentes reutilizáveis
│   │   ├── care_detail_card.dart
│   │   └── plant_details_modal.dart
│   └── utils/
│       └── ai_service.dart       # Integração com Azure OpenAI
├── assets/images/                # Imagens estáticas
├── test/                         # Testes de widget
├── android/ ios/ web/ ...        # Projetos nativos por plataforma
└── pubspec.yaml
```

---

## 🚀 Como executar

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>= 3.7.2`)
- Um emulador/dispositivo, ou navegador para a versão web
- Projeto Firebase configurado (os arquivos `firebase_options.dart` e
  `google-services.json` já acompanham o repositório)

### 1. Instalar dependências

```bash
flutter pub get
```

### 2. Rodar o app

```bash
flutter run
```
