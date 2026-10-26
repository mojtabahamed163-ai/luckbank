# بيئة بناء Android

## التوصيات الرسمية

توصي وثائق Godot لتصدير Android بقالب التصدير المطابق لإصدار Godot، وJava، وAndroid SDK مع أدوات المنصة والبناء المناسبة. يستخدم هذا المستودع Godot 4.7.2 وقالب Android الرسمي المطابق له، مع Android Platform 35 وPlatform-Tools وBuild-Tools 35.0.0.[1][2]

## ما استُخدم في التصدير النهائي

بيئة البناء الحالية تستخدم OpenJDK 21، وAndroid SDK في `/home/ubuntu/android-sdk`، وPlatform-Tools، وAndroid Platform 35، وBuild-Tools 35.0.0، مع قالب Android الرسمي المطابق لـGodot 4.7.2. ضُبطت مسارات SDK وJava في إعدادات المحرر العامة، ولا توجد هذه المسارات داخل المستودع.

صدّر Godot APK بمعماريتي `arm64-v8a` و`armeabi-v7a` ووقّعه بتوقيع Debug. اكتمل فحص بنية APK والتحقق من توقيعي V2 وV3. بيانات الحزمة: API الأدنى 24، واتجاه Manifest أفقي `landscape`، ولا يوجد إذن إنترنت. النسخة المحفوظة داخل المستودع هي `docs/artifacts/luckbank-universal-debug.apk` وحجمها نحو 70 MB.

لإعادة التصدير بعد إعداد Android SDK:

```bash
mkdir -p build
godot --headless --path . --export-debug Android build/luckbank-universal-debug.apk
```

هذه نسخة Debug وليست مفتاح إصدار متجر. لم يتصل هاتف Android أو محاكي بهذه البيئة، لذلك لا يوجد ادعاء باختبار APK على جهاز فعلي. بعد تثبيت المتطلبات وضبط Godot، يعاد التصدير بالأمر السابق، ثم يمكن التحقق من التوقيع بواسطة `apksigner verify --verbose`.

## المراجع

[1]: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html "متطلبات Godot الرسمية لتصدير Android"
[2]: https://godotengine.org/download/archive/4.7.2-stable/ "إصدار Godot 4.7.2 وقوالب التصدير الرسمية"
[3]: https://developer.android.com/tools "أدوات Android SDK"
