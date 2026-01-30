# 🎯 Sessame - Application de Suivi de Projets Personnels

Une application mobile Flutter pour suivre et gérer vos projets personnels avec des rappels intelligents et un suivi de progression.

## ✨ Fonctionnalités

### 📝 Gestion de Projets
- **Créer des projets** avec titre, description et date limite
- **Organiser par statut** : En cours, Terminés, Abandonnés
- **Vue d'ensemble** de tous vos projets avec filtres
- **Modifier et supprimer** facilement vos projets

### ✅ Gestion de Tâches
- **Ajouter des tâches** pour chaque projet
- **Cocher les tâches terminées**
- **Suivi automatique** de la progression
- **Suppression intuitive** par glissement (swipe)

### 🔔 Notifications Intelligentes
- **Rappels personnalisables** (tous les 1-14 jours)
- **Notifications locales** qui demandent votre avancement
- **Programmation automatique** des rappels
- **Gestion des permissions** Android et iOS

### 📊 Statistiques et Analyses
- **Tableau de bord** avec statistiques détaillées
- **Graphiques visuels** (diagramme circulaire)
- **Taux de réussite** de vos projets
- **Projets en retard** mis en évidence

### 🎨 Interface Moderne
- **Design Material 3** élégant et moderne
- **Thème cohérent** avec couleurs personnalisées
- **Animations fluides** et transitions
- **Responsive** et adaptatif
- **Interface en français**

## 🚀 Installation

### Prérequis
- Flutter SDK (>=3.10.4)
- Android Studio / Xcode
- Dart SDK

### Étapes d'installation

1. **Cloner le projet**
```bash
cd sessame
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Nettoyer le cache de build** (recommandé)
```bash
flutter clean
```

4. **Générer les icônes** (optionnel)
```bash
flutter pub run flutter_launcher_icons
```

5. **Lancer l'application**
```bash
# Sur Android
flutter run

# Sur iOS
flutter run

# Mode release
flutter run --release
```

### ⚠️ Note importante pour Android

Ce projet utilise `flutter_local_notifications` qui nécessite le **Core Library Desugaring** pour Android. Cette configuration est déjà intégrée dans `android/app/build.gradle.kts` :

```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

Si vous rencontrez des erreurs de build, assurez-vous que cette configuration est présente.

## 📦 Packages Utilisés

### Core
- **provider** ^6.1.1 - Gestion d'état
- **sqflite** ^2.3.0 - Base de données locale
- **path_provider** ^2.1.1 - Accès aux dossiers système

### Notifications
- **flutter_local_notifications** ^16.3.0 - Notifications locales
- **timezone** ^0.9.2 - Gestion des fuseaux horaires

### UI & Utils
- **intl** ^0.18.1 - Formatage des dates
- **fl_chart** ^0.65.0 - Graphiques statistiques
- **uuid** ^4.2.1 - Génération d'identifiants uniques
- **shared_preferences** ^2.2.2 - Stockage de préférences

## 📱 Architecture

```
lib/
├── main.dart                    # Point d'entrée
├── models/                      # Modèles de données
│   ├── project.dart            # Modèle Projet
│   └── task.dart               # Modèle Tâche
├── providers/                   # Gestion d'état
│   └── project_provider.dart   # Provider principal
├── screens/                     # Écrans de l'application
│   ├── home_screen.dart        # Écran d'accueil
│   ├── add_project_screen.dart # Ajout/Edition de projet
│   ├── project_detail_screen.dart # Détails d'un projet
│   └── statistics_screen.dart  # Statistiques
├── services/                    # Services
│   ├── database_service.dart   # Service base de données
│   └── notification_service.dart # Service notifications
└── widgets/                     # Widgets réutilisables
    └── project_card.dart       # Carte de projet
```

## 🎯 Utilisation

### Créer un Projet
1. Appuyez sur le bouton **"Nouveau projet"**
2. Remplissez le titre et la description
3. Choisissez une date limite
4. Configurez la fréquence des rappels
5. Validez avec **"Créer le projet"**

### Ajouter des Tâches
1. Ouvrez un projet
2. Utilisez le champ en bas pour ajouter une tâche
3. Cochez les tâches terminées
4. La progression se met à jour automatiquement

### Gérer les Notifications
- Les notifications sont envoyées selon la fréquence définie
- Vous pouvez modifier la fréquence à tout moment
- Les notifications s'arrêtent quand le projet est terminé

### Voir les Statistiques
1. Appuyez sur l'icône **graphique** en haut à droite
2. Consultez vos statistiques :
   - Nombre total de projets
   - Projets en cours
   - Projets terminés
   - Projets en retard
   - Taux de réussite

## 🔧 Configuration

### Personnaliser les Notifications

Modifiez dans `notification_service.dart` :
```dart
notificationFrequency: 3, // Fréquence par défaut (jours)
```

### Changer le Thème

Modifiez dans `main.dart` :
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.deepPurple, // Votre couleur
),
```

## 📊 Base de Données

L'application utilise **SQLite** pour stocker :
- Les projets (titre, description, dates, progression, statut)
- Les tâches (titre, état, dates)
- Configuration des notifications

Les données sont persistées localement sur l'appareil.

## 🔔 Permissions

### Android
- `POST_NOTIFICATIONS` - Afficher les notifications
- `SCHEDULE_EXACT_ALARM` - Programmer des alarmes exactes
- `USE_EXACT_ALARM` - Utiliser des alarmes exactes
- `RECEIVE_BOOT_COMPLETED` - Reprogrammer après redémarrage
- `VIBRATE` - Vibration pour les notifications

### iOS
- Notifications - Demandé au premier lancement
- Alertes, badges et sons - Configurables

## 🎨 Captures d'écran

_(Les captures d'écran seront ajoutées après le premier lancement)_

## 🔮 Améliorations Futures

- [ ] Mode sombre
- [ ] Exportation des projets en PDF
- [ ] Synchronisation cloud
- [ ] Partage de projets
- [ ] Rappels par email
- [ ] Catégories de projets
- [ ] Tags et filtres avancés
- [ ] Widget pour l'écran d'accueil
- [ ] Backup et restauration
- [ ] Thèmes personnalisables

## 🔧 Dépannage

### Erreur : "Dependency requires core library desugaring to be enabled"

Cette erreur survient quand le Core Library Desugaring n'est pas activé. **Solution :**

1. Vérifiez que `android/app/build.gradle.kts` contient :
```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

2. Nettoyez le build :
```bash
flutter clean
flutter pub get
flutter run
```

### Build lent ou échec de Gradle

Si le build prend trop de temps ou échoue :

```bash
# Nettoyer le cache Gradle
cd android
./gradlew clean
cd ..

# Nettoyer Flutter
flutter clean
flutter pub get

# Relancer
flutter run
```

### Notifications ne fonctionnent pas

1. Vérifiez les permissions dans `AndroidManifest.xml`
2. Sur Android 13+, assurez-vous d'accepter les permissions de notification
3. Testez avec une notification immédiate d'abord

## 👨‍💻 Développement

### Commandes utiles

```bash
# Analyser le code
flutter analyze

# Formater le code
flutter format lib/

# Tester l'application
flutter test

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Nettoyer complètement
flutter clean && flutter pub get
```

## 📝 License

Ce projet est sous licence MIT.

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📧 Contact

Pour toute question ou suggestion, n'hésitez pas à ouvrir une issue.

---

**Fait avec ❤️ et Flutter**
