চট্টগ্রাম ড্রাইভার বাজার — Flutter সোর্স প্রজেক্ট

এই সংস্করণে:
- ড্রাইভার/গাড়ির মালিক অ্যাকাউন্টের ধরন নির্বাচন
- Firebase Phone Authentication দিয়ে SMS OTP লগইন প্রবাহ
- ড্রাইভার CV/প্রোফাইল ফরম: ব্যক্তিগত তথ্য, ঠিকানা, শিক্ষা, লাইসেন্স, অভিজ্ঞতা, গাড়ির ধরন, বেতন, দক্ষতা
- ড্রাইভারের ছবি এবং PDF/DOC/DOCX CV আপলোডের কোড
- Firestore-এ ড্রাইভার/মালিক প্রোফাইল সংরক্ষণ
- মালিকের বদলি ডিউটি রিকোয়েস্ট পোস্ট করার ফরম
- ড্রাইভারদের তালিকা ও চাকরির বিজ্ঞাপন দেখানোর প্রাথমিক স্ক্রিন

গুরুত্বপূর্ণ সেটআপ:
1. Firebase Console-এ Android app যোগ করুন:
   package/application ID: com.chattogram.driverbazar
2. Firebase থেকে google-services.json ডাউনলোড করে android/app/ ফোল্ডারে রাখুন।
3. Firebase Authentication > Sign-in method থেকে Phone চালু করুন।
4. Cloud Firestore এবং Firebase Storage তৈরি করুন।
5. Firestore/Storage Security Rules নিরাপদভাবে সেট করুন। পরীক্ষার জন্যও production-এ test mode রেখে দেবেন না।
6. Flutter SDK ইনস্টল থাকা কম্পিউটারে প্রকল্প খুলে:
   flutter pub get
   flutter run
7. Android build করার আগে প্রয়োজন হলে Flutter-এর বর্তমান stable সংস্করণ অনুযায়ী Gradle/Android Gradle Plugin সামঞ্জস্য করুন।

সীমাবদ্ধতা/পরবর্তী কাজ:
- এই ZIP হলো Flutter সোর্স কোড; APK নয়।
- Firebase প্রকল্পের গোপন কনফিগারেশন এখানে নেই, কারণ সেটি আপনার নিজস্ব Firebase project থেকে নিতে হবে।
- SMS OTP, ছবি/CV আপলোড ও Firestore save চালাতে Firebase configuration এবং rules লাগবে।
- চাকরির বিজ্ঞাপন পোস্ট করার মালিক UI, বদলি রিকোয়েস্টে ড্রাইভারের আবেদন/মালিকের গ্রহণ-বাতিল, প্রোফাইল সম্পাদনা, রিপোর্ট/অ্যাডমিন প্যানেল, privacy controls এবং production security rules পরবর্তী উন্নয়নের বিষয়।
- ব্যক্তিগত তথ্য, লাইসেন্স ও CV সংবেদনশীল; Firestore/Storage-এ access control ছাড়া প্রকাশ করবেন না।
