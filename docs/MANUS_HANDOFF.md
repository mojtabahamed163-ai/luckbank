# دليل تسليم مشروع بنك الحظ

هذا المستودع هو مصدر اللعبة الكامل القابل للفحص والتعديل. المشروع مبني بـGodot **4.7.2**، والمشهد الرئيسي هو `scenes/main.tscn`، والواجهة في `scripts/main.gd`، ومنطق المباراة والاقتصاد في `scripts/game/bank_game.gd`.

## أهم المسارات

- `project.godot`: إعدادات Godot، المشهد الرئيسي، الاتجاه الأفقي، وخصائص العرض.
- `export_presets.cfg`: preset التصدير `Web` و`Android`.
- `scripts/main.gd`: إنشاء الواجهة، اللوحة، الخانات، الشاشات، التعريب والتفاعل.
- `scripts/game/bank_game.gd`: قواعد الحركة، اللفات، الاقتصاد، السجن، الإفلاس، الحفظ والنتائج.
- `localization/luckbank.json`: العربية والإنجليزية والإسبانية والفرنسية.
- `test/test_suite.gd`: اختبارات القواعد والاقتصاد.
- `test/ui_smoke.gd`: اختبار الواجهة واللوحة والخانات الأربعين.
- `docs/qa-device-compatibility.md`: نتائج فحص المقاسات الأفقية للهواتف.
- `docs/android-build-environment.md`: متطلبات وإرشادات بناء Android.
- `docs/artifacts/luckbank-universal-debug.apk`: آخر APK Debug محفوظ مع المصدر.

## الفحوص

```bash
source /home/ubuntu/.user_env
godot --headless --path . --scene res://test/test_suite.tscn
xvfb-run -a -s '-screen 0 1400x900x24' \
  godot --audio-driver Dummy --path . \
  --resolution 1280x720 --windowed \
  --script res://test/ui_smoke.gd
```

نتيجة آخر فحص موثقة: **1448/1448** لاختبارات القواعد والاقتصاد، واختبار الواجهة ناجح على 640×360 و854×480 و1280×720 و1920×1080.

## بناء Android

يجب تثبيت قالب تصدير Godot المطابق للإصدار 4.7.2، وJava، وAndroid SDK مع `platform-tools` و`platforms;android-35` و`build-tools;35.0.0`. بعد ضبط المسارات في Godot، استخدم:

```bash
mkdir -p build
godot --headless --path . \
  --export-debug Android build/luckbank-universal-debug.apk
```

الناتج Debug وموقّع للتثبيت اليدوي وليس مفتاح إصدار متجر. الـAPK المحفوظ في `docs/artifacts/` يدعم `armeabi-v7a` و`arm64-v8a`، ولا يطلب إذن الإنترنت، واتجاهه أفقي.

## ملاحظات العمل

- لا تعتمد على ملفات `.godot/` أو `build/` المحلية؛ هي ملفات توليدية ومُدرجة في `.gitignore`.
- لا توجد حاجة إلى خدمة شبكة أو قاعدة بيانات لتشغيل اللعبة؛ اللعبة تعمل دون اتصال.
- عند تعديل الواجهة، شغّل `ui_smoke.gd` على المقاسات الأربعة ثم شغّل `test_suite.tscn` قبل اعتماد التغيير.
- لم يتم الادعاء باختبار APK على جهاز Android فعلي؛ التقرير الحالي اختبار محاكاة نافذة عبر Godot/Xvfb.
