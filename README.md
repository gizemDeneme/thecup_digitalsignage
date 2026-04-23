# thecup Digital Signage

Flutter + Firebase tabanlı dijital tabela sistemi. Tek kod tabanı, iki uygulama:

- **Admin App** (iOS/Android) — video, görsel, menü ve fiyat listesi yönetimi
- **TV App** (Android TV) — gerçek zamanlı içerik gösterimi, offline destek

## Kurulum

### 1. Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) → Proje: `thecup-signage`
2. 3 uygulama kaydet:
   - Android Admin: `com.thecup.admin`
   - iOS Admin: `com.thecup.admin`
   - Android TV: `com.thecup.tv`
3. Auth → Email/Password aç
4. Firestore → `europe-west1` region
5. Storage → Default bucket
6. FlutterFire CLI ile yapılandır:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=thecup-signage
```

7. Firestore & Storage kurallarını deploy et:

```bash
firebase deploy --only firestore:rules,storage:rules
```

8. Firebase Console → Authentication → İlk admin kullanıcısını oluştur
9. Firestore → `admins/{uid}` dökümanını yaz: `{ "email": "...", "createdAt": ... }`

### 2. Çalıştırma

```bash
# Admin (telefon)
flutter run --flavor admin -t lib/main_admin.dart

# TV (Android TV)
flutter run --flavor tv -t lib/main_tv.dart

# TV release APK
flutter build apk --flavor tv -t lib/main_tv.dart --release
```

## Mimari

```
lib/
├── main_admin.dart          # Admin entry point
├── main_tv.dart             # TV entry point
├── core/                    # DI, sabitler
├── data/                    # Modeller, servisler, repository'ler
├── admin/                   # Admin uygulama (ekranlar, provider'lar)
└── tv/                      # TV uygulama (display, controller, cache)
```

## İçerik Tipleri

| Tip | Açıklama |
|-----|---------|
| Video | MP4 dosyaları — Firebase Storage'a yüklenir |
| Görsel | JPG/PNG — Firebase Storage'a yüklenir |
| Menü | Kategorili menü — Firestore'da tutulur |
| Fiyat Listesi | Fiyat tablosu — Firestore'da tutulur |

## Yayın Akışı

1. Admin uygulaması → Playlist editörü → "Yayınla"
2. Firestore `playlists/active` güncellenir (atomik)
3. Tüm TV'lerdeki Firestore listener tetiklenir (~1-2 saniye)
4. TV'ler yeni playlist'i Hive cache'e yazar ve oynatmaya başlar
