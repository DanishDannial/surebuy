import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData leadingIcon;
  final Function(String) onTextChanged;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onTextChanged,
    this.hintText = "Search...",
    this.leadingIcon = Icons.search,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      onChanged: onTextChanged,
      hintText: hintText,
      leading: Icon(leadingIcon),
    );
  }
}
