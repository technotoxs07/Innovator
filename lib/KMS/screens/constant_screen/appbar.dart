import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/constants/app_style.dart';

class AppbarScreen extends ConsumerWidget {
  const AppbarScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      iconTheme: IconThemeData(color: AppStyle.primaryColor),
      elevation: 0,
      backgroundColor: AppStyle.backgroundColor,
      title: SearchBar(
        padding: WidgetStatePropertyAll(EdgeInsets.only(left: 15)),
        leading: Icon(Icons.search, color: Colors.grey),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: AppStyle.bodyTextSize,
            color: Colors.grey,
            fontFamily: 'InterThin',
          ),
        ),
        hintText: 'Search',
        backgroundColor: WidgetStatePropertyAll(AppStyle.searchBarColor),
        elevation: WidgetStatePropertyAll(0),
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(
                CupertinoIcons.bell_fill,
                color: AppStyle.primaryColor,
              ),
            ),
            Positioned(
              right: 12,
              top: 10,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
    
        Container(
          height: 40,
          width: 80,
          margin: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppStyle.primaryColor,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
    
            children: [
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Container(
                  width: 20,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                    icon: const Icon(
                      Icons.person,
                      size: 20,
                      color: AppStyle.primaryColor,
                    ),
                  ),
                ),
              ),
              PopupMenuButton(
               
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    value: 'profile',
                    child: Text('Profile', style: TextStyle(color: Colors.black)),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings', style: TextStyle(color: Colors.black)),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout', style: TextStyle(color: Colors.black)),
                  ),
                ],
                // onSelected: (value) {
                  
                // },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
