import 'package:classroom_nav/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String> addLocNamePopup(context) async {
  TextEditingController newLocName = TextEditingController();
  final nameFormKey = GlobalKey<FormState>();
  return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
                shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).primaryColorLight), borderRadius: const BorderRadius.all(Radius.circular(5))),
                titlePadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
                title: const Text('Location Name', style: TextStyle(fontWeight: FontWeight.w700)),
                contentPadding: const EdgeInsets.only(left: 10, right: 10),
                content: Form(
                  key: nameFormKey,
                  child: TextFormField(
                    controller: newLocName,
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.deny(RegExp('[\\/:*?"<>|]'))],
                    validator: (value) {
                      if (mappedCoords.indexWhere((e) => e.locName == value) != -1) {
                        return 'This name already existed';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        labelText: 'Enter location name',
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Theme.of(context).colorScheme.error),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Theme.of(context).colorScheme.error),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        //isCollapsed: true,
                        //isDense: true,
                        contentPadding: const EdgeInsets.only(left: 5, right: 5, bottom: 2),
                        constraints: const BoxConstraints.tightForFinite(),
                        // Set border for enabled state (default)
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Theme.of(context).hintColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        // Set border for focused state
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(2),
                        )),
                    onChanged: (value) async {
                      setState(() {
                        nameFormKey.currentState!.validate();
                      });
                    },
                  ),
                ),
                actionsPadding: const EdgeInsets.all(10),
                actions: <Widget>[
                  ElevatedButton(
                      child: const Text('Cancel'),
                      onPressed: () async {
                        Navigator.pop(context, '');
                      }),
                  ElevatedButton(
                      onPressed: newLocName.text.isEmpty
                          ? null
                          : () async {
                              if (nameFormKey.currentState!.validate()) {
                                Navigator.pop(context, newLocName.text);
                              }
                            },
                      child: const Text('Set'))
                ]);
          }));
}