#!/bin/bash
set -e
cd ~/chore.me
export PATH=/root/flutter-sdk/bin:$PATH

git add -A
git commit -m "Pre-autobuild: source sync $(date +%Y-%m-%d\ %H:%M)" || true
git pull origin main
cd chore_checker
flutter channel stable
flutter upgrade
flutter pub get
flutter precache --web
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false
cd ..
rm -rf build/*
cp -r chore_checker/build/web/. build/
git add build/
git commit -m "Autobuild Flutter web to root/build $(date +%Y-%m-%d\ %H:%M)" || true
git push origin main
echo "Autobuild complete. Vercel auto-deploys from root/build (vercel.json)." | tee /tmp/chore-build.log
