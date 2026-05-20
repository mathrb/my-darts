// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
GameResult _$GameResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'aroundTheClock':
          return AroundTheClockResult.fromJson(
            json
          );
                case 'catch40':
          return Catch40Result.fromJson(
            json
          );
                case 'bobs27':
          return Bobs27Result.fromJson(
            json
          );
                case 'checkoutPractice':
          return CheckoutPracticeResult.fromJson(
            json
          );
                case 'shanghai':
          return ShanghaiResult.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'GameResult',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$GameResult {

 String get competitorName;
/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameResultCopyWith<GameResult> get copyWith => _$GameResultCopyWithImpl<GameResult>(this as GameResult, _$identity);

  /// Serializes this GameResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameResult&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName);

@override
String toString() {
  return 'GameResult(competitorName: $competitorName)';
}


}

/// @nodoc
abstract mixin class $GameResultCopyWith<$Res>  {
  factory $GameResultCopyWith(GameResult value, $Res Function(GameResult) _then) = _$GameResultCopyWithImpl;
@useResult
$Res call({
 String competitorName
});




}
/// @nodoc
class _$GameResultCopyWithImpl<$Res>
    implements $GameResultCopyWith<$Res> {
  _$GameResultCopyWithImpl(this._self, this._then);

  final GameResult _self;
  final $Res Function(GameResult) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competitorName = null,}) {
  return _then(_self.copyWith(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GameResult].
extension GameResultPatterns on GameResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AroundTheClockResult value)?  aroundTheClock,TResult Function( Catch40Result value)?  catch40,TResult Function( Bobs27Result value)?  bobs27,TResult Function( CheckoutPracticeResult value)?  checkoutPractice,TResult Function( ShanghaiResult value)?  shanghai,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AroundTheClockResult() when aroundTheClock != null:
return aroundTheClock(_that);case Catch40Result() when catch40 != null:
return catch40(_that);case Bobs27Result() when bobs27 != null:
return bobs27(_that);case CheckoutPracticeResult() when checkoutPractice != null:
return checkoutPractice(_that);case ShanghaiResult() when shanghai != null:
return shanghai(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AroundTheClockResult value)  aroundTheClock,required TResult Function( Catch40Result value)  catch40,required TResult Function( Bobs27Result value)  bobs27,required TResult Function( CheckoutPracticeResult value)  checkoutPractice,required TResult Function( ShanghaiResult value)  shanghai,}){
final _that = this;
switch (_that) {
case AroundTheClockResult():
return aroundTheClock(_that);case Catch40Result():
return catch40(_that);case Bobs27Result():
return bobs27(_that);case CheckoutPracticeResult():
return checkoutPractice(_that);case ShanghaiResult():
return shanghai(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AroundTheClockResult value)?  aroundTheClock,TResult? Function( Catch40Result value)?  catch40,TResult? Function( Bobs27Result value)?  bobs27,TResult? Function( CheckoutPracticeResult value)?  checkoutPractice,TResult? Function( ShanghaiResult value)?  shanghai,}){
final _that = this;
switch (_that) {
case AroundTheClockResult() when aroundTheClock != null:
return aroundTheClock(_that);case Catch40Result() when catch40 != null:
return catch40(_that);case Bobs27Result() when bobs27 != null:
return bobs27(_that);case CheckoutPracticeResult() when checkoutPractice != null:
return checkoutPractice(_that);case ShanghaiResult() when shanghai != null:
return shanghai(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String competitorName,  int turnsToComplete,  int totalDarts,  bool doublesOnly)?  aroundTheClock,TResult Function( String competitorName,  int score,  int targetsCleared)?  catch40,TResult Function( String competitorName,  int finalScore,  int roundReached,  bool bustedToZero)?  bobs27,TResult Function( String competitorName,  bool checkedOut,  int dartsThrown,  int fromScore,  int remainingScore)?  checkoutPractice,TResult Function( String competitorName,  int totalScore,  int shanghaiBonuses,  int bestRound,  int roundsPlayed)?  shanghai,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AroundTheClockResult() when aroundTheClock != null:
return aroundTheClock(_that.competitorName,_that.turnsToComplete,_that.totalDarts,_that.doublesOnly);case Catch40Result() when catch40 != null:
return catch40(_that.competitorName,_that.score,_that.targetsCleared);case Bobs27Result() when bobs27 != null:
return bobs27(_that.competitorName,_that.finalScore,_that.roundReached,_that.bustedToZero);case CheckoutPracticeResult() when checkoutPractice != null:
return checkoutPractice(_that.competitorName,_that.checkedOut,_that.dartsThrown,_that.fromScore,_that.remainingScore);case ShanghaiResult() when shanghai != null:
return shanghai(_that.competitorName,_that.totalScore,_that.shanghaiBonuses,_that.bestRound,_that.roundsPlayed);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String competitorName,  int turnsToComplete,  int totalDarts,  bool doublesOnly)  aroundTheClock,required TResult Function( String competitorName,  int score,  int targetsCleared)  catch40,required TResult Function( String competitorName,  int finalScore,  int roundReached,  bool bustedToZero)  bobs27,required TResult Function( String competitorName,  bool checkedOut,  int dartsThrown,  int fromScore,  int remainingScore)  checkoutPractice,required TResult Function( String competitorName,  int totalScore,  int shanghaiBonuses,  int bestRound,  int roundsPlayed)  shanghai,}) {final _that = this;
switch (_that) {
case AroundTheClockResult():
return aroundTheClock(_that.competitorName,_that.turnsToComplete,_that.totalDarts,_that.doublesOnly);case Catch40Result():
return catch40(_that.competitorName,_that.score,_that.targetsCleared);case Bobs27Result():
return bobs27(_that.competitorName,_that.finalScore,_that.roundReached,_that.bustedToZero);case CheckoutPracticeResult():
return checkoutPractice(_that.competitorName,_that.checkedOut,_that.dartsThrown,_that.fromScore,_that.remainingScore);case ShanghaiResult():
return shanghai(_that.competitorName,_that.totalScore,_that.shanghaiBonuses,_that.bestRound,_that.roundsPlayed);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String competitorName,  int turnsToComplete,  int totalDarts,  bool doublesOnly)?  aroundTheClock,TResult? Function( String competitorName,  int score,  int targetsCleared)?  catch40,TResult? Function( String competitorName,  int finalScore,  int roundReached,  bool bustedToZero)?  bobs27,TResult? Function( String competitorName,  bool checkedOut,  int dartsThrown,  int fromScore,  int remainingScore)?  checkoutPractice,TResult? Function( String competitorName,  int totalScore,  int shanghaiBonuses,  int bestRound,  int roundsPlayed)?  shanghai,}) {final _that = this;
switch (_that) {
case AroundTheClockResult() when aroundTheClock != null:
return aroundTheClock(_that.competitorName,_that.turnsToComplete,_that.totalDarts,_that.doublesOnly);case Catch40Result() when catch40 != null:
return catch40(_that.competitorName,_that.score,_that.targetsCleared);case Bobs27Result() when bobs27 != null:
return bobs27(_that.competitorName,_that.finalScore,_that.roundReached,_that.bustedToZero);case CheckoutPracticeResult() when checkoutPractice != null:
return checkoutPractice(_that.competitorName,_that.checkedOut,_that.dartsThrown,_that.fromScore,_that.remainingScore);case ShanghaiResult() when shanghai != null:
return shanghai(_that.competitorName,_that.totalScore,_that.shanghaiBonuses,_that.bestRound,_that.roundsPlayed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class AroundTheClockResult implements GameResult {
  const AroundTheClockResult({required this.competitorName, required this.turnsToComplete, required this.totalDarts, required this.doublesOnly, final  String? $type}): $type = $type ?? 'aroundTheClock';
  factory AroundTheClockResult.fromJson(Map<String, dynamic> json) => _$AroundTheClockResultFromJson(json);

@override final  String competitorName;
 final  int turnsToComplete;
 final  int totalDarts;
 final  bool doublesOnly;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AroundTheClockResultCopyWith<AroundTheClockResult> get copyWith => _$AroundTheClockResultCopyWithImpl<AroundTheClockResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AroundTheClockResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AroundTheClockResult&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.turnsToComplete, turnsToComplete) || other.turnsToComplete == turnsToComplete)&&(identical(other.totalDarts, totalDarts) || other.totalDarts == totalDarts)&&(identical(other.doublesOnly, doublesOnly) || other.doublesOnly == doublesOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName,turnsToComplete,totalDarts,doublesOnly);

@override
String toString() {
  return 'GameResult.aroundTheClock(competitorName: $competitorName, turnsToComplete: $turnsToComplete, totalDarts: $totalDarts, doublesOnly: $doublesOnly)';
}


}

/// @nodoc
abstract mixin class $AroundTheClockResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $AroundTheClockResultCopyWith(AroundTheClockResult value, $Res Function(AroundTheClockResult) _then) = _$AroundTheClockResultCopyWithImpl;
@override @useResult
$Res call({
 String competitorName, int turnsToComplete, int totalDarts, bool doublesOnly
});




}
/// @nodoc
class _$AroundTheClockResultCopyWithImpl<$Res>
    implements $AroundTheClockResultCopyWith<$Res> {
  _$AroundTheClockResultCopyWithImpl(this._self, this._then);

  final AroundTheClockResult _self;
  final $Res Function(AroundTheClockResult) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorName = null,Object? turnsToComplete = null,Object? totalDarts = null,Object? doublesOnly = null,}) {
  return _then(AroundTheClockResult(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,turnsToComplete: null == turnsToComplete ? _self.turnsToComplete : turnsToComplete // ignore: cast_nullable_to_non_nullable
as int,totalDarts: null == totalDarts ? _self.totalDarts : totalDarts // ignore: cast_nullable_to_non_nullable
as int,doublesOnly: null == doublesOnly ? _self.doublesOnly : doublesOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Catch40Result implements GameResult {
  const Catch40Result({required this.competitorName, required this.score, required this.targetsCleared, final  String? $type}): $type = $type ?? 'catch40';
  factory Catch40Result.fromJson(Map<String, dynamic> json) => _$Catch40ResultFromJson(json);

@override final  String competitorName;
 final  int score;
 final  int targetsCleared;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Catch40ResultCopyWith<Catch40Result> get copyWith => _$Catch40ResultCopyWithImpl<Catch40Result>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Catch40ResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Catch40Result&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.score, score) || other.score == score)&&(identical(other.targetsCleared, targetsCleared) || other.targetsCleared == targetsCleared));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName,score,targetsCleared);

@override
String toString() {
  return 'GameResult.catch40(competitorName: $competitorName, score: $score, targetsCleared: $targetsCleared)';
}


}

/// @nodoc
abstract mixin class $Catch40ResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $Catch40ResultCopyWith(Catch40Result value, $Res Function(Catch40Result) _then) = _$Catch40ResultCopyWithImpl;
@override @useResult
$Res call({
 String competitorName, int score, int targetsCleared
});




}
/// @nodoc
class _$Catch40ResultCopyWithImpl<$Res>
    implements $Catch40ResultCopyWith<$Res> {
  _$Catch40ResultCopyWithImpl(this._self, this._then);

  final Catch40Result _self;
  final $Res Function(Catch40Result) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorName = null,Object? score = null,Object? targetsCleared = null,}) {
  return _then(Catch40Result(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,targetsCleared: null == targetsCleared ? _self.targetsCleared : targetsCleared // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Bobs27Result implements GameResult {
  const Bobs27Result({required this.competitorName, required this.finalScore, required this.roundReached, required this.bustedToZero, final  String? $type}): $type = $type ?? 'bobs27';
  factory Bobs27Result.fromJson(Map<String, dynamic> json) => _$Bobs27ResultFromJson(json);

@override final  String competitorName;
 final  int finalScore;
 final  int roundReached;
 final  bool bustedToZero;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Bobs27ResultCopyWith<Bobs27Result> get copyWith => _$Bobs27ResultCopyWithImpl<Bobs27Result>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Bobs27ResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bobs27Result&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.roundReached, roundReached) || other.roundReached == roundReached)&&(identical(other.bustedToZero, bustedToZero) || other.bustedToZero == bustedToZero));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName,finalScore,roundReached,bustedToZero);

@override
String toString() {
  return 'GameResult.bobs27(competitorName: $competitorName, finalScore: $finalScore, roundReached: $roundReached, bustedToZero: $bustedToZero)';
}


}

/// @nodoc
abstract mixin class $Bobs27ResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $Bobs27ResultCopyWith(Bobs27Result value, $Res Function(Bobs27Result) _then) = _$Bobs27ResultCopyWithImpl;
@override @useResult
$Res call({
 String competitorName, int finalScore, int roundReached, bool bustedToZero
});




}
/// @nodoc
class _$Bobs27ResultCopyWithImpl<$Res>
    implements $Bobs27ResultCopyWith<$Res> {
  _$Bobs27ResultCopyWithImpl(this._self, this._then);

  final Bobs27Result _self;
  final $Res Function(Bobs27Result) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorName = null,Object? finalScore = null,Object? roundReached = null,Object? bustedToZero = null,}) {
  return _then(Bobs27Result(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,finalScore: null == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int,roundReached: null == roundReached ? _self.roundReached : roundReached // ignore: cast_nullable_to_non_nullable
as int,bustedToZero: null == bustedToZero ? _self.bustedToZero : bustedToZero // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CheckoutPracticeResult implements GameResult {
  const CheckoutPracticeResult({required this.competitorName, required this.checkedOut, required this.dartsThrown, required this.fromScore, required this.remainingScore, final  String? $type}): $type = $type ?? 'checkoutPractice';
  factory CheckoutPracticeResult.fromJson(Map<String, dynamic> json) => _$CheckoutPracticeResultFromJson(json);

@override final  String competitorName;
 final  bool checkedOut;
 final  int dartsThrown;
 final  int fromScore;
 final  int remainingScore;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutPracticeResultCopyWith<CheckoutPracticeResult> get copyWith => _$CheckoutPracticeResultCopyWithImpl<CheckoutPracticeResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutPracticeResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutPracticeResult&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.checkedOut, checkedOut) || other.checkedOut == checkedOut)&&(identical(other.dartsThrown, dartsThrown) || other.dartsThrown == dartsThrown)&&(identical(other.fromScore, fromScore) || other.fromScore == fromScore)&&(identical(other.remainingScore, remainingScore) || other.remainingScore == remainingScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName,checkedOut,dartsThrown,fromScore,remainingScore);

@override
String toString() {
  return 'GameResult.checkoutPractice(competitorName: $competitorName, checkedOut: $checkedOut, dartsThrown: $dartsThrown, fromScore: $fromScore, remainingScore: $remainingScore)';
}


}

/// @nodoc
abstract mixin class $CheckoutPracticeResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $CheckoutPracticeResultCopyWith(CheckoutPracticeResult value, $Res Function(CheckoutPracticeResult) _then) = _$CheckoutPracticeResultCopyWithImpl;
@override @useResult
$Res call({
 String competitorName, bool checkedOut, int dartsThrown, int fromScore, int remainingScore
});




}
/// @nodoc
class _$CheckoutPracticeResultCopyWithImpl<$Res>
    implements $CheckoutPracticeResultCopyWith<$Res> {
  _$CheckoutPracticeResultCopyWithImpl(this._self, this._then);

  final CheckoutPracticeResult _self;
  final $Res Function(CheckoutPracticeResult) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorName = null,Object? checkedOut = null,Object? dartsThrown = null,Object? fromScore = null,Object? remainingScore = null,}) {
  return _then(CheckoutPracticeResult(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,checkedOut: null == checkedOut ? _self.checkedOut : checkedOut // ignore: cast_nullable_to_non_nullable
as bool,dartsThrown: null == dartsThrown ? _self.dartsThrown : dartsThrown // ignore: cast_nullable_to_non_nullable
as int,fromScore: null == fromScore ? _self.fromScore : fromScore // ignore: cast_nullable_to_non_nullable
as int,remainingScore: null == remainingScore ? _self.remainingScore : remainingScore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ShanghaiResult implements GameResult {
  const ShanghaiResult({required this.competitorName, required this.totalScore, required this.shanghaiBonuses, required this.bestRound, required this.roundsPlayed, final  String? $type}): $type = $type ?? 'shanghai';
  factory ShanghaiResult.fromJson(Map<String, dynamic> json) => _$ShanghaiResultFromJson(json);

@override final  String competitorName;
 final  int totalScore;
 final  int shanghaiBonuses;
 final  int bestRound;
 final  int roundsPlayed;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShanghaiResultCopyWith<ShanghaiResult> get copyWith => _$ShanghaiResultCopyWithImpl<ShanghaiResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShanghaiResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShanghaiResult&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&(identical(other.shanghaiBonuses, shanghaiBonuses) || other.shanghaiBonuses == shanghaiBonuses)&&(identical(other.bestRound, bestRound) || other.bestRound == bestRound)&&(identical(other.roundsPlayed, roundsPlayed) || other.roundsPlayed == roundsPlayed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName,totalScore,shanghaiBonuses,bestRound,roundsPlayed);

@override
String toString() {
  return 'GameResult.shanghai(competitorName: $competitorName, totalScore: $totalScore, shanghaiBonuses: $shanghaiBonuses, bestRound: $bestRound, roundsPlayed: $roundsPlayed)';
}


}

/// @nodoc
abstract mixin class $ShanghaiResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $ShanghaiResultCopyWith(ShanghaiResult value, $Res Function(ShanghaiResult) _then) = _$ShanghaiResultCopyWithImpl;
@override @useResult
$Res call({
 String competitorName, int totalScore, int shanghaiBonuses, int bestRound, int roundsPlayed
});




}
/// @nodoc
class _$ShanghaiResultCopyWithImpl<$Res>
    implements $ShanghaiResultCopyWith<$Res> {
  _$ShanghaiResultCopyWithImpl(this._self, this._then);

  final ShanghaiResult _self;
  final $Res Function(ShanghaiResult) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorName = null,Object? totalScore = null,Object? shanghaiBonuses = null,Object? bestRound = null,Object? roundsPlayed = null,}) {
  return _then(ShanghaiResult(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,shanghaiBonuses: null == shanghaiBonuses ? _self.shanghaiBonuses : shanghaiBonuses // ignore: cast_nullable_to_non_nullable
as int,bestRound: null == bestRound ? _self.bestRound : bestRound // ignore: cast_nullable_to_non_nullable
as int,roundsPlayed: null == roundsPlayed ? _self.roundsPlayed : roundsPlayed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
