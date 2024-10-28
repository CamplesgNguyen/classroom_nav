// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoordPoint _$CoordPointFromJson(Map<String, dynamic> json) => CoordPoint(
      LatLng.fromJson(json['coord'] as Map<String, dynamic>),
      (json['neighborCoords'] as List<dynamic>)
          .map((e) => LatLng.fromJson(e as Map<String, dynamic>))
          .toList(),
    )
      ..locName = json['locName'] as String
      ..isEntrancePoint = json['isEntrancePoint'] as bool?
      ..isStairsPoint = json['isStairsPoint'] as bool?
      ..isElevatorsPoint = json['isElevatorsPoint'] as bool?;

Map<String, dynamic> _$CoordPointToJson(CoordPoint instance) =>
    <String, dynamic>{
      'coord': instance.coord,
      'locName': instance.locName,
      'isEntrancePoint': instance.isEntrancePoint,
      'isStairsPoint': instance.isStairsPoint,
      'isElevatorsPoint': instance.isElevatorsPoint,
      'neighborCoords': instance.neighborCoords,
    };
