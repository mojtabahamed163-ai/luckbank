# تقرير التحقق — بنك الحظ 1.0.4

## APK Android

أُنتج `build/luckbank-universal-debug.apk` بقالب Godot الرسمي المطابق لـ4.7.2، وحجمه نحو 70 MB. معرّف الحزمة `org.manus.luckbank`، والاسم الظاهر «بنك الحظ»، ورقم الإصدار 1.0.4 (versionCode 5). يطلب Android API 24 كحد أدنى، ويضم معماريتي `arm64-v8a` و`armeabi-v7a`، ولا يطلب إذن الإنترنت. يثبت الـManifest الاتجاه الأفقي `landscape`، ويعرض compile/target SDK 36.

اجتاز APK فحص سلامة ZIP، وتحقق `apksigner` من توقيعي Android Signature Scheme v2 وv3. هذا ملف Debug موقّع بمفتاح تطوير Godot، وليس إصدار متجر بمفتاح توزيع. تعذر توفير Build-Tools المطابقة لـTarget SDK 36، فأصدر Godot تحذيرًا واستعمل Build-Tools 29.0.3 كبديل؛ رغم ذلك اكتمل التصدير والتوقيع.

لم يتصل هاتف Android أو محاكي بهذه البيئة. لا أستطيع اعتبار فحص ZIP وManifest بديلًا عن تجربة التثبيت واللمس والأداء على الهاتف الحقيقي.

## تقدير Infinix SMART 7 HD

تذكر المواصفات المنشورة للطراز X6516 نظام Android 12 Go، ومعالج SC9863A1، ووحدة PowerVR GE8322 وذاكرة 2 GB.[4] [5] يطلب APK API 24 على الأقل ويدعم ARM64 وARMv7، ويستخدم المشروع مسار Compatibility/`gl_compatibility`. توضح وثائق Godot أن مسار Compatibility على Android يحتاج OpenGL ES 3.0 على الأقل، وأن Android 7 هو الحد الأدنى للنظام.[6] يسجل UL للهاتف اختبار OpenGL ES 3.1.[7]

بناءً على هذه المواصفات **يُتوقع أن يثبت ويعمل على الهاتف**، لكن ذاكرة 2 GB محدودة نسبيًا ولم أجرّب الملف عليه مباشرة؛ لذلك لا أضمن الأداء أو خلوه من اختلافات تعريفات الجهاز.

## الواجهة والصور

اختُبرت الواجهة الفعلية على نافذة X11 أفقية 1280×720. تحقّق اختبار دخان الواجهة من مباراة محلية رباعية، ومن وجود 40 خانة فريدة على المحيط وخلوّ المساحة الوسطى منها، وبناء ثماني صفحات باللغات العربية والإنجليزية والإسبانية والفرنسية. والتُقطت صور من تشغيل فعلي: شاشة البداية والإعداد واللوحة، ثم رمية نرد (6) والهبوط في نيجيريا وعرض قرار الشراء وإتمامه. هذه صور معاينة على Linux/X11، وليست لقطات من الهاتف.

## نتائج اللعبة والاختبارات

اجتازت اختبارات النموذج **1257/1257**، بما فيها ترتيب اللوحة وقيم 30 دولة، ميزات الدول، توسعات السودان، الأحداث، درجات الكمبيوتر، الحفظ، التسوية، والصفقات ومحاكاة مباراة حتى نهايتها. يضم كل قاموس لغة 253 مفتاح واجهة و40 اسم خانة و40 اسم حدث و40 رمز خانة.

خيارات المدة تنفذ حدود 8/16/24 جولة؛ زمن اللعب الفعلي بالدقائق لم يُقَس على هاتف. بطاقات الاقتصاد آثارها تلقائية ومشروطة، ولا تتضمن هذه النسخة بطاقة قرار تفاعلي.

## إعادة الاختبارات

```bash
godot --headless --path . --scene res://test/test_suite.tscn
xvfb-run -a -s '-screen 0 1400x900x24' \
  godot --path . --windowed --resolution 1280x720 \
  --script res://test/ui_smoke.gd
```

## المراجع

[1]: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html "متطلبات Godot لتصدير Android"
[2]: https://godotengine.org/download/archive/4.7.2-stable/ "قوالب Godot الرسمية 4.7.2"
[3]: https://developer.android.com/tools "أدوات Android SDK"
[4]: https://www.gsmarena.com/infinix_smart_7_hd-12243.php "مواصفات Infinix Smart 7 HD"
[5]: https://wap.sn.infinixmobility.com/specs/smart-7-hd "صفحة Infinix الرسمية"
[6]: https://docs.godotengine.org/en/stable/about/system_requirements.html "متطلبات النظام لـGodot"
[7]: https://benchmarks.ul.com/hardware/phone/Infinix+Smart+7+HD+review "نتيجة اختبار UL للهاتف"
[8]: https://docs.godotengine.org/en/4.7/classes/class_displayserver.html "قيم اتجاه الشاشة في Godot 4.7"
