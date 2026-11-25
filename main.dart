import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    // Missing Firebase configuration is explained on the welcome screen.
  }
  runApp(DriverBazarApp(firebaseReady: firebaseReady));
}

class DriverBazarApp extends StatelessWidget {
  const DriverBazarApp({super.key, required this.firebaseReady});
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'চট্টগ্রাম ড্রাইভার বাজার',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F5B)),
      scaffoldBackgroundColor: const Color(0xFFF6F8F7),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: WelcomePage(firebaseReady: firebaseReady),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.firebaseReady});
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.directions_car_filled, size: 76, color: Color(0xFF087F5B)),
        const SizedBox(height: 16),
        const Text('চট্টগ্রাম ড্রাইভার বাজার',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('ড্রাইভার ও গাড়ির মালিকদের সংযোগের নির্ভরযোগ্য প্ল্যাটফর্ম',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(
          firebaseReady
            ? 'Firebase সংযোগ প্রস্তুত'
            : 'Firebase সেটআপ বাকি। README_BN.txt অনুসরণ করে google-services.json যোগ করুন।',
          textAlign: TextAlign.center,
          style: TextStyle(color: firebaseReady ? Colors.green.shade700 : Colors.deepOrange),
        ))),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountTypePage())),
          child: const Padding(padding: EdgeInsets.all(14), child: Text('শুরু করুন', style: TextStyle(fontSize: 18))),
        )),
      ]),
    ))),
  );
}

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('অ্যাকাউন্ট নির্বাচন')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('আপনি কোন ধরনের অ্যাকাউন্ট খুলবেন?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLoginPage(role: 'driver'))),
          icon: const Icon(Icons.person), label: const Padding(padding: EdgeInsets.all(14), child: Text('আমি ড্রাইভার'))),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLoginPage(role: 'owner'))),
          icon: const Icon(Icons.directions_car), label: const Padding(padding: EdgeInsets.all(14), child: Text('আমি গাড়ির মালিক'))),
      ],
    )),
  );
}

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key, required this.role});
  final String role;
  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  String? verificationId;
  bool sending = false;
  bool codeSent = false;

  @override
  void dispose() { phone.dispose(); otp.dispose(); super.dispose(); }

  Future<void> sendCode() async {
    if (phone.text.trim().length < 10) {
      showMsg(context, 'সঠিক মোবাইল নম্বর লিখুন');
      return;
    }
    setState(() => sending = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone.text.trim().startsWith('+')
          ? phone.text.trim()
          : '+88${phone.text.trim()}',
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) goNext();
        },
        verificationFailed: (e) => showMsg(context, 'OTP পাঠানো যায়নি: ${e.message ?? e.code}'),
        codeSent: (id, _) {
          if (!mounted) return;
          setState(() { verificationId = id; codeSent = true; });
          showMsg(context, 'OTP পাঠানো হয়েছে');
        },
        codeAutoRetrievalTimeout: (id) => verificationId = id,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      showMsg(context, 'Firebase সংযোগ/নম্বর পরীক্ষা করুন: $e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> verify() async {
    if (verificationId == null) return;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!, smsCode: otp.text.trim());
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) goNext();
    } catch (_) {
      showMsg(context, 'OTP সঠিক নয় অথবা মেয়াদ শেষ হয়েছে');
    }
  }

  void goNext() {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => widget.role == 'driver'
        ? const DriverRegistrationPage()
        : const OwnerRegistrationPage()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('মোবাইল যাচাই')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('আপনার মোবাইল নম্বর দিয়ে অ্যাকাউন্ট খুলুন', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      TextField(controller: phone, keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'মোবাইল নম্বর', hintText: '01XXXXXXXXX')),
      if (codeSent) ...[
        const SizedBox(height: 14),
        TextField(controller: otp, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'SMS-এ পাওয়া OTP')),
      ],
      const SizedBox(height: 18),
      FilledButton(
        onPressed: sending ? null : (codeSent ? verify : sendCode),
        child: Padding(padding: const EdgeInsets.all(13), child: Text(
          sending ? 'অপেক্ষা করুন...' : (codeSent ? 'OTP যাচাই করুন' : 'OTP পাঠান'))),
      ),
      const SizedBox(height: 10),
      const Text('নোট: আসল SMS OTP চালাতে Firebase Phone Authentication চালু ও Android app configure করতে হবে.',
        style: TextStyle(color: Colors.black54)),
    ]),
  );
}

class DriverRegistrationPage extends StatefulWidget {
  const DriverRegistrationPage({super.key});
  @override
  State<DriverRegistrationPage> createState() => _DriverRegistrationPageState();
}

class _DriverRegistrationPageState extends State<DriverRegistrationPage> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{
    for (final key in [
      'পূর্ণ নাম', 'পিতার নাম', 'মোবাইল নম্বর', 'জন্মতারিখ', 'বর্তমান ঠিকানা',
      'স্থায়ী ঠিকানা', 'শিক্ষাগত যোগ্যতা', 'লাইসেন্স নম্বর', 'লাইসেন্সের মেয়াদ',
      'ড্রাইভিং অভিজ্ঞতা (বছর)', 'যে গাড়ি চালাতে পারেন', 'পূর্বের চাকরির অভিজ্ঞতা',
      'প্রত্যাশিত বেতন', 'অতিরিক্ত দক্ষতা'
    ]) key: TextEditingController()
  };
  String licenseType = 'পেশাদার';
  File? photo;
  PlatformFile? cv;
  bool saving = false;

  @override
  void dispose() { for (final c in fields.values) { c.dispose(); } super.dispose(); }

  Future<void> pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => photo = File(x.path));
  }

  Future<void> pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'], withData: false);
    if (result != null) setState(() => cv = result.files.single);
  }

  Future<String?> uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (FirebaseAuth.instance.currentUser == null) {
      showMsg(context, 'আগে মোবাইল নম্বর যাচাই করুন'); return;
    }
    setState(() => saving = true);
    try {
      String? photoUrl;
      String? cvUrl;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (photo != null) photoUrl = await uploadFile(photo!, 'driver_profiles/$uid/photo.jpg');
      if (cv?.path != null) {
        final f = File(cv!.path!);
        final ref = FirebaseStorage.instance.ref('driver_profiles/$uid/cv_${cv!.name}');
        await ref.putFile(f);
        cvUrl = await ref.getDownloadURL();
      }
      final data = <String, dynamic>{
        for (final entry in fields.entries) entry.key: entry.value.text.trim(),
        'licenseType': licenseType,
        'photoUrl': photoUrl,
        'cvUrl': cvUrl,
        'cvFileName': cv?.name,
        'role': 'driver',
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('users').doc(uid).set(data, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DriverHomePage()), (_) => false);
    } catch (e) {
      showMsg(context, 'তথ্য সংরক্ষণ হয়নি: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget field(String label, {int lines = 1, TextInputType? type, bool required = true}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(
      controller: fields[label], maxLines: lines, keyboardType: type,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'এই তথ্যটি দিন' : null : null,
      decoration: InputDecoration(labelText: label, alignLabelWithHint: lines > 1),
    ));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ড্রাইভার CV ও রেজিস্ট্রেশন')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('ব্যক্তিগত তথ্য', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Center(child: Column(children: [
        CircleAvatar(radius: 42, backgroundImage: photo != null ? FileImage(photo!) : null,
          child: photo == null ? const Icon(Icons.person, size: 42) : null),
        TextButton.icon(onPressed: pickPhoto, icon: const Icon(Icons.photo), label: const Text('নিজের ছবি দিন')),
      ])),
      field('পূর্ণ নাম'), field('পিতার নাম'), field('মোবাইল নম্বর', type: TextInputType.phone),
      field('জন্মতারিখ', required: false), field('বর্তমান ঠিকানা', lines: 2),
      field('স্থায়ী ঠিকানা', lines: 2),
      const SizedBox(height: 8),
      const Text('শিক্ষা ও ড্রাইভিং তথ্য', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      field('শিক্ষাগত যোগ্যতা'),
      DropdownButtonFormField<String>(
        value: licenseType,
        decoration: const InputDecoration(labelText: 'লাইসেন্সের ধরন'),
        items: const ['পেশাদার', 'অপেশাদার', 'শিক্ষানবিশ'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => licenseType = v ?? licenseType)),
      const SizedBox(height: 12),
      field('লাইসেন্স নম্বর'), field('লাইসেন্সের মেয়াদ', required: false),
      field('ড্রাইভিং অভিজ্ঞতা (বছর)', type: TextInputType.number),
      field('যে গাড়ি চালাতে পারেন', lines: 2),
      field('পূর্বের চাকরির অভিজ্ঞতা', lines: 3, required: false),
      field('প্রত্যাশিত বেতন', type: TextInputType.number, required: false),
      field('অতিরিক্ত দক্ষতা', lines: 2, required: false),
      const SizedBox(height: 4),
      OutlinedButton.icon(onPressed: pickCv, icon: const Icon(Icons.upload_file),
        label: Text(cv == null ? 'CV PDF / DOC / DOCX আপলোড করুন' : cv!.name)),
      const SizedBox(height: 8),
      const Text('ছবি ও CV ঐচ্ছিক; তবে ভালো প্রোফাইলের জন্য যোগ করা পরামর্শযোগ্য।',
        style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 18),
      FilledButton(onPressed: saving ? null : save,
        child: Padding(padding: const EdgeInsets.all(14), child: Text(saving ? 'সংরক্ষণ হচ্ছে...' : 'রেজিস্ট্রেশন সম্পন্ন করুন'))),
    ])),
  );
}

class OwnerRegistrationPage extends StatefulWidget {
  const OwnerRegistrationPage({super.key});
  @override
  State<OwnerRegistrationPage> createState() => _OwnerRegistrationPageState();
}

class _OwnerRegistrationPageState extends State<OwnerRegistrationPage> {
  final name = TextEditingController(), phone = TextEditingController(), address = TextEditingController();
  bool saving = false;
  @override
  void dispose() { name.dispose(); phone.dispose(); address.dispose(); super.dispose(); }

  Future<void> save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { showMsg(context, 'আগে মোবাইল নম্বর যাচাই করুন'); return; }
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty || address.text.trim().isEmpty) {
      showMsg(context, 'সব তথ্য পূরণ করুন'); return;
    }
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name.text.trim(), 'phone': phone.text.trim(), 'address': address.text.trim(),
        'role': 'owner', 'uid': user.uid, 'createdAt': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));
      if (mounted) Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const OwnerHomePage()), (_) => false);
    } catch (e) { showMsg(context, 'সংরক্ষণ হয়নি: $e'); }
    finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('গাড়ির মালিক রেজিস্ট্রেশন')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'নাম')),
      const SizedBox(height: 12),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'মোবাইল নম্বর')),
      const SizedBox(height: 12),
      TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'ঠিকানা')),
      const SizedBox(height: 18),
      FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'সংরক্ষণ হচ্ছে...' : 'রেজিস্ট্রেশন সম্পন্ন করুন')),
    ]),
  );
}

class DriverHomePage extends StatelessWidget {
  const DriverHomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ড্রাইভার ড্যাশবোর্ড'), actions: [
      IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))
    ]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('চাকরির বিজ্ঞাপন', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('নতুন চাকরির বিজ্ঞাপন এখানে দেখা যাবে।'),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('jobs').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Text('চাকরির তথ্য লোড করা যায়নি');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('এখনো কোনো চাকরির বিজ্ঞাপন নেই'));
          return Column(children: snap.data!.docs.map((d) => JobCard(data: d.data())).toList());
        }),
    ]),
  );
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    title: Text(data['title'] ?? 'ড্রাইভারের চাকরি'),
    subtitle: Text('${data['location'] ?? ''}\nবেতন: ${data['salary'] ?? 'আলোচনা সাপেক্ষে'}'),
    isThreeLine: true,
  ));
}

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('গাড়ির মালিক ড্যাশবোর্ড'), actions: [
      IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))
    ]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('আপনার প্রয়োজনীয় সেবা', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubstituteDutyPage())),
        icon: const Icon(Icons.swap_horiz), label: const Padding(padding: EdgeInsets.all(14), child: Text('বদলি ডিউটি রিকোয়েস্ট দিন'))),
      const SizedBox(height: 16),
      const Text('ড্রাইভার খোঁজা', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Text('ড্রাইভারের তালিকা লোড করা যায়নি');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Text('এখনো কোনো ড্রাইভার রেজিস্ট্রেশন করেননি');
          return Column(children: snap.data!.docs.map((d) {
            final x = d.data();
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(x['পূর্ণ নাম'] ?? 'ড্রাইভার'),
              subtitle: Text('অভিজ্ঞতা: ${x['ড্রাইভিং অভিজ্ঞতা (বছর)'] ?? '-'} বছর • ${x['যে গাড়ি চালাতে পারেন'] ?? ''}'),
            ));
          }).toList());
        }),
    ]),
  );
}

class SubstituteDutyPage extends StatefulWidget {
  const SubstituteDutyPage({super.key});
  @override
  State<SubstituteDutyPage> createState() => _SubstituteDutyPageState();
}

class _SubstituteDutyPageState extends State<SubstituteDutyPage> {
  final keyForm = GlobalKey<FormState>();
  final title = TextEditingController(text: 'বদলি ড্রাইভার প্রয়োজন');
  final vehicle = TextEditingController(), location = TextEditingController(),
    date = TextEditingController(), time = TextEditingController(), pay = TextEditingController(), details = TextEditingController();
  bool saving = false;
  @override
  void dispose() { for (final c in [title, vehicle, location, date, time, pay, details]) { c.dispose(); } super.dispose(); }

  Future<void> save() async {
    if (!keyForm.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { showMsg(context, 'আগে লগইন করুন'); return; }
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('substitute_duty_requests').add({
        'title': title.text.trim(), 'vehicle': vehicle.text.trim(),
        'location': location.text.trim(), 'date': date.text.trim(),
        'time': time.text.trim(), 'pay': pay.text.trim(), 'details': details.text.trim(),
        'ownerUid': user.uid, 'status': 'open', 'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) { showMsg(context, 'বদলি ডিউটি রিকোয়েস্ট প্রকাশ হয়েছে'); Navigator.pop(context); }
    } catch (e) { showMsg(context, 'রিকোয়েস্ট প্রকাশ হয়নি: $e'); }
    finally { if (mounted) setState(() => saving = false); }
  }

  Widget f(TextEditingController c, String label, {bool required = true, int lines = 1}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(
      controller: c, maxLines: lines,
      validator: required ? (v) => v == null || v.trim().isEmpty ? 'এই তথ্যটি দিন' : null : null,
      decoration: InputDecoration(labelText: label)));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('বদলি ডিউটি রিকোয়েস্ট')),
    body: Form(key: keyForm, child: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('শুধু গাড়ির মালিক এই রিকোয়েস্ট দিতে পারবেন।', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 14),
      f(title, 'রিকোয়েস্টের শিরোনাম'),
      f(vehicle, 'গাড়ির ধরন / মডেল'),
      f(location, 'কর্মস্থল / এলাকা'),
      f(date, 'ডিউটির তারিখ (যেমন: ২৫-১২-২০২৬)'),
      f(time, 'ডিউটির সময়'),
      f(pay, 'পারিশ্রমিক / বেতন'),
      f(details, 'কাজের বিস্তারিত', required: false, lines: 3),
      FilledButton(onPressed: saving ? null : save,
        child: Padding(padding: const EdgeInsets.all(14), child: Text(saving ? 'প্রকাশ হচ্ছে...' : 'রিকোয়েস্ট প্রকাশ করুন'))),
    ])),
  );
}

void showMsg(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
