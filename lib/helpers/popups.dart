import 'package:classroom_nav/global_variables.dart';
import 'package:classroom_nav/helpers/classes.dart';
import 'package:classroom_nav/helpers/json_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:toggle_switch/toggle_switch.dart';

Future<void> mappingCoordSettingsPopup(context, CoordPoint point) async {
  TextEditingController newLocName = TextEditingController();
  int locTypeIndex = -1;
  List<LatLng> toBeRemovedNeighborCoords = [];
  final nameFormKey = GlobalKey<FormState>();
  return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
                shape: RoundedRectangleBorder(side: BorderSide(color: Theme.of(context).primaryColorLight), borderRadius: const BorderRadius.all(Radius.circular(5))),
                titlePadding: const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
                title: const Text('Coord Settings', style: TextStyle(fontWeight: FontWeight.w700)),
                contentPadding: const EdgeInsets.only(left: 10, right: 10),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location Name', style: Theme.of(context).textTheme.titleMedium),
                    Form(
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
                    Divider(
                      thickness: 2,
                      color: Theme.of(context).dividerColor,
                    ),
                    Text('Types', style: Theme.of(context).textTheme.titleMedium),
                    ToggleSwitch(
                      minWidth: double.infinity,
                      minHeight: 30,
                      initialLabelIndex: 0,
                      totalSwitches: 4,
                      labels: const ['None', 'Entrance', 'Stairs', 'Elevators'],
                      onToggle: (index) {
                        if (index != null) {
                          locTypeIndex = index;
                        }
                      },
                    ),
                    Divider(
                      thickness: 2,
                      color: Theme.of(context).dividerColor,
                    ),
                    Text('Connected coords', style: Theme.of(context).textTheme.titleMedium),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < point.neighborCoords.length; i++)
                          ListTile(
                            dense: true,
                            title: Text('Lat: ${point.neighborCoords[i].latitude}\nLng: ${point.neighborCoords[i].longitude}'),
                            trailing: ElevatedButton.icon(
                                onPressed: () {
                                  if (!toBeRemovedNeighborCoords.contains(point.neighborCoords[i])) {
                                    toBeRemovedNeighborCoords.add(point.neighborCoords[i]);
                                  } else {
                                    toBeRemovedNeighborCoords.remove(point.neighborCoords[i]);
                                  }
                                  setState(
                                    () {},
                                  );
                                },
                                label: Icon(Icons.delete, color: toBeRemovedNeighborCoords.contains(point.neighborCoords[i]) ? Colors.red : null)),
                          )
                      ],
                    )
                  ],
                ),
                actionsPadding: const EdgeInsets.all(10),
                actions: <Widget>[
                  ElevatedButton(
                      child: const Text('Cancel'),
                      onPressed: () async {
                        Navigator.pop(context);
                      }),
                  ElevatedButton(
                      onPressed: () async {
                        // Rename
                        if (nameFormKey.currentState!.validate()) {
                          point.locName = newLocName.text;
                        }
                        // Types
                        locTypeIndex == 1
                            ? point.isEntrancePoint = true
                            : locTypeIndex == 2
                                ? point.isStairsPoint = true
                                : locTypeIndex == 3
                                    ? point.isElevatorsPoint = true
                                    : locTypeIndex = -1;
                        // Neighbor coords
                        for (var element in toBeRemovedNeighborCoords) {
                          mappedCoords
                              .firstWhere((e) => e.coord.latitude == element.latitude && e.coord.longitude == element.longitude)
                              .neighborCoords
                              .removeWhere((e) => e.latitude == point.coord.latitude && e.longitude == point.coord.longitude);
                        }
                        point.neighborCoords.removeWhere((e) => toBeRemovedNeighborCoords.contains(e));
                        for (var element in toBeRemovedNeighborCoords) {
                          mappedPaths.removeWhere((e) =>
                              e.points.where((c) => c.latitude == element.latitude && c.longitude == element.longitude).isNotEmpty &&
                              e.points.where((c) => c.latitude == point.coord.latitude && c.longitude == point.coord.longitude).isNotEmpty);
                        }
                        //Save
                        mappedCoordSave();
                        Navigator.pop(context);
                      },
                      child: const Text('Save'))
                ]);
          }));
}
