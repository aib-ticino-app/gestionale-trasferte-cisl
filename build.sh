#!/bin/bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter
export PATH="$PATH:`pwd`/_flutter/bin"
flutter doctor
flutter pub get
flutter build web --release