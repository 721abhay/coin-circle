import 'package:flutter_riverpod/flutter_riverpod.dart';

final createPoolProvider = StateNotifierProvider<CreatePoolNotifier, CreatePoolState>((ref) {
  return CreatePoolNotifier();
});

class CreatePoolState {
  final String name;
  final String description;
  final String category;
  final String image;
  final double amount;
  final String frequency;
  final int duration;
  final int maxMembers;
  final bool isPrivate;
  final int paymentDay; // Day of month for payment (1-28)
  final double lateFee;
  final int autoRemovalMissedPayments;
  final String winnerSelectionMethod;
  final double emergencyFund;
  final bool enableChat;
  final bool requireIdVerification;
  final DateTime? joiningDeadline;
  final int startDrawMonth;

  CreatePoolState({
    this.name = '',
    this.description = '',
    this.category = 'Friends',
    this.image = '',
    this.amount = 100,
    this.frequency = 'Monthly',
    this.duration = 10,
    this.maxMembers = 10,
    this.isPrivate = true,
    this.paymentDay = 1, // Default to 1st of month
    this.lateFee = 5.0,
    this.autoRemovalMissedPayments = 2,
    this.winnerSelectionMethod = 'Random Draw',
    this.emergencyFund = 0.0,
    this.enableChat = true,
    this.requireIdVerification = false,
    this.joiningDeadline,
    this.startDrawMonth = 1,
  });

  CreatePoolState copyWith({
    String? name,
    String? description,
    String? category,
    String? image,
    double? amount,
    String? frequency,
    int? duration,
    int? maxMembers,
    bool? isPrivate,
    int? paymentDay,
    double? lateFee,
    int? autoRemovalMissedPayments,
    String? winnerSelectionMethod,
    double? emergencyFund,
    bool? enableChat,
    bool? requireIdVerification,
    DateTime? joiningDeadline,
    int? startDrawMonth,
  }) {
    return CreatePoolState(
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      maxMembers: maxMembers ?? this.maxMembers,
      isPrivate: isPrivate ?? this.isPrivate,
      paymentDay: paymentDay ?? this.paymentDay,
      lateFee: lateFee ?? this.lateFee,
      autoRemovalMissedPayments: autoRemovalMissedPayments ?? this.autoRemovalMissedPayments,
      winnerSelectionMethod: winnerSelectionMethod ?? this.winnerSelectionMethod,
      emergencyFund: emergencyFund ?? this.emergencyFund,
      enableChat: enableChat ?? this.enableChat,
      requireIdVerification: requireIdVerification ?? this.requireIdVerification,
      joiningDeadline: joiningDeadline ?? this.joiningDeadline,
      startDrawMonth: startDrawMonth ?? this.startDrawMonth,
    );
  }
}

class CreatePoolNotifier extends StateNotifier<CreatePoolState> {
  CreatePoolNotifier() : super(CreatePoolState());

  void updateName(String name) => state = state.copyWith(name: name);
  void updateDescription(String description) => state = state.copyWith(description: description);
  void updateCategory(String category) => state = state.copyWith(category: category);
  void updateImage(String image) => state = state.copyWith(image: image);
  void updateAmount(double amount) => state = state.copyWith(amount: amount);
  void updateFrequency(String frequency) => state = state.copyWith(frequency: frequency);
  void updateDuration(int duration) => state = state.copyWith(duration: duration);
  void updateMaxMembers(int maxMembers) => state = state.copyWith(maxMembers: maxMembers);
  void updatePrivacy(bool isPrivate) => state = state.copyWith(isPrivate: isPrivate);
  void updatePaymentDay(int day) => state = state.copyWith(paymentDay: day);
  void updateLateFee(double fee) => state = state.copyWith(lateFee: fee);
  void updateAutoRemoval(int payments) => state = state.copyWith(autoRemovalMissedPayments: payments);
  void updateWinnerSelection(String method) => state = state.copyWith(winnerSelectionMethod: method);
  void updateEmergencyFund(double percent) => state = state.copyWith(emergencyFund: percent);
  void updateEnableChat(bool enable) => state = state.copyWith(enableChat: enable);
  void updateIdVerification(bool require) => state = state.copyWith(requireIdVerification: require);
  void updateJoiningDeadline(DateTime date) => state = state.copyWith(joiningDeadline: date);
  void updateStartDrawMonth(int month) => state = state.copyWith(startDrawMonth: month);
}
