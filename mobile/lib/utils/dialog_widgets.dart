import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:mobile/utils/theme.dart';

void loadingDialog(BuildContext context) {
  CoolAlert.show(
    context: context,
    type: CoolAlertType.loading,
    text: 'Loading...',
    barrierDismissible: false,
  );
}

void confirmDialog(BuildContext context, String message, Function() onConfirm, String action) {
  CoolAlert.show(
    context: context,
    barrierDismissible: false,
    type: (action == 'freeze') ? CoolAlertType.confirm : CoolAlertType.warning,
    backgroundColor: (action == 'freeze') ? CustomTheme.darkBlue2.withOpacity(0.2) : const Color.fromARGB(255, 255, 247, 172),
    confirmBtnColor: (action == 'freeze') ? const Color.fromARGB(255, 0, 132, 255) : const Color.fromARGB(255, 255, 206, 11),
    confirmBtnText: 'Yes',
    showCancelBtn: true,
    title: message,
    text: (action == 'terminate') ? 'This action is irreversible.' : null,
    titleTextStyle: const TextStyle(
      fontWeight: FontWeight.w600,
    ),
    cancelBtnTextStyle: const TextStyle(
      fontSize: 18,
      color: CustomTheme.darkGrey,
      fontWeight: FontWeight.w600,
    ),
    confirmBtnTextStyle: const TextStyle(
      fontSize: 18,
      color: CustomTheme.white,
      fontWeight: FontWeight.w600,
    ),
    onConfirmBtnTap: onConfirm,
  );
}

void successDialog(BuildContext context, String message) {
  CoolAlert.show(
    context: context,
    barrierDismissible: false,
    type: CoolAlertType.success,
    backgroundColor: Colors.greenAccent.withOpacity(0.2),
    confirmBtnColor: const Color.fromARGB(255, 73, 186, 143),
    confirmBtnText: 'OK',
    title: message,
    titleTextStyle: const TextStyle(
      fontWeight: FontWeight.w600,
    )
  );
}

void successDialogWithFunction(BuildContext context, String message, String buttonText, {VoidCallback? onConfirm}) {
  CoolAlert.show(
    context: context,
    barrierDismissible: false,
    type: CoolAlertType.success,
    backgroundColor: Colors.greenAccent.withOpacity(0.2),
    confirmBtnColor: const Color.fromARGB(255, 73, 186, 143),
    confirmBtnText: buttonText,
    title: message,
    titleTextStyle: const TextStyle(
      fontWeight: FontWeight.w600,
    ),
    onConfirmBtnTap: onConfirm,
  );
}

void errorDialog(BuildContext context, String message) {
  CoolAlert.show(
    context: context,
    barrierDismissible: false,
    type: CoolAlertType.error,
    backgroundColor: Colors.redAccent.withOpacity(0.1),
    confirmBtnColor: Colors.redAccent,
    confirmBtnText: 'OK',
    title: message,
    titleTextStyle: const TextStyle(
      fontWeight: FontWeight.w600,
    )
  );
}

void connectionLostDialog(BuildContext context, String message) {
  CoolAlert.show(
    context: context,
    barrierDismissible: false,
    autoCloseDuration: const Duration(seconds: 3),
    type: CoolAlertType.error,
    backgroundColor: Colors.redAccent.withOpacity(0.1),
    title: message,
    titleTextStyle: const TextStyle(
      fontWeight: FontWeight.w600,
    )
  );
}
