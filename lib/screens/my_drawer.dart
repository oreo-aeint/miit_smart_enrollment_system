import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:miit_project/screens/home_screen.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              DrawerHeader(
                child: Image.asset('assets/img_2.png', width: 100, height: 100),
              ),
              const SizedBox(height: 25),

              // HOME ListTile
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  leading: const Icon(Icons.home),
                  title: Text(tr("home")), // Localized
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MIITHomePage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Optional: Language switcher at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<Locale>(
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.black),
              value: context.locale,
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  context.setLocale(newLocale);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text("English"),
                ),
                DropdownMenuItem(
                  value: Locale('my'),
                  child: Text("မြန်မာ"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
