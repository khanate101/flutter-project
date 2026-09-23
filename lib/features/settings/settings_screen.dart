import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings_service.dart';

class SettingsScreen extends ConsumerWidget { const SettingsScreen({super.key});
 @override Widget build(BuildContext context,WidgetRef ref){final s=ref.watch(settingsServiceProvider);return Scaffold(appBar:AppBar(title:const Text('الإعدادات')),body:ListView(padding:const EdgeInsets.all(12),children:[
 const ListTile(title:Text('المظهر'),subtitle:Text('اختر الوضع المناسب')),
 RadioListTile<ThemeMode>(value:ThemeMode.system,groupValue:s.themeMode,onChanged:(v)=>s.setThemeMode(v!),title:const Text('تلقائي')),RadioListTile<ThemeMode>(value:ThemeMode.light,groupValue:s.themeMode,onChanged:(v)=>s.setThemeMode(v!),title:const Text('فاتح')),RadioListTile<ThemeMode>(value:ThemeMode.dark,groupValue:s.themeMode,onChanged:(v)=>s.setThemeMode(v!),title:const Text('داكن')),
 SwitchListTile(value:s.autoplay,onChanged:s.setAutoplay,title:const Text('تشغيل الفيديو تلقائيًا')),
 SwitchListTile(value:s.autoSave,onChanged:s.setAutoSave,title:const Text('حفظ تلقائي للحالات الجديدة')),
 ListTile(title:const Text('اللغة'),trailing:DropdownButton<Locale>(value:s.locale,items:const[DropdownMenuItem(value:Locale('ar'),child:Text('العربية')),DropdownMenuItem(value:Locale('en'),child:Text('English'))],onChanged:(v){if(v!=null)s.setLocale(v);})),
 const Divider(),
 const ListTile(title:Text('الخصوصية'),subtitle:Text('StatusVault لا يرفع الصور أو الفيديوهات إلى خادم. لا يقرأ الرسائل أو المحادثات. الوصول للوسائط يخضع لصلاحيات Android.')),
 const AboutListTile(applicationName:'StatusVault',applicationVersion:'1.0.0',applicationLegalese:'احفظ لحظاتك بسهولة'),
 ]));}
}
