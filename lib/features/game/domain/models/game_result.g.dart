// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AroundTheClockResult _$AroundTheClockResultFromJson(
  Map<String, dynamic> json,
) => AroundTheClockResult(
  competitorName: json['competitorName'] as String,
  turnsToComplete: (json['turnsToComplete'] as num).toInt(),
  totalDarts: (json['totalDarts'] as num).toInt(),
  doublesOnly: json['doublesOnly'] as bool,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$AroundTheClockResultToJson(
  AroundTheClockResult instance,
) => <String, dynamic>{
  'competitorName': instance.competitorName,
  'turnsToComplete': instance.turnsToComplete,
  'totalDarts': instance.totalDarts,
  'doublesOnly': instance.doublesOnly,
  'runtimeType': instance.$type,
};

Catch40Result _$Catch40ResultFromJson(Map<String, dynamic> json) =>
    Catch40Result(
      competitorName: json['competitorName'] as String,
      score: (json['score'] as num).toInt(),
      targetsCleared: (json['targetsCleared'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$Catch40ResultToJson(Catch40Result instance) =>
    <String, dynamic>{
      'competitorName': instance.competitorName,
      'score': instance.score,
      'targetsCleared': instance.targetsCleared,
      'runtimeType': instance.$type,
    };

Bobs27Result _$Bobs27ResultFromJson(Map<String, dynamic> json) => Bobs27Result(
  competitorName: json['competitorName'] as String,
  finalScore: (json['finalScore'] as num).toInt(),
  roundReached: (json['roundReached'] as num).toInt(),
  bustedToZero: json['bustedToZero'] as bool,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$Bobs27ResultToJson(Bobs27Result instance) =>
    <String, dynamic>{
      'competitorName': instance.competitorName,
      'finalScore': instance.finalScore,
      'roundReached': instance.roundReached,
      'bustedToZero': instance.bustedToZero,
      'runtimeType': instance.$type,
    };

CheckoutPracticeResult _$CheckoutPracticeResultFromJson(
  Map<String, dynamic> json,
) => CheckoutPracticeResult(
  competitorName: json['competitorName'] as String,
  checkedOut: json['checkedOut'] as bool,
  dartsThrown: (json['dartsThrown'] as num).toInt(),
  fromScore: (json['fromScore'] as num).toInt(),
  remainingScore: (json['remainingScore'] as num).toInt(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$CheckoutPracticeResultToJson(
  CheckoutPracticeResult instance,
) => <String, dynamic>{
  'competitorName': instance.competitorName,
  'checkedOut': instance.checkedOut,
  'dartsThrown': instance.dartsThrown,
  'fromScore': instance.fromScore,
  'remainingScore': instance.remainingScore,
  'runtimeType': instance.$type,
};

ShanghaiResult _$ShanghaiResultFromJson(Map<String, dynamic> json) =>
    ShanghaiResult(
      competitorName: json['competitorName'] as String,
      totalScore: (json['totalScore'] as num).toInt(),
      shanghaiBonuses: (json['shanghaiBonuses'] as num).toInt(),
      bestRound: (json['bestRound'] as num).toInt(),
      roundsPlayed: (json['roundsPlayed'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$ShanghaiResultToJson(ShanghaiResult instance) =>
    <String, dynamic>{
      'competitorName': instance.competitorName,
      'totalScore': instance.totalScore,
      'shanghaiBonuses': instance.shanghaiBonuses,
      'bestRound': instance.bestRound,
      'roundsPlayed': instance.roundsPlayed,
      'runtimeType': instance.$type,
    };
