class LeaveReviewState {
  final int selectedRating;
  final bool isLoading;
  final bool success;
  final String? error;

  const LeaveReviewState({
    this.selectedRating = 0,
    this.isLoading = false,
    this.success = false,
    this.error,
  });

  LeaveReviewState copyWith({
    int? selectedRating,
    bool? isLoading,
    bool? success,
    String? error,
    bool clearError = false,
  }) {
    return LeaveReviewState(
      selectedRating: selectedRating ?? this.selectedRating,
      isLoading: isLoading ?? this.isLoading,
      success: success ?? this.success,
      error: clearError ? null : error ?? this.error,
    );
  }
}
