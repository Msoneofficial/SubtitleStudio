import 'package:equatable/equatable.dart';

/// States for AI explanation feature
/// Follows clean architecture and immutable state pattern
abstract class AiExplanationState extends Equatable {
  const AiExplanationState();

  @override
  List<Object?> get props => [];
}

/// Initial state - waiting for user action
class AiExplanationInitial extends AiExplanationState {
  const AiExplanationInitial();
}

/// Loading state - API call in progress
class AiExplanationLoading extends AiExplanationState {
  const AiExplanationLoading();
}

/// Success state - explanation received
class AiExplanationSuccess extends AiExplanationState {
  final String explanation;

  const AiExplanationSuccess(this.explanation);

  @override
  List<Object?> get props => [explanation];
}

/// Error state - something went wrong
class AiExplanationError extends AiExplanationState {
  final String message;

  const AiExplanationError(this.message);

  @override
  List<Object?> get props => [message];
}

/// No API key configured state
class AiExplanationNoApiKey extends AiExplanationState {
  const AiExplanationNoApiKey();
}
