import '../../game/circle_rouge_game.dart';
import '../hero.dart';

/// Abstract base class for all hero ultimate abilities
/// Each hero should have their own implementation extending this class
abstract class UltimateAbility {
  /// Reference to the hero using this ultimate
  final Hero hero;
  
  /// Reference to the game instance
  CircleRougeGame get gameRef => hero.gameRef;
  
  /// Whether the ultimate is currently active
  bool get isActive => hero.isUsingUltimate;
  
  UltimateAbility(this.hero);
  
  /// Called when the ultimate is activated
  /// Should initialize the ultimate state
  void activate();
  
  /// Called every frame while the ultimate is active
  /// [dt] is the delta time since last frame
  void update(double dt);
  
  /// Called when the ultimate ends (either naturally or forcefully)
  void deactivate();
  
  /// Get the name of this ultimate ability
  String get name;
}

