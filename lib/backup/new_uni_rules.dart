// uni_rules.dart
// uni_rules.dart
// uni_rules.dart
import 'package:flutter/material.dart';
import 'my_drawer.dart';
import 'new_student_enrollment_app.dart';
import 'package:miit_project/components/text.dart';
import 'package:easy_localization/easy_localization.dart';


// ✅ University Rules
const String universityRules = '''
၁။ \t  ကျောင်းခေါ်ချိန်ကို တွက်ချက်ရာတွင် ဘာသာရပ်တစ်ခုချင်းစီအလိုက် တွက်ချက်သွားမည် ဖြစ်သည်။ ဘာသာရပ်တစ်ခုတွင် ကျောင်းခေါ်ချိန် (၇၅%)ရာခိုင်နှုန်း မပြည့်မီလျှင် အဆိုပါ ဘာသာရပ်အား 
    \t    စာမေးပွဲဖြေဆိုခြင်း လုံးဝ ခွင့်မပြု။
၂။  \t ဘာသာရပ်တစ်ခုတွင် ကျောင်းခေါ်ချိန် (၇၅%) မပြည့်မီသဖြင့် စာမေးပွဲဖြေဆိုခွင့် မရရှိပါက အဆိုပါပညာသင်နှစ်အတွက် အဆိုပါဘာသာရပ်ကို စာမေးပွဲတစ်ကြိမ်ကျအဖြစ် သတ်မှတ်ခြင်း ခံရမည်။
၃။  \t စာမေးပွဲတွင် မသမာသောနည်းလမ်းဖြင့် စာမေးပွဲဖြေဆိုခြင်း သိရှိပါက ကျောင်းမှသတ်မှတ်ထားသော စည်းကမ်းချက်များအတိုင်း အရေးယူခံရမည်။
၄။  \t ကျောင်းလခများကို သတ်မှတ်ကာလအတွင်း ပေးသွင်းရမည်ဖြစ်ပြီး ကျောင်းလခ၊ စာကြည့်တိုက်နှင့် စက်ပစ္စည်းကြွေးကျန်များရှိနေပါက စာမေးပွဲရလာဒ်များ (Transcript, Grade Sheet) ကို ထိန်းသိမ်းမည်။
၅။  \t ကျောင်းသား/ကျောင်းသူများသည် ကျောင်းချိန်အတွင်း ကျောင်းက သတ်မှတ်ထားသော တူညီဝတ်စုံကိုသာ ဝတ်ဆင်ရမည်။
၆။  \t ကျောင်းဝင်းအတွင်း မိမိတို့သက်ဆိုင်ရာ ကျောင်းသား ကဒ်ပြားများအား ချိတ်ဆွဲထားရမည်။
၇။  \t စာသင်ချိန်အတွင်း Mobile Phone, Earphone များ အသုံးမပြုရန်နှင့် သင်ကြားရေးအတွက် အသုံးပြုရန်လိုအပ်ပါက တာဝန်ကျဆရာ/ဆရာမများ၏ ခွင့်ပြုချက်ဖြင့်သာအသုံးပြုရမည်။ စာသင်ချိန်အတွင်း 
    \t    တာဝန်ကျ ဆရာ၊ ဆရာမများအား လေးစားမှုရှိရမည်။
၈။  \t ကျောင်းပရဝဏ်အတွင်း ဖြစ်စေ၊ ပြင်ပတွင် ဖြစ်စေ၊ ရာဇဝတ်မှုနှင့် မလွတ်ကင်းသော လှုပ်ရှားမှုများနှင့် မည်သည့်လောင်းကစားခြင်းကိုမျှမပြုလုပ်ရ၊ အမျိုးသမီးများကို အနုတ်ကျစေမည့်နှောက်ယှက်မှုမျိုးကို 
    \t    မပြုလုပ်ရ။
၉။  \t ကျောင်းသား၊ ကျောင်းသူ ချစ်သူစုံတွဲများသည် ကျောင်းပရိဝုဏ်နှင့် စာသင်ခန်း အတွင်း၊ အပြင် အစရှိသည့် နေရာများတွင် မြန်မာ့ယဉ်ကျေးမှုနှင့် မလျော်ညီသော အပြုအမူများပြုမိပါက တက္ကသိုလ်၏ 
    \t    စည်းမျဉ်း စည်းကမ်းများအရ အရေးယူခြင်းခံရမည်။
၁၀။ \t ကျောင်းသား/ကျောင်းသူများသည် ဆေးလိပ်သောက်ခြင်း၊ မူးယစ်ဆေးဝါး၊ အရက်၊ ဘီယာ၊ E-Cigarettes မသုံးစွဲရ။
၁၁။ \t ကျောင်းနံရံများ၊ ကြော်ငြာများတွင် ခွင့်ပြုချက်မရှိဘဲ စာရွက်စာတမ်း ကပ်ခြင်း၊ ရေးခြစ်ခြင်း မပြုလုပ်ရ။
၁၂။  \t ကျောင်းပိုင်ပစ္စည်းများနှင့် သင်ထောက်ကူပစ္စည်းများ ခွင့်ပြုချက်မရှိဘဲ အသုံးမပြုရ။
၁၃။ \t ကျောင်းအဆောက်အဦး၊ ပစ္စည်းများ ဖျက်ဆီးခြင်း မပြုရ။
၁၄။ \t ကျောင်းမှ ထုတ်ပြန်သော စည်းကမ်းချက်များကို လိုက်နာမရှိပါက အရေးယူခံရမည်။
''';

const String universityOneRules = '''
တက္ကသိုလ်စာမေးပွဲများတွင် အောက်ပါမသမာသောနည်းလမ်းများကို အသုံးပြုရန်ကြိုးစားအား ထုတ်ခြင်းနှင့် ကျူးလွန်ခြင်းများတွေ့ရှိပါက စာမေးပွဲစည်းကမ်းအရ အရေးယူခြင်းခံရမည်ဖြစ်သည် - \n
(၁) \t စာမေးပွဲ မဖြေမီ မသမာမှုပြုရန် ရည်ရွယ်၍ ကြိုတင်ကြံစည်ခြင်း (စာမေးပွဲခန်းသို့ မဝင်မီ စာမေးပွဲခန်းကြီးကြပ်ရေးမှူးများမှ စစ်ဆေးစဉ် တွေ့ရှိပါက)-
         ပြင်းထန်စွာ သတိပေး၍ ဝန်ခံကတိ ရေးထိုးစေခြင်း
(၂) \t စစ်ဆေးသည့် ဘာသာရပ်ကို မသမာသောနည်းဖြင့် ဖြေဆိုရန် မှတ်စု၊ စာရွက်၊ စာတမ်း၊ စာအုပ်နှင့် အခြားအထောက်အကူပြု ပစ္စည်းများအား စာမေးပွဲခန်းအတွင်းသို့ ယူဆောင် လာခြင်း၊ 
    \t   စာမေးပွဲအခန်းအတွင်း၌ စာဖြေသူ၏ ခန္ဓာကိုယ် တစ်နေရာရာတွင် ရေးမှတ်လာသည်ကို တွေ့ရှိရခြင်း-
      \t ကျူးလွန်သည့်ပြစ်မှုကို စိစစ်၍ ပြစ်မှုအလိုက် ပြင်းထန်စွာသတိပေးခြင်းအဆင့်မှ စာမေးပွဲ ဖြေဆိုခွင့်ရပ်စဲ၍ လက်ရှိပညာသင်နှစ်အား ကျရှုံး သတ်မှတ်သည့်အဆင့်အထိပြစ်မှုအလိုက် ပြစ်ဒဏ်သတ်မှတ်ရန်
(၃) \t စာမေးပွဲအခန်း အတွင်း၌ဖြစ်စေ၊ အနှောင့်အယှက်ပြုခြင်း-အပြင်၌ဖြစ်စေ၊ စာမေးပွဲဖြေဆိုခြင်းအား
     \t  ကျူးလွန်သည့်ပြစ်မှုကို စိစစ်၍ ပြစ်မှုအလိုက် ပြင်းထန်စွာသတိပေးခြင်းအဆင့်မှ စာမေးပွဲ ဖြေဆိုခွင့်ရပ်စဲ၍ လက်ရှိပညာသင်နှစ်အား ကျရှုံး သတ်မှတ်သည့်အဆင့်အထိပြစ်မှုအလိုက် ပြစ်ဒဏ်သတ်မှတ်ရန်
(၄) \t စာမေးပွဲဖြေဆိုပြီး အဖြေလွှာကို သက်ဆိုင်ရာကြီးကြပ်ရေးမှူးထံ မအပ်နှံပဲ စာမေးပွဲခန်း ပြင်ပသို့ ယူဆောင်သွားခြင်း-
     \t  စာမေးပွဲဖြေဆိုခွင့်ရပ်စဲ၍ စာမေးပွဲဖြေဆိုသည့် ပညာသင်နှစ်(၁)နှစ် ကျရှုံး သတ်မှတ်ရန်
(၅) \t စာမေးပွဲခန်းတွင် ခိုးချခြင်း၊ ခိုးချရန်ကြိုးစားခြင်း စသည့် မသမာသော နည်းလမ်းဖြင့် ဖြေဆိုကြောင်း စာမေးပွဲကြီးကြပ်ရေးအဖွဲ့မှ အထောက်အထား ခိုင်လုံစွာ တွေ့ရှိရခြင်း
    \t   စာမေးပွဲဖြေဆိုခွင့်ရပ်စဲ၍ စာမေးပွဲဖြေသည့် ပညာသင်နှစ်အား ကျရှုံး သတ်မှတ်ပြီး နောက်ထပ် ဆက်တိုက် ပညာသင်နှစ်(၁)နှစ်ကို ပညာသင်ခွင့် ရပ်ဆိုင်းရန်
(၆) \t ကျောင်းသားတစ်ဦးသည် စာမေးပွဲအခန်း အတွင်း၌ဖြစ်စေ၊ အပြင်၌ဖြစ်စေ၊ ကြီးကြပ်သူ ဆရာ/ဆရာမများအား ရိုင်းပြစွာ ပြောဆိုဆက်ဆံခြင်း၊ ခြိမ်းခြောက်ခြင်း၊ နှောက်ယှက်ခြင်း
     \t  စာမေးပွဲဖြေဆိုခွင့်ရပ်စဲ၍ စာမေးပွဲဖြေသည့် ပညာသင်နှစ်အား ကျရှုံး သတ်မှတ်ပြီး နောက်ထပ် ဆက်တိုက် ပညာသင်နှစ်(၁)နှစ်ကို ပညာသင်ခွင့် ရပ်ဆိုင်းရန်**
(၇) \t ကျောင်းသားတစ်ဦးသည် မိမိဖြေဆိုပြီးသော အဖြေလွှာစာရွက် (သို့မဟုတ်) အဖြေ ရေးသားနိုင်သည့် မေးခွန်းစာရွက်ကဲ့သို့သော တစ်စုံတစ်ရာကို အခြားကျောင်းသား တစ်ဦးအားပေး၍
    \t   ကူးယူစေခြင်းနှင့် အခြားနည်းဖြင့် ကူညီခြင်း
    \t   စာမေးပွဲဖြေဆိုခွင့်ရပ်စဲ၍ စာမေးပွဲဖြေသည့် ပညာသင်နှစ်အား ကျရှုံး သတ်မှတ်ပြီး နောက်ထပ် ဆက်တိုက် ပညာသင်နှစ်(၁)နှစ်ကို ပညာသင်ခွင့် ရပ်ဆိုင်းရန် (ကူညီသူနှင့် အကူအညီလက်ခံသူအား တူညီစွာ အရေးယူရန်)
(၈) \t ကျောင်းသားတစ်ဦးသည် အသင့်ဖြေဆိုထားသော စာရွက်များကို အစားထိုး လဲလှယ် ကြားညှပ်၍ လည်းကောင်း၊ အသင့်ဖြေဆိုထားသော အဖြေလွှာစာအုပ်ချင်း လဲလှယ်၍ လည်းကောင်း၊ 
    \t   မသမာသောနည်းဖြင့် စာမေးပွဲဖြေဆိုခြင်း
    \t   စာမေးပွဲဖြေဆိုခွင့်ရပ်စဲ၍ စာမေးပွဲဖြေသည့် ပညာသင်နှစ်အား ကျရှုံး သတ်မှတ်ပြီး နောက်ထပ် ဆက်တိုက် ပညာသင်နှစ်(၂)နှစ်ကို ပညာသင်ခွင့် ရပ်ဆိုင်းရန်
(၉) \t ကျောင်းသားတစ်ဦးသည် စာမေးပွဲဖြေဆိုပြီးသွားသော အခြားကျောင်းသားတစ်ဦး၏ အဖြေလွှာကို မိမိအဖြေလွှာနှင့် လဲယူပြီး ထိုလဲယူထားသော အဖြေလွှာပေါ်တွင် မိမ၏ ခုံအမှတ်ကို
    \t   ပြင်ဆင်ရေးသားထားကြောင်း တွေ့ရှိရခြင်း
    \t   စာမေးပွဲဖြေသည့် ပညာသင်နှစ်အား ကျရှုံး သတ်မှတ်ပြီး နောက်ထပ် ဆက်တိုက် ပညာသင်နှစ်(၂)နှစ်ကို ပညာသင်ခွင့် ရပ်ဆိုင်းရန်(လဲယူနိုင်ရန် အခြားကျောင်းသား၏ အကူအညီ ပါရှိ/မရှိစိစစ်၍ 
    \t   ပါရှိက ၎င်း ကျောင်းသားကိုပါတူညီစွာအရေးယူဆောင်ရွက်ရန်
(၁၀)\t စာမေးပွဲတွင် လူစားထိုးဝင်ရောက်ဖြေဆိုကြောင်း စစ်ဆေးတွေ့ရှိရခြင်း
    \t     စာမေးပွဲဖြေဆိုခွင့် ရပ်စဲ၍ စာမေးပွဲဖြေသည့် ပညာသင်နှစ်အား ကျရှုံး သတ်မှတ်ပြီး နောက်ထပ် ဆက်တိုက် ပညာသင်နှစ်(၂)နှစ်ကို ပညာသင်ခွင့် ရပ်ဆိုင်းရန် (သက်ဆိုင်ရာ ကျောင်းသား/သူနှင့် 
    \t     လူစားဝင်ရောက်ဖြေဆိုပေးသူသည် မိမိတက္ကသိုလ်မှဖြစ်ပါကတူညီစွာအရေးယူရန်၊ အခြားဝန်ကြီးဌာနအောက်ရှိ ကျောင်းတစ်ခုခုမှဖြစ်ပါက သက်ဆိုင်ရာ ပါမောက္ခချုပ်/ကျောင်းအုပ်ကြီးများထံသို့
    \t     အကြောင်းကြားစာ ပေးပို့ရန်၊ ဝန်ထမ်းဖြစ်ပါက သက်ဆိုင်ရာ အကြီးအကဲထံသို့လည်းကောင်း ပြင်ပပုဂ္ဂိုလ်ဖြစ်ပါက သက်ဆိုင်ရာ မြို့နယ်အထွေထွေ အုပ်ချုပ်ရေးဦးစီးဌာနသို့ လည်းကောင်း အကြောင်းကြားစာ ပေးပို့ရန်
(၁၁)\t စာမေးပွဲ မဖြေဆိုမီ ကြိုတင်ဝင်ရောက် နှောင့်ယှက်ခြင်း
     \t   ကျူးလွန်သည့် ပြစ်မှုစိစစ်၍ ပြင်းထန်စွာ သတိပေးခြင်းပြုလုပ်ရန် (သို့မဟုတ်) လက်ရှိပညာသင်နှစ်(၁)နှစ် ရပ်နားသတ်မှတ်ရန်
  ''';

const String universityTwoRules = '''
၁။  \t	မူးယစ်ထုံထိုင်းစေတတ်သော ဆေးဝါးများကို သုံးစွဲခြင်း၊ ထားသိုခြင်း၊ ရောင်းချခြင်း၊ ဖြန့်ဖြူးခြင်း။
၂။   \t	နိုင်ငံပိုင်နှင့် ကျောင်းပိုင် အဆောက်အအုံများ၊ ပစ္စည်းများ ဖျက်ဆီးခြင်း၊ ခိုးယူခြင်း၊ အဓမ္မယူခြင်း။
၃။  \t	ဆရာမများ၊ ကျောင်းသား/သူများအား ကာယအိန္ဒြေပျက်ပြားအောင် ပြောဆိုခြင်း၊ ပြုမူခြင်း၊ လုပ်ဆောင်ခြင်း။
၄။  \t	ဆရာ၊ဆရာမ၊ကျောင်းသား၊ကျောင်းသူများနှင့် အခြားပုဂ္ဂိုလ်များအား ဆဲရေးတိုင်းထွာခြင်း၊ ကြိမ်းဝါးခြင်း၊ နှောက်ယှက်ခြင်း။

''';

const String universityThreeRules = '''
၁။	\t ပြစ်မှုဆိုင်ရာ ဥပဒေတစ်ရပ်ရပ်အရ ပြစ်ဒဏ်ခံရခြင်း။
၂။  \t ဆရာ၊ဆရာမများက ဆိုဆုံးမသည်များကို မနာခံခြင်း။
၃။	\t ကျောင်းတွင်း၊ ကျောင်းပြင် လောင်းကစားမှု ကျူးလွန်ခြင်း။
''';

const String universityFourRules = '''
၁။  \t စာသင်ခန်းအတွင်း/အပြင်၌ သင်ကြားမှုကို အနှောက်အယှက်ဖြစ်စေရန် ပြောဆိုခြင်း၊ ပြုမူခြင်း၊ လုပ်ဆောင်ခြင်း။
၂။  \t  ကျောင်းတွင်း/ကျောင်းပြင် ခိုက်ရန်ဖြစ်ပွားခြင်း။
၃။	\t ကျောင်းတွင်း/ကျောင်းပြင် အရက်သေစာ သောက်စားမူးယစ်ခြင်း။
၄။	\t ကျောင်းမှ အခါအားလျော်စွာ ချမှတ်ထားသော ကျောင်းစည်းကမ်းများကို မလိုက်နာခြင်း။
၅။	\t တက္ကသိုလ်/ဒီဂရီကောလိပ်/ကောလိပ် နှင့် သိပ္ပံကျောင်း၏ ဂုဏ်သိက္ခာ ညိုးနွမ်း ထိခိုက်စေမည့် ကိစ္စရပ်များကို ပြောဆိုခြင်း၊ ပြမူခြင်း၊ လုပ်ဆောင်ခြင်း။
''';

class NewUniRules extends StatefulWidget {
  const NewUniRules({super.key});

  @override
  State<NewUniRules> createState() => _UniRulesState();
}

class _UniRulesState extends State<NewUniRules> {
  bool isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MyDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF87CEFA), Color(0xFFADD8E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset('assets/img_2.png', width: 50, height: 50),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tr("uniRules"), style: AppTextStyles.heading),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: DropdownButton<Locale>(
                underline: const SizedBox(),
                icon: const Icon(Icons.language, color: Colors.black),
                value: context.locale,
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) context.setLocale(newLocale);
                },
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text("English")),
                  DropdownMenuItem(value: Locale('my'), child: Text("မြန်မာ")),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "\nပြည်ထောင်စုသမ္မတမြန်မာနိုင်ငံတော်အစိုးရ",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                  Text(
                    "သိပ္ပံနှင့် နည်းပညာဝန်ကြီးဌာန",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                  Text(
                    "အဆင့်မြင့် သိပ္ပံနှင့်နည်းပညာဦးစီးဌာန",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                  Text(
                    "မြန်မာသတင်းအချက်အလက်နည်းပညာတက္ကသိုလ်",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                  Text(
                    "* ကျောင်းသား / ကျောင်းသူများလိုက်နာရန် စည်းကမ်းချက်များ * \n",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(universityRules, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 20),

            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "စာမေးပွဲတွင် မသမာသောနည်းအသုံးပြုဖြေဆိုမှုဆိုင်ရာ ပြစ်မှု/ပြစ်ဒဏ်များ \n",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(universityOneRules, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 20),

            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "\nအကျင့်စာရိတ္တပျက်ပြားမှု ဆိုင်ရာ ပြစ်မှုများ \n",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                ],
              ),
            ),

            Text(
              "* ကျောင်းမှ ထုတ်ပယ်ခြင်း",
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
            ),

            const SizedBox(height: 10),
            Text(universityTwoRules, style: const TextStyle(fontSize: 16, height: 1.5)),



            Text(
              "* ကျောင်းမှ ထုတ်ပယ်ခြင်းနှင့် ပြင်းထန်စွာ သတိပေးခြင်း",
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
            ),

            const SizedBox(height: 10),
            Text(universityThreeRules, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 20),

            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "\nကျောင်းစည်းကမ်းဖောက်ဖျက်မှုဆိုင်ရာ ပြစ်မှုများ \n",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
                  ),
                ],
              ),
            ),
            Text(
              "* ကျောင်းမှ ထုတ်ပယ်ခြင်းနှင့် ပြင်းထန်စွာ သတိပေးခြင်း",
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.6),
            ),

            const SizedBox(height: 10),
            Text(universityFourRules, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: isAgreed,
                  onChanged: (value) => setState(() => isAgreed = value ?? false),
                ),
                Expanded(
                  child: Text(
                    tr("agreeRules"),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isAgreed
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewStudentEnrollmentApp(),
                  ),
                );
              }
                  : null,
              icon: const Icon(Icons.person_2_rounded),
              label: Text(
                tr("nextEnrollment"),
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade100,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                          Icons.arrow_circle_left, size: 40, color: Colors.indigo)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}