// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Warehouse Management';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get continue_ => 'Continue';

  @override
  String get loginUsername => 'Username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'Log In';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginRegister => 'Register';

  @override
  String get loginEmptyError => 'Please enter username and password';

  @override
  String get loginFailedNetwork => 'Login failed, please check your network';

  @override
  String get loginRecentTitle => 'Recent Accounts';

  @override
  String get loginClearAll => 'Clear All';

  @override
  String get loginClearAllTitle => 'Clear Records';

  @override
  String get loginClearAllContent =>
      'Remove all saved accounts on this device?';

  @override
  String get loginUseOtherAccount => 'Use another account';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle =>
      'Register to use the Warehouse Management System';

  @override
  String get registerName => 'Name / Display Name';

  @override
  String get registerConfirmPassword => 'Confirm Password';

  @override
  String get registerButton => 'Register';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerValidation =>
      'Please fill in all fields, password must be at least 6 characters';

  @override
  String get registerPasswordMismatch => 'Passwords do not match';

  @override
  String get registerFailed => 'Registration failed';

  @override
  String get passwordRuleLength => '6–20 characters';

  @override
  String get passwordRuleLowercase => 'Contains lowercase letters';

  @override
  String get passwordRuleDigit => 'Contains digits';

  @override
  String get passwordRuleAlnum => 'Lowercase letters and digits only';

  @override
  String get forgotTitle => 'Forgot Password';

  @override
  String get forgotSubtitle =>
      'Contact your admin to reset your password.\nFill in your username and submit a request.';

  @override
  String get forgotAdminContact => 'Contact Admin';

  @override
  String get forgotAdminDesc =>
      'Passwords are managed by the administrator. Please contact your warehouse supervisor or system admin, provide your username, and ask them to reset your password.';

  @override
  String get forgotNote => 'Note (optional) — e.g. contact info / details';

  @override
  String get forgotSubmit => 'Submit Request';

  @override
  String get forgotDismiss => 'Got it';

  @override
  String get forgotSuccessTitle => 'Request Submitted';

  @override
  String get forgotSuccessDesc =>
      'The admin will reset your password after reviewing your request.\nPlease wait for notification.';

  @override
  String get forgotBackToLogin => 'Back to Login';

  @override
  String get forgotEmptyError => 'Please enter your username';

  @override
  String get forgotSubmitFailed => 'Submission failed, please try again';

  @override
  String get forceChangeTitle => 'Change Password Required';

  @override
  String get forceChangeNotice =>
      'Your password has been reset by the admin. Please change it before continuing.';

  @override
  String get forceChangeOldPassword => 'Current Password (temporary)';

  @override
  String get forceChangeNewPassword => 'New Password (min. 6 characters)';

  @override
  String get forceChangeConfirmPassword => 'Confirm New Password';

  @override
  String get forceChangeButton => 'Confirm Change';

  @override
  String get forceChangeEmptyError => 'Please fill in all fields';

  @override
  String get forceChangeShortError =>
      'New password must be at least 6 characters';

  @override
  String get forceChangeMismatchError => 'New passwords do not match';

  @override
  String get forceChangeSameError =>
      'New password cannot be the same as current password';

  @override
  String get forceChangeFailed => 'Change failed, please try again';

  @override
  String get navSku => 'SKU';

  @override
  String get navLocation => 'Location';

  @override
  String get navScanner => 'Scan';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get skuScreenTitle => 'SKU Search';

  @override
  String get skuSearchHint => 'Search SKU / name / barcode...';

  @override
  String get skuFilterActive => 'Active';

  @override
  String get skuFilterAll => 'Include Archived';

  @override
  String get skuFilterArchived => 'Archived Only';

  @override
  String get skuEmptyArchived => 'No archived SKUs';

  @override
  String get skuEmpty => 'No SKUs';

  @override
  String skuNoResult(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get skuSearchTip => 'Try a shorter keyword or ignore separators';

  @override
  String get skuNoStock => 'No stock';

  @override
  String get unitBox => 'box';

  @override
  String get unitPiece => 'pcs';

  @override
  String skuTotalQty(int qty, String unit) {
    return '$qty $unit total';
  }

  @override
  String get locationScreenTitle => 'Location Search';

  @override
  String get locationSearchHint => 'Search location code or description...';

  @override
  String get locationEmpty => 'No locations';

  @override
  String get locationNoResult => 'No matching locations';

  @override
  String get locationNewButton => 'New Location';

  @override
  String get locationNoStock => 'No stock';

  @override
  String locationTotalQty(int qty) {
    return '$qty pcs total';
  }

  @override
  String get scannerTitle => 'Barcode Scanner';

  @override
  String get scannerHint => 'Point the barcode/QR code at the frame';

  @override
  String get scannerViewDetail => 'View Details';

  @override
  String get scannerStockLocations => 'Stock Locations:';

  @override
  String get scannerOutOfStock => 'Out of Stock';

  @override
  String get scannerAllZero => 'All locations have 0 stock';

  @override
  String get scannerRestock => 'Restock';

  @override
  String get scannerContinue => 'Continue Scanning';

  @override
  String get scannerNotFound => 'Product Not Found';

  @override
  String scannerBarcode(String code) {
    return 'Barcode: $code';
  }

  @override
  String get scannerAddProduct => 'Add Product';

  @override
  String get scannerMultipleFound => 'Multiple Matches Found';

  @override
  String scannerTotalStock(int qty) {
    return 'Total Stock: $qty boxes';
  }

  @override
  String scannerQtyPiece(int qty) {
    return '$qty pcs';
  }

  @override
  String get historyTitle => 'Operation History';

  @override
  String get historyAllUsers => 'All Users';

  @override
  String get historyEmpty => 'No records';

  @override
  String get historyFilterDate => 'Date';

  @override
  String get historyFilterAction => 'Action';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyToday => 'Today';

  @override
  String get historyThisWeek => 'This Week';

  @override
  String get historyThisMonth => 'This Month';

  @override
  String get historyCustom => 'Custom';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsDisplayName => 'Display Name';

  @override
  String get settingsNameEmpty => 'Name cannot be empty';

  @override
  String get settingsProfileUpdated => 'Profile updated';

  @override
  String get settingsUpdateFailed => 'Update failed';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsOldPassword => 'Current Password';

  @override
  String get settingsNewPassword => 'New Password (min. 6 characters)';

  @override
  String get settingsPasswordChanged => 'Password changed successfully';

  @override
  String get settingsPasswordChangeFailed => 'Change failed';

  @override
  String get settingsSwitchAccount => 'Switch Account';

  @override
  String get settingsSwitchAccountSubtitle =>
      'Log out and return to login page';

  @override
  String get settingsSectionManage => 'Management';

  @override
  String get settingsUserManagement => 'User Management';

  @override
  String get settingsUserManagementSubtitle =>
      'Create accounts / assign roles / disable accounts';

  @override
  String get settingsPasswordResetRequests => 'Password Reset Requests';

  @override
  String get settingsPasswordResetRequestsSubtitle =>
      'Handle forgot password requests';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsDataImport => 'Import Data';

  @override
  String get settingsDataImportSubtitle =>
      'SKU master / Location master / Inventory details';

  @override
  String get settingsExportExcel => 'Export Excel';

  @override
  String get settingsExportExcelSubtitle =>
      'Export all SKUs, locations, inventory and transactions';

  @override
  String get settingsExporting => 'Generating Excel, please wait...';

  @override
  String settingsExportDone(String filename) {
    return 'Downloaded: $filename';
  }

  @override
  String get settingsSectionDanger => 'Danger Zone';

  @override
  String get settingsClearAllData => 'Clear All Business Data';

  @override
  String get settingsClearAllDataSubtitle =>
      'Clear inventory, SKU, location, transactions, logs and import records. User accounts are kept.';

  @override
  String get settingsClearDataTitle => 'Dangerous Operation';

  @override
  String get settingsClearDataContent =>
      'This will permanently delete:\n\n• All inventory records\n• All SKU master data\n• All location master data\n• All transactions\n• All audit logs\n• All import records\n\nUser accounts will be kept.\n\nThis action cannot be undone!';

  @override
  String get settingsSecondConfirmTitle => 'Second Confirmation';

  @override
  String get settingsSecondConfirmContent => 'Type \"CLEAR DATA\" to confirm:';

  @override
  String get settingsClearDataHint => 'CLEAR DATA';

  @override
  String get settingsInputIncorrect => 'Incorrect input';

  @override
  String get settingsConfirmClear => 'Confirm Clear';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Change the display language';

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get langSystem => 'System Default';

  @override
  String get langSelectTitle => 'Select Language';

  @override
  String get skuFormTitle => 'SKU Info';

  @override
  String get skuFormSkuCode => 'SKU Code';

  @override
  String get skuFormName => 'Name (optional)';

  @override
  String get skuFormBarcode => 'Barcode (optional)';

  @override
  String get skuFormCartonQty => 'Carton Qty (pcs/box, optional)';

  @override
  String get skuFormSkuEmpty => 'SKU code cannot be empty';

  @override
  String get skuFormSaveSuccess => 'Saved successfully';

  @override
  String get skuFormArchive => 'Archive';

  @override
  String get skuFormUnarchive => 'Unarchive';

  @override
  String get skuFormDelete => 'Delete';

  @override
  String get skuFormConfirmArchive => 'Confirm archiving this SKU?';

  @override
  String get skuFormConfirmUnarchive => 'Confirm unarchiving this SKU?';

  @override
  String get skuFormConfirmDelete =>
      'Confirm deleting this SKU? This cannot be undone.';

  @override
  String get inventoryAddTitle => 'Inventory Operation';

  @override
  String get inventoryTabIn => 'Stock In';

  @override
  String get inventoryTabOut => 'Stock Out';

  @override
  String get inventoryTabAdjust => 'Adjust';

  @override
  String get inventorySearchSku => 'Search SKU...';

  @override
  String get inventorySearchLocation => 'Search location...';

  @override
  String get inventoryQty => 'Quantity';

  @override
  String get inventoryNote => 'Note (optional)';

  @override
  String get inventorySubmit => 'Submit';

  @override
  String get inventorySuccess => 'Operation successful';

  @override
  String get inventoryNewSku => 'New SKU';

  @override
  String get inventoryNewLocation => 'New Location';

  @override
  String get inventorySelectSku => 'Please select a SKU';

  @override
  String get inventorySelectLocation => 'Please select a location';

  @override
  String get inventoryQtyError => 'Please enter a valid quantity';

  @override
  String get errorRetry => 'Retry';

  @override
  String operationFailed(String error) {
    return 'Operation failed: $error';
  }
}
