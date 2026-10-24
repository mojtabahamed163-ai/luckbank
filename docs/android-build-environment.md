# بيئة بناء Android

## التوصيات الرسمية

توصي وثائق Godot لتصدير Android بـJDK 17، وقالب التصدير المطابق لإصدار Godot، وAndroid SDK مع Platform-Tools 35.0.0 أو أحدث، وBuild-Tools 35.0.1، وAndroid Platform 35، وNDK r28b وCMake 3.10.2.4988404 في إعداد SDK الموصى به.[1] قوالب Godot 4.7.2 الرسمية متاحة في الأرشيف.[2]

## ما استُخدم في التصدير النهائي

بيئة البناء ARM64 وبها OpenJDK 21. ثُبّتت حزم Android المتاحة من Ubuntu، ومنها Build-Tools 29.0.3 وPlatform-Tools 28.0.2 ومنصة SDK 23. ثُبّت قالب Android الرسمي المطابق لـGodot 4.7.2 وضُبطت مسارات SDK وJava في إعدادات المحرر.

صدّر Godot APK بمعماريتي `arm64-v8a` و`armeabi-v7a` ووقّعه؛ تعذّر العثور على Build-Tools مطابقة لـTarget SDK 36، لذلك ظهر تحذير واستُخدمت 29.0.3 كبديل. اكتمل التصدير والتحقق من التوقيع. بيانات الحزمة: API الأدنى 24، وcompile/target SDK 36، واتجاه Manifest أفقي `landscape`، ولا يوجد إذن إنترنت.

لإعادة التصدير بعد إعداد Android SDK:

```bash
mkdir -p build
godot --headless --path . --export-debug Android build/luckbank-universal-debug.apk
```

هذه نسخة Debug وليست مفتاح إصدار متجر. لم يتصل هاتف Android أو محاكي بهذه البيئة، لذلك لا يوجد ادعاء باختبار APK على جهاز فعلي. لإزالة تحذير Build-Tools وإعادة بناء تتبع توصيات Godot، ثبّت Build-Tools 35.0.1 أو أحدث مع منصة Android SDK المناسبة.

## المراجع

[1]: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html "متطلبات Godot الرسمية لتصدير Android"
[2]: https://godotengine.org/download/archive/4.7.2-stable/ "إصدار Godot 4.7.2 وقوالب التصدير الرسمية"
[3]: https://developer.android.com/tools "أدوات Android SDK"
