# Firebase setup (Auth + Firestore)

## 1) Structure Firestore recommandÃ©e

Chaque utilisateur a **son document** puis une sous-collection de projets :

```
users/{uid}
  projects/{projectId}
    tasks/{taskId}
```

L'app Ã©crit dans `users/{uid}/projects/*` et `tasks/*` via `lib/services/firestore_service.dart`.

## 2) Activer l'auth par tÃ©lÃ©phone (obligatoire)

Firebase Console â†’ **Authentication** â†’ **Sign-in method** :
- Activer **Phone**

### Android
Firebase Console â†’ Project settings â†’ **Your apps (Android)** :
- Ajouter les empreintes **SHA-1** et **SHA-256** de ton keystore (debug + release)
- TÃ©lÃ©charger `google-services.json` dans `android/app/`

### iOS
Firebase Console â†’ Project settings â†’ **Your apps (iOS)** :
- TÃ©lÃ©charger `GoogleService-Info.plist` et le placer dans `ios/Runner/`
- Ouvrir `ios/Runner.xcworkspace` et vÃ©rifier que le plist est bien inclus dans Runner

## 3) Activer Firestore + rÃ¨gles de sÃ©curitÃ©

Firebase Console â†’ **Firestore Database** â†’ Create database.

RÃ¨gles minimales (Ã  adapter) :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /projects/{projectId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;

        match /tasks/{taskId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
  }
}
```

## 4) Ajouter Google / Facebook comme fournisseurs

Firebase Console â†’ **Authentication** â†’ **Sign-in method** :

### Google
- Activer **Google**
- (Android) s'assurer que SHA-1/SHA-256 sont dÃ©clarÃ©s
- (iOS) s'assurer que le `REVERSED_CLIENT_ID` est bien dans `ios/Runner/Info.plist` (flutterfire le gÃ©nÃ¨re si tu utilises FlutterFire)

### Facebook
- Activer **Facebook** dans Firebase
- CrÃ©er une app sur Meta for Developers et rÃ©cupÃ©rer `App ID` + `App Secret`
- Dans Firebase, coller `App ID`/`App Secret`
- Ajouter l'URI de redirection OAuth indiquÃ© par Firebase dans la console Meta

## 5) CÃ´tÃ© app (Flutter)

- `lib/screens/auth_screen.dart` : login par tÃ©lÃ©phone (SMS)
- `lib/providers/project_provider.dart` : Ã©crit sur Firestore quand l'utilisateur est connectÃ©
- Premier login : si Firestore est vide et SQLite contient des projets, l'app upload local â†’ cloud (best effort).

