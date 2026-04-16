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
  String get locationScreenTitle => 'Location Management';

  @override
  String get locationSearchHint => 'Search location code / note...';

  @override
  String get locationEmpty => 'No locations';

  @override
  String locationNoResult(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get locationSearchTip => 'Try a shorter keyword or ignore case';

  @override
  String locationCount(int count) {
    return '$count locations';
  }

  @override
  String get locationNewButton => 'Add Location';

  @override
  String get locationAddInventory => 'Record Inventory';

  @override
  String get locationNewTitle => 'Add Location';

  @override
  String get locationCode => 'Location Code *';

  @override
  String get locationDescription => 'Description (optional)';

  @override
  String get locationCreate => 'Create';

  @override
  String get locationCreateFailed => 'Create failed';

  @override
  String get locationEmpty2 => 'Empty';

  @override
  String locationChecked(String date) {
    return 'Checked $date';
  }

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateDaysAgo(int days) {
    return '${days}d ago';
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

  @override
  String get saveFailed => 'Save failed';

  @override
  String get skuFormEditTitle => 'Edit SKU';

  @override
  String get skuFormNewTitle => 'New SKU';

  @override
  String get skuFormSkuCodeLabel => 'SKU Code *';

  @override
  String get skuFormProductName => 'Product Name';

  @override
  String get skuFormBarcodeLabel => 'Barcode';

  @override
  String get skuFormBarcodeAdminOnly => 'Only admin can edit barcode';

  @override
  String get skuFormViewBarcodeHistory => 'View barcode history';

  @override
  String get skuFormCartonQtyLabel => 'Pcs per box';

  @override
  String get skuFormCreateButton => 'Create';

  @override
  String get skuFormSaveButton => 'Save';

  @override
  String get barcodeHistoryTitle => 'Barcode Change History';

  @override
  String barcodeHistoryCurrent(String barcode) {
    return 'Current: $barcode';
  }

  @override
  String get barcodeHistoryEmpty => 'No barcode change history';

  @override
  String get barcodeSourceManual => 'Manual edit';

  @override
  String get barcodeSourceImport => 'Bulk import';

  @override
  String get barcodeCurrentLabel => 'Current';

  @override
  String get pwdResetTitle => 'Password Reset Requests';

  @override
  String pwdResetHandleTitle(String name) {
    return 'Handle Request — $name';
  }

  @override
  String get pwdResetInfoUsername => 'Username';

  @override
  String get pwdResetInfoTime => 'Request time';

  @override
  String get pwdResetInfoNote => 'User note';

  @override
  String get pwdResetAction => 'Action';

  @override
  String get pwdResetActionComplete => 'Reset Password';

  @override
  String get pwdResetActionReject => 'Reject';

  @override
  String get pwdResetTempPassword => 'Temporary Password * (min. 6 chars)';

  @override
  String get pwdResetForceChangeNotice =>
      'User will be forced to change this password on next login.';

  @override
  String get pwdResetRejectReason => 'Rejection reason (optional)';

  @override
  String get pwdResetNoteOptional => 'Note (optional)';

  @override
  String get pwdResetNoteHint => 'e.g. User has been notified';

  @override
  String get pwdResetPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get pwdResetOperationFailed => 'Operation failed';

  @override
  String get pwdResetConfirmComplete => 'Confirm Reset';

  @override
  String get pwdResetConfirmReject => 'Confirm Reject';

  @override
  String get pwdResetDeleteTitle => 'Delete Record';

  @override
  String pwdResetDeleteContent(String username) {
    return 'Confirm delete request from @$username?';
  }

  @override
  String get pwdResetDelete => 'Delete';

  @override
  String get pwdResetEmpty => 'No requests';

  @override
  String get pwdResetHandle => 'Handle';

  @override
  String pwdResetRequestTime(String time) {
    return 'Requested: $time';
  }

  @override
  String pwdResetResolver(String resolver) {
    return 'Handler: $resolver';
  }

  @override
  String get pwdResetStatusAll => 'All';

  @override
  String get pwdResetStatusPending => 'Pending';

  @override
  String get pwdResetStatusCompleted => 'Completed';

  @override
  String get pwdResetStatusRejected => 'Rejected';

  @override
  String get pwdResetStatusUnknown => 'Unknown';

  @override
  String get historyAllTime => 'All Time';

  @override
  String get historyLast7Days => 'Last 7 Days';

  @override
  String get historyLast30Days => 'Last 30 Days';

  @override
  String get historyCustomRange => 'Custom';

  @override
  String get historyCustomRangeTitle => 'Custom Date Range';

  @override
  String get historyStartDate => 'Start Date';

  @override
  String get historyEndDate => 'End Date';

  @override
  String get historyPleaseSelect => 'Select';

  @override
  String get historyClear => 'Clear';

  @override
  String get historyApply => 'Apply';

  @override
  String get historySearchHint => 'Search records...';

  @override
  String historyTotalRecords(int total) {
    return '$total records';
  }

  @override
  String get historyNoRecords => 'No records';

  @override
  String get historyActionTypeLabel => 'Action';

  @override
  String get historyEntityLabel => 'Entity';

  @override
  String get historyEntityLocation => 'Location';

  @override
  String get historyEntityInventory => 'Inventory';

  @override
  String get historyUserLabel => 'User';

  @override
  String get historyTimeLabel => 'Time';

  @override
  String get historyAllUsersTab => 'All Users';

  @override
  String get historyMyRecords => 'My Records';

  @override
  String get historyFilterImport => 'Import';

  @override
  String get historyFilterNew => 'New';

  @override
  String get historyFilterEntry => 'Entry';

  @override
  String get historyFilterAdjust => 'Adjust';

  @override
  String get historyFilterTransfer => 'Transfer';

  @override
  String get historyFilterCopy => 'Copy';

  @override
  String get historyFilterCheck => 'Check';

  @override
  String get historyFilterIn => 'Stock In';

  @override
  String get historyFilterOut => 'Stock Out';

  @override
  String get historyEntitySku => 'SKU';

  @override
  String get historyEntityLocationLabel => 'Location';

  @override
  String get historyEntityInventoryLabel => 'Inventory';

  @override
  String get historyPieceSuffix => 'pcs';

  @override
  String get inventoryAddManualTitle => 'Manual Inventory Entry';

  @override
  String get inventorySkuSection => 'SKU';

  @override
  String get inventoryLocationSection => 'Location';

  @override
  String get inventoryInitialStockSection => 'Initial Stock';

  @override
  String get inventoryNewSkuLabel => 'New SKU';

  @override
  String get inventorySearchExisting => 'Search existing';

  @override
  String get inventorySearchSkuHint => 'Search SKU code / name / barcode';

  @override
  String inventoryNewSkuTitle(String name) {
    return 'New \"$name\"';
  }

  @override
  String get inventorySkuNotFound => 'Not found, ';

  @override
  String get inventoryCreateNewSku => 'Click to create SKU';

  @override
  String get inventorySkuCodeLabel => 'SKU Code *';

  @override
  String get inventoryProductNameLabel => 'Product Name';

  @override
  String get inventoryBarcodeLabel => 'Barcode (optional)';

  @override
  String get inventoryNewLocationLabel => 'New Location';

  @override
  String get inventorySearchLocationHint => 'Search location code';

  @override
  String inventoryNewLocationTitle(String name) {
    return 'New \"$name\"';
  }

  @override
  String get inventoryLocationNotFound => 'Not found, ';

  @override
  String get inventoryCreateNewLocation => 'Click to create location';

  @override
  String get inventoryLocationCodeLabel => 'Location Code *';

  @override
  String get inventoryLocationDescLabel => 'Description (optional)';

  @override
  String get inventoryPendingTitle => 'Pending / To Count';

  @override
  String get inventoryPendingSubtitle =>
      'Goods arrived, quantity not yet confirmed';

  @override
  String get inventoryModeCarton => 'By carton';

  @override
  String get inventoryModeBoxOnly => 'Boxes only';

  @override
  String get inventoryModeQty => 'By total qty';

  @override
  String get inventoryBoxesLabel => 'Boxes *';

  @override
  String get inventoryBoxesSuffix => 'box(es)';

  @override
  String get inventoryUnitsLabel => 'Pcs/box *';

  @override
  String get inventoryTotalQtyLabel => 'Total qty *';

  @override
  String get inventoryTotalQtySuffix => 'pcs';

  @override
  String get inventoryNoteLabel => 'Note (optional)';

  @override
  String get inventoryAddNoteHint => 'Add note';

  @override
  String get inventoryConfirmPending => 'Confirm Pending';

  @override
  String get inventorySaveStock => 'Save Stock';

  @override
  String get inventoryStockSaved => 'Stock saved';

  @override
  String get inventorySelectOrCreate => 'Please select or create a SKU';

  @override
  String get inventorySkuCodeEmpty => 'SKU code cannot be empty';

  @override
  String get inventoryLocationCodeEmpty => 'Location code cannot be empty';

  @override
  String get inventoryValidBoxCount => 'Please enter a valid box count';

  @override
  String get inventoryValidUnits => 'Please enter pcs per box';

  @override
  String get inventoryValidQty => 'Please enter a valid quantity';

  @override
  String get inventoryTotal => 'Total';

  @override
  String inventoryBoxesTotal(int boxes) {
    return '$boxes box(es) · carton qty TBD';
  }

  @override
  String inventoryQtyTotal(int qty) {
    return 'Total $qty pcs';
  }

  @override
  String get inventoryPendingNote =>
      'Will be marked as \"Pending\", quantity excluded from official totals.';

  @override
  String get skuDetailNewLocation => 'Add Location';

  @override
  String get skuDetailLocationSection => 'Location';

  @override
  String get skuDetailNewLocationButton => '+ New Location';

  @override
  String get skuDetailSearchLocationHint => 'Search location code';

  @override
  String skuDetailNewLocationTitle(String name) {
    return 'New \"$name\"';
  }

  @override
  String get skuDetailLocationNotFound => 'Not found, click to create';

  @override
  String get skuDetailLocationCodeHint => 'Location Code *';

  @override
  String get skuDetailLocationDescHint => 'Description (optional)';

  @override
  String get skuDetailInitialStock => 'Initial Stock';

  @override
  String get skuDetailPendingTitle => 'Pending / To Count';

  @override
  String get skuDetailPendingSubtitle =>
      'Goods arrived, quantity not yet confirmed';

  @override
  String get skuDetailModeCarton => 'By carton';

  @override
  String get skuDetailModeBoxOnly => 'Boxes only';

  @override
  String get skuDetailModeQty => 'By total qty';

  @override
  String get skuDetailBoxesLabel => 'Boxes';

  @override
  String get skuDetailBoxesSuffix => 'box(es)';

  @override
  String get skuDetailUnitsLabel => 'Pcs/box';

  @override
  String get skuDetailUnitsSuffix => 'pcs/box';

  @override
  String get skuDetailBoxesOnlyHelp =>
      'Record boxes only, pcs/box can be filled in later';

  @override
  String get skuDetailTotalLabel => 'Total pcs';

  @override
  String get skuDetailTotalSuffix => 'pcs';

  @override
  String get skuDetailNoteLabel => 'Note (optional)';

  @override
  String get skuDetailCancel => 'Cancel';

  @override
  String get skuDetailCreate => 'Create';

  @override
  String get skuDetailSelectSku => 'Please select a SKU';

  @override
  String get skuDetailValidBoxes => 'Please enter valid boxes and pcs/box';

  @override
  String get skuDetailValidBoxesOnly => 'Please enter valid box count';

  @override
  String get skuDetailValidQty => 'Please enter a valid quantity';

  @override
  String get skuDetailConfirmPending => 'Confirm Pending';

  @override
  String get skuDetailSave => 'Save';

  @override
  String get skuDetailDeleteConfirmTitle => 'Confirm Delete';

  @override
  String skuDetailDeleteConfirmContent(String location, String sku) {
    return 'Delete $sku stock at $location?\nThis cannot be undone.';
  }

  @override
  String get skuDetailDelete => 'Delete';

  @override
  String skuDetailDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String skuDetailArchiveWithStockContent(String skuCode, int count) {
    return '$skuCode has $count inventory records.\n\nAfter archiving, no new stock in is allowed, but existing stock can still be viewed and shipped.\n\nConfirm archive?';
  }

  @override
  String skuDetailArchiveContent(String skuCode) {
    return 'Archive SKU $skuCode? No new stock in allowed after archiving.';
  }

  @override
  String get skuDetailArchiveTitle => 'Confirm Archive';

  @override
  String get skuDetailConfirmArchive => 'Confirm Archive';

  @override
  String skuDetailArchived(String skuCode) {
    return '$skuCode archived';
  }

  @override
  String skuDetailOperationFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get skuDetailRestoreTitle => 'Restore SKU';

  @override
  String skuDetailRestoreContent(String skuCode) {
    return 'Restore $skuCode to active status?';
  }

  @override
  String get skuDetailConfirmRestore => 'Confirm Restore';

  @override
  String skuDetailRestored(String skuCode) {
    return '$skuCode restored to active';
  }

  @override
  String get skuDetailArchivedNotice =>
      'This SKU is archived. No new stock in allowed. Existing stock can still be viewed and shipped.';

  @override
  String get skuDetailTotalStock => 'Total Stock';

  @override
  String skuDetailTotalBoxes(int boxes) {
    return '$boxes box(es)';
  }

  @override
  String skuDetailTotalQtyPieces(int qty) {
    return '$qty pcs';
  }

  @override
  String get skuDetailLocationCol => 'Location';

  @override
  String get skuDetailBoxesCol => 'Boxes';

  @override
  String get skuDetailDefaultCarton => 'Default Carton';

  @override
  String skuDetailCartonQtyDisplay(int qty) {
    return '$qty pcs/box';
  }

  @override
  String get skuDetailStockLocations => 'Stock Locations';

  @override
  String get skuDetailAddLocation => 'Add Location';

  @override
  String get skuDetailBadgePending => 'To Count';

  @override
  String get skuDetailBadgeBoxOnly => 'Boxes Only';

  @override
  String get skuDetailBadgeCarton => 'By Carton';

  @override
  String get skuDetailUnknownLocation => 'Unknown Location';

  @override
  String get skuDetailStockDelete => 'Delete';

  @override
  String skuDetailSkuStock(int total) {
    return 'Stock SKUs ($total)';
  }

  @override
  String skuDetailSkuStockShown(int shown, int total) {
    return 'Stock SKUs ($shown / $total)';
  }

  @override
  String get skuDetailTransferLabel => 'Transfer';

  @override
  String get skuDetailCopyLabel => 'Copy';

  @override
  String get skuDetailNoMatchingSku => 'No matching SKUs';

  @override
  String get skuDetailClearFilter => 'Clear filter';

  @override
  String get skuDetailFilterStock => 'Stock:';

  @override
  String get skuDetailFilterBusiness => 'Status:';

  @override
  String get skuDetailFilterAll => 'All';

  @override
  String get skuDetailFilterHasStock => 'Has stock';

  @override
  String get skuDetailFilterZeroStock => 'Zero stock';

  @override
  String get skuDetailFilterNormal => 'Normal';

  @override
  String get skuDetailFilterPending => 'Pending';

  @override
  String get skuDetailChecked => 'Checked';

  @override
  String get skuDetailLastCheck => 'Last check';

  @override
  String get skuDetailNoCheckRecord => 'No check record';

  @override
  String get skuDetailLastChange => 'Last change';

  @override
  String get skuDetailNoChangeRecord => 'No change record';

  @override
  String get skuDetailTotalBoxesLabel => 'Total Boxes';

  @override
  String get skuDetailTotalPiecesLabel => 'Total Pcs';

  @override
  String skuDetailChangeRecords(String locationCode) {
    return '$locationCode Change Records';
  }

  @override
  String skuDetailLoadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String get skuDetailNoChangeRecords => 'No change records';

  @override
  String skuDetailViewAllRecords(int total) {
    return 'View all $total records';
  }

  @override
  String get skuDetailViewHistoryPage => 'View in history page';

  @override
  String get skuDetailNoSkuHere => 'No SKUs at this location';

  @override
  String skuDetailCheckInventory(String code) {
    return 'Check if $code has inventory recorded,\nor contact admin to verify data';
  }

  @override
  String get skuDetailCreateSkuError => 'Please enter a SKU code';

  @override
  String skuDetailCreateFailed(String error) {
    return 'Create failed: $error';
  }

  @override
  String get skuDetailPendingMarkTitle => 'Mark as Pending / To Count';

  @override
  String get skuDetailPendingMarkSubtitle1 =>
      'This record will be in pending category, actual qty can be filled in';

  @override
  String get skuDetailPendingMarkSubtitle2 =>
      'After checking, record goes to pending, qty still entered normally';

  @override
  String get skuDetailNewSkuCode => 'SKU Code *';

  @override
  String get skuDetailNewSkuName => 'SKU Name (optional)';

  @override
  String skuDetailEmptyFilterMsg(String parts) {
    return 'No SKUs under filter \"$parts\"';
  }

  @override
  String get skuDetailNoInventory => 'No inventory SKUs';

  @override
  String get skuDetailQtyLinePending => 'Qty to be filled in';

  @override
  String skuDetailQtyLineBoxes(int boxes) {
    return '$boxes box(es) · carton qty TBD';
  }

  @override
  String skuDetailQtyLineCarton(int boxes, int qty) {
    return '$boxes box(es) · $qty pcs';
  }

  @override
  String skuDetailSelectedSkus(int count) {
    return '$count SKUs selected, choose target location';
  }

  @override
  String get skuDetailTargetLocationHint => 'Enter location code...';

  @override
  String get skuDetailEnterCodeToSearch => 'Enter location code to search';

  @override
  String get skuDetailLoadTargetFailed => 'Failed to load target location';

  @override
  String skuDetailCreateLocationFailed(String error) {
    return 'Create location failed: $error';
  }

  @override
  String skuDetailNewAndTransfer(String code, String action) {
    return 'Create \"$code\" and $action here';
  }

  @override
  String skuDetailSelectedSkuCount(int count) {
    return '$count SKUs';
  }

  @override
  String skuDetailConflictMsg(int count) {
    return 'Target location has $count conflicting SKUs, choose how to handle:';
  }

  @override
  String get skuDetailMerge => 'Merge';

  @override
  String get skuDetailMergeDesc =>
      'Merge source stock into existing target stock';

  @override
  String get skuDetailOverwrite => 'Overwrite';

  @override
  String get skuDetailOverwriteDesc => 'Replace target stock with source stock';

  @override
  String get skuDetailStack => 'Stack';

  @override
  String get skuDetailStackDesc =>
      'Add source stock on top of existing target stock';

  @override
  String skuDetailNoConflict(int count, String action) {
    return 'No conflict SKUs ($count, will be $action directly):';
  }

  @override
  String get skuDetailTransferDeleteNotice =>
      'After transfer, source location\'s corresponding SKU stock will be deleted.';

  @override
  String skuDetailTransferFailed(String action, String error) {
    return '$action failed: $error';
  }

  @override
  String skuDetailBulkTitle(String action) {
    return 'Bulk $action Stock';
  }

  @override
  String skuDetailBulkSelectHint(String action, String code) {
    return 'Select SKUs to $action (from: $code)';
  }

  @override
  String skuDetailSkuCountSuffix(int count) {
    return '$count SKUs · ';
  }

  @override
  String skuDetailSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get skuDetailDeselectAll => 'Deselect All';

  @override
  String get skuDetailSelectAll => 'Select All';

  @override
  String get skuDetailReturn => 'Back';

  @override
  String skuDetailConfirmActionCount(String action, int count) {
    return 'Confirm $action $count';
  }

  @override
  String get skuDetailNextStep => 'Next';

  @override
  String skuDetailNextStepWithCount(int count) {
    return 'Next ($count selected)';
  }

  @override
  String skuDetailConfirmAction(String action) {
    return 'Confirm $action';
  }

  @override
  String skuDetailRouteLabel(String src, String dst, int total) {
    return '$src → $dst, $total SKUs';
  }

  @override
  String skuDetailDirectAction(String action) {
    return 'Direct $action';
  }

  @override
  String skuDetailResultSection(String title, int count) {
    return '$title ($count)';
  }

  @override
  String skuDetailTransferDone(String action) {
    return '$action Complete';
  }

  @override
  String get importTitle => 'Bulk Import';

  @override
  String get importSelectType => 'Select Import Type';

  @override
  String get importRecordsTab => 'Records';

  @override
  String get importHistoryTab => 'Import History';

  @override
  String get importHistoryTitle => 'Import History';

  @override
  String get importSkuMasterLabel => 'SKU Master Import';

  @override
  String get importSkuMasterSubtitle => 'Bulk add or update SKU master data';

  @override
  String get importLocationMasterLabel => 'Location Master Import';

  @override
  String get importLocationMasterSubtitle => 'Bulk add or update locations';

  @override
  String get importInventoryLabel => 'Inventory Import';

  @override
  String get importInventorySubtitle =>
      'Bulk record inventory (SKU and location must exist)';

  @override
  String get importSkuBarcodeLabel => 'SKU Barcode Bulk Update';

  @override
  String get importSkuBarcodeSubtitle =>
      'Update barcode field for existing SKUs only';

  @override
  String get importSkuCartonLabel => 'SKU Carton Qty Bulk Update';

  @override
  String get importSkuCartonSubtitle =>
      'Update default carton qty for existing SKUs only';

  @override
  String get importTemplateColumns => 'Template columns:';

  @override
  String get importReselect => 'Reselect';

  @override
  String importConfirm(int count) {
    return 'Confirm Import ($count rows)';
  }

  @override
  String get importNoData => 'No data to import';

  @override
  String get importReimport => 'Re-import';

  @override
  String get importDownloadTemplate => 'Download Template';

  @override
  String get importValidating => 'Validating…';

  @override
  String get importImporting => 'Importing…';

  @override
  String get importSelectFile => 'Select File';

  @override
  String get importColName => 'Column';

  @override
  String get importColRequired => 'Required';

  @override
  String get importColDesc => 'Description';

  @override
  String get importReqRequired => 'Required';

  @override
  String get importReqEitherA => 'Either A';

  @override
  String get importReqEitherB => 'Either B';

  @override
  String get importReqOptional => 'Optional';

  @override
  String get importValidationOkWithErrors => 'Validation done (some errors)';

  @override
  String get importValidationAllErrors =>
      'Validation done (all rows have errors)';

  @override
  String get importValidationPassed => 'Validation passed, ready to import';

  @override
  String importFilename(String filename) {
    return 'File: $filename';
  }

  @override
  String get importStatTotal => 'Total';

  @override
  String get importStatCreate => 'To Create';

  @override
  String get importStatUpdate => 'To Update';

  @override
  String get importStatSkip => 'Skip';

  @override
  String get importStatError => 'Error';

  @override
  String get importErrorDetails => 'Error details:';

  @override
  String importRowLabel(int row) {
    return 'Row $row  ';
  }

  @override
  String importMoreErrors(int count) {
    return '… $count more errors (fix file and reselect)';
  }

  @override
  String get importPreviewData => 'Data preview:';

  @override
  String importMoreRows(int count) {
    return '… $count more rows (all will be written on confirm)';
  }

  @override
  String get importCreate => 'Create';

  @override
  String get importUpdate => 'Update';

  @override
  String get importDoneTitle => 'Import Complete';

  @override
  String get importDoneWithErrors => 'Import Complete (with some issues)';

  @override
  String get importResultTotal => 'Total';

  @override
  String get importResultCreate => 'Created';

  @override
  String get importResultUpdate => 'Updated';

  @override
  String get importResultSkip => 'Skipped';

  @override
  String get importResultError => 'Errors';

  @override
  String get importRowErrorDetails => 'Row error details:';

  @override
  String importMoreRowErrors(int count) {
    return '… $count more errors';
  }

  @override
  String get importValidationFailed =>
      'Validation failed, please check file format';

  @override
  String importValidationError(String error) {
    return 'Validation failed: $error';
  }

  @override
  String get importFailed => 'Import failed, please check file format';

  @override
  String importError(String error) {
    return 'Import failed: $error';
  }

  @override
  String importHistoryTotal(int count) {
    return '$count records';
  }

  @override
  String get importHistoryEmpty => 'No import history';

  @override
  String get importHistoryLoadMore => 'Load more';

  @override
  String importExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get importStatusSuccess => 'Success';

  @override
  String get importStatusPartial => 'Partial success';

  @override
  String get importStatusAllFailed => 'All failed';

  @override
  String get importStatusSkipped => 'Done (with skips)';

  @override
  String get importHistoryStatTotal => 'Total';

  @override
  String get importHistoryStatCreate => 'Created';

  @override
  String get importHistoryStatUpdate => 'Updated';

  @override
  String get importHistoryStatSkip => 'Skipped';

  @override
  String get importHistoryStatError => 'Errors';

  @override
  String get importHistoryRowErrors => 'Row error details:';

  @override
  String importHistoryMoreErrors(int count) {
    return '… $count more errors';
  }

  @override
  String get importExporting => 'Exporting…';

  @override
  String get importExportDetail => 'Export Excel Detail';

  @override
  String get importFilterAll => 'All';

  @override
  String get importFilterSku => 'SKU Master';

  @override
  String get importFilterLocation => 'Location Master';

  @override
  String get importFilterInventory => 'Inventory';

  @override
  String get importFilterBarcodeUpdate => 'Barcode Update';

  @override
  String get importFilterCartonUpdate => 'Carton Qty Update';

  @override
  String get importRefresh => 'Refresh';

  @override
  String historyBulkSkuCount(int total) {
    return '$total SKU types';
  }

  @override
  String get badgeActionCreate => 'New';

  @override
  String get badgeActionUpdate => 'Edit';

  @override
  String get badgeActionDelete => 'Delete';

  @override
  String get auditBasicInfo => 'Basic Info';

  @override
  String get auditActionType => 'Action Type';

  @override
  String get auditEntity => 'Entity';

  @override
  String get auditEntityId => 'Entity ID';

  @override
  String get auditOperator => 'Operator';

  @override
  String get auditTime => 'Time';

  @override
  String get auditDescription => 'Description';

  @override
  String get auditFieldChanges => 'Field Changes';

  @override
  String get auditBefore => 'Before';

  @override
  String get auditAfter => 'After';

  @override
  String get auditNone => 'None';

  @override
  String get auditStockInTitle => 'Stock In Details';

  @override
  String get auditStockOutTitle => 'Stock Out Details';

  @override
  String get auditAdjustTitle => 'Adjust Details';

  @override
  String get auditEntryTitle => 'Entry Details';

  @override
  String get auditDeleteStockTitle => 'Delete Stock Details';

  @override
  String get auditStructureTitle => 'Structure Change Details';

  @override
  String get auditTransferTitle => 'Transfer Path';

  @override
  String get auditCopyTitle => 'Copy Path';

  @override
  String get auditCheckTitle => 'Check Status';

  @override
  String get auditLocationOpTitle => 'Location Info';

  @override
  String get auditLocation => 'Location';

  @override
  String get auditSku => 'SKU';

  @override
  String auditQtyAdded(int qty) {
    return '+$qty pcs';
  }

  @override
  String auditQtyReduced(int qty) {
    return '-$qty pcs';
  }

  @override
  String auditQtyPcs(int qty) {
    return '$qty pcs';
  }

  @override
  String auditQtyBoxes(int boxes) {
    return '$boxes box(es)';
  }

  @override
  String auditQtyPcsPerBox(int qty) {
    return '$qty pcs/box';
  }

  @override
  String get auditBeforeAfterChange => 'Before / After';

  @override
  String get auditChangeLabel => 'Change';

  @override
  String get auditBeforeLabel => 'Before';

  @override
  String get auditAfterLabel => 'After';

  @override
  String get auditNoStock => 'No stock';

  @override
  String get auditNote => 'Note';

  @override
  String get auditDeletedNotice =>
      'All inventory for this SKU at this location has been deleted. This cannot be undone.';

  @override
  String get auditAdjustMode => 'Adjust mode';

  @override
  String get auditAdjustModeConfig => 'By carton';

  @override
  String get auditAdjustModeQty => 'By total qty';

  @override
  String auditFirstEntry(int qty) {
    return 'First entry · $qty pcs total';
  }

  @override
  String get auditSourceLocation => 'Source Location';

  @override
  String get auditTargetLocation => 'Target Location';

  @override
  String auditSkuTotal(int total) {
    return '$total SKU types';
  }

  @override
  String get auditAffectedDetails => 'Affected Details';

  @override
  String get auditDirectTransfer => 'Direct transfer';

  @override
  String get auditDirectTransferDesc => 'SKU not in target, written directly';

  @override
  String get auditMerged => 'Merged';

  @override
  String get auditMergedDesc =>
      'Merged with existing stock at target, stacked by carton';

  @override
  String get auditOverwritten => 'Overwritten';

  @override
  String get auditOverwrittenDesc =>
      'Replaced existing stock at target with source stock';

  @override
  String get auditImpactResult => 'Result';

  @override
  String get auditTransferDeleteNotice =>
      'After transfer, source location\'s SKU stock was deleted.\nTarget location has new or updated SKU stock.';

  @override
  String get auditDirectCopy => 'Direct copy';

  @override
  String get auditDirectCopyDesc => 'SKU not in target, written directly';

  @override
  String get auditStacked => 'Stacked';

  @override
  String get auditStackedDesc => 'Stacked on top of existing stock at target';

  @override
  String get auditCopySourceUnchanged =>
      'Source unchanged (copy does not delete source data)';

  @override
  String get auditCheckedChange => 'Status Change';

  @override
  String get auditMarkChecked => 'Unchecked → Checked';

  @override
  String get auditUnmarkChecked => 'Checked → Unchecked';

  @override
  String get auditCheckedBy => 'Checked by';

  @override
  String get auditCheckedAt => 'Checked at';

  @override
  String get auditLocationCode => 'Location Code';

  @override
  String get auditDescription2 => 'Description';

  @override
  String auditTotalSkuCount(int total) {
    return '$total SKUs';
  }

  @override
  String get auditTargetLocationChange => 'Target Location Change';

  @override
  String auditSkuTypeCount(int count) {
    return '$count SKU types';
  }

  @override
  String auditGroupTitle(String title, int count) {
    return '$title ($count types)';
  }

  @override
  String auditQtyPcsBold(int qty) {
    return '$qty pcs';
  }

  @override
  String get auditBusinessActionStockIn => 'Stock In';

  @override
  String get auditBusinessActionStockOut => 'Stock Out';

  @override
  String get auditBusinessActionAdjust => 'Adjust';

  @override
  String get auditBusinessActionEntry => 'Entry';

  @override
  String get auditBusinessActionDeleteStock => 'Delete Stock';

  @override
  String get auditBusinessActionStructure => 'Structure Change';

  @override
  String get auditBusinessActionTransfer => 'Bulk Transfer';

  @override
  String get auditBusinessActionTransferIn => 'Transfer In';

  @override
  String get auditBusinessActionCopy => 'Bulk Copy';

  @override
  String get auditBusinessActionCopyIn => 'Copy In';

  @override
  String get auditBusinessActionNewLocation => 'New Location';

  @override
  String get auditBusinessActionEditLocation => 'Edit Location';

  @override
  String get auditBusinessActionDeleteLocation => 'Delete Location';

  @override
  String get auditBusinessActionMarkChecked => 'Mark Checked';

  @override
  String get auditBusinessActionUnmarkChecked => 'Unmark Checked';

  @override
  String get auditBusinessActionNewSku => 'New SKU';

  @override
  String get auditBusinessActionEditSku => 'Edit SKU';

  @override
  String get auditBusinessActionDeleteSku => 'Delete SKU';

  @override
  String skuDetailInitialPreviewCarton(int boxes, int units, int qty) {
    return 'Initial: $boxes box × $units pcs/box = $qty pcs';
  }

  @override
  String skuDetailInitialPreviewBoxOnly(int qty) {
    return 'Initial: $qty box(es) (pcs/box TBD)';
  }

  @override
  String skuDetailInitialPreviewQty(int qty) {
    return 'Initial: $qty pcs';
  }

  @override
  String get locDetailAddSkuTitle => 'Add SKU';

  @override
  String get locDetailEditStock => 'Edit Inventory';

  @override
  String get locDetailReselectSku => 'Reselect';

  @override
  String get locDetailSearchSkuHint => 'Search code / name / barcode';

  @override
  String get locDetailNewSkuButton => '+ New SKU';

  @override
  String get locDetailOperationFailedRetry => 'Operation failed, please retry';

  @override
  String get locDetailParamError =>
      'Invalid parameters, please check your input';

  @override
  String locDetailTotalPcs(int qty) {
    return 'Total $qty pcs';
  }

  @override
  String locDetailConfigCarton(int boxes, int units) {
    return '$boxes box × $units pcs/box';
  }

  @override
  String get errPermissionDenied => 'Permission denied';

  @override
  String get errSessionExpired => 'Session expired, please log in again';

  @override
  String get errResourceNotFound =>
      'Resource not found, please refresh and retry';

  @override
  String errRequestFailed(int code) {
    return 'Request failed ($code), please retry';
  }

  @override
  String get errCannotConnectServer =>
      'Cannot connect to server, please check your network';

  @override
  String get errNetworkFailed => 'Network request failed, please retry';

  @override
  String get errOperationFailed => 'Operation failed, please retry';

  @override
  String get invDetailQtyUnknown => 'Qty not filled';

  @override
  String get invDetailBoxesSuffix => 'box(es)';

  @override
  String get invDetailPieceSuffix => 'pcs';

  @override
  String get invDetailUnitsPerBoxSuffix => 'pcs/box';

  @override
  String get invDetailCurrentStatusPending => 'Current status: To Count';

  @override
  String invDetailCurrentStock(String label) {
    return 'Current stock: $label';
  }

  @override
  String get invDetailModeByCarton => 'By carton';

  @override
  String get invDetailModeBoxesOnly => 'Boxes only';

  @override
  String get invDetailModeByQty => 'By total qty';

  @override
  String get invDetailBoxesLabel => 'Boxes *';

  @override
  String get invDetailPendingBoxes => 'Pending boxes: ';

  @override
  String get invDetailStockInBoxes => 'Stock in boxes: ';

  @override
  String invDetailBoxesValue(int boxes) {
    return '$boxes box(es)';
  }

  @override
  String get invDetailCartonTBD => '  · Carton qty TBD';

  @override
  String get invDetailStockInTotal => 'Stock in total: ';

  @override
  String invDetailAddQty(int qty) {
    return '+ $qty pcs';
  }

  @override
  String invDetailNewTotal(int total) {
    return '  →  $total pcs';
  }

  @override
  String get invDetailStockInQtyLabel => 'Stock in qty *';

  @override
  String get invDetailPendingMarkNote =>
      'Will mark this inventory as \"To Count\". Current qty unchanged. Update qty later via \"Adjust\".';

  @override
  String get invDetailErrInvalidBoxes => 'Please enter a valid box count';

  @override
  String get invDetailErrInvalidBoxesAndUnits =>
      'Please enter valid boxes and pcs/box';

  @override
  String get invDetailErrInvalidQty => 'Please enter a valid qty';

  @override
  String get invDetailConfirmPendingBtn => 'Confirm Pending';

  @override
  String get invDetailConfirmStockIn => 'Confirm Stock In';

  @override
  String get invDetailStockInTitle => 'Stock In';

  @override
  String get invDetailStockOutTitle => 'Stock Out';

  @override
  String get invDetailOutTotal => 'Stock out total: ';

  @override
  String invDetailOutBoxesValue(int boxes) {
    return '$boxes box(es)';
  }

  @override
  String invDetailOutPcsValue(int qty) {
    return '$qty pcs';
  }

  @override
  String invDetailRemainCartonBoxes(int boxes) {
    return '  →  $boxes box(es) remaining';
  }

  @override
  String invDetailRemainBoxes(int boxes) {
    return '  →  $boxes box(es) remaining';
  }

  @override
  String invDetailRemainPcs(int qty) {
    return '  →  $qty pcs remaining';
  }

  @override
  String get invDetailNoCartonData => 'No carton data, please use another mode';

  @override
  String get invDetailSelectOutBoxes => 'Select qty to ship:';

  @override
  String invDetailUnitsPerBoxDisplay(int units) {
    return '$units pcs/box';
  }

  @override
  String invDetailTotalBoxesDisplay(int boxes) {
    return '$boxes boxes total';
  }

  @override
  String invDetailOutMaxBoxes(int boxes) {
    return 'Out (max $boxes boxes)';
  }

  @override
  String invDetailExceedBoxes(int boxes) {
    return 'Exceeds available $boxes boxes';
  }

  @override
  String invDetailEqPcs(int qty) {
    return '= $qty pcs';
  }

  @override
  String invDetailOutBoxesLabel(int boxes) {
    return 'Out boxes * (max $boxes)';
  }

  @override
  String get invDetailBoxesOnlyHelp =>
      'Suitable when carton qty is unknown — ship by boxes only.';

  @override
  String get invDetailOutQtyLabel => 'Stock out qty *';

  @override
  String get invDetailErrNegativeBoxes => 'Out box count cannot be negative';

  @override
  String invDetailErrExceedCartonBoxes(int units, int boxes) {
    return '$units pcs/box: exceeds available ($boxes boxes)';
  }

  @override
  String get invDetailErrAtLeastOneCarton =>
      'Please enter at least one carton qty';

  @override
  String invDetailErrExceedStockBoxes(int boxes) {
    return 'Out qty cannot exceed current stock ($boxes boxes)';
  }

  @override
  String invDetailErrExceedStockPcs(int qty) {
    return 'Out qty cannot exceed current stock ($qty pcs)';
  }

  @override
  String get invDetailConfirmStockOut => 'Confirm Stock Out';

  @override
  String get invDetailAdjustTitle => 'Adjust Inventory';

  @override
  String get invDetailAdjustedTotalLabel => 'Adjusted total qty *';

  @override
  String get invDetailAdjustQtyHelp =>
      'Suitable for: inventory variance, loss, etc. Directly correct total qty.';

  @override
  String get invDetailBoxesOnlyPanelHelp =>
      'Keep pcs/box unchanged, only edit box count for each spec:';

  @override
  String invDetailSubtotalPcs(int qty) {
    return '=$qty pcs';
  }

  @override
  String get invDetailCartonGroupsLabel => 'Carton groups (max 3):';

  @override
  String get invDetailAddCarton => 'Add carton';

  @override
  String get invDetailAddFirstCarton => 'Add first carton group';

  @override
  String get invDetailUnitsPerBoxLabel => 'Pcs/box';

  @override
  String get invDetailBoxesAdjustLabel => 'Boxes';

  @override
  String get invDetailSkuCorrectCurrent => 'Current:';

  @override
  String get invDetailSkuCorrectSelectHint => '(select below)';

  @override
  String get invDetailSkuCorrectSearch => 'Search new SKU code or name';

  @override
  String invDetailQtyRetained(String label) {
    return 'Inventory qty $label will remain unchanged';
  }

  @override
  String get invDetailAdjustModeQty => 'By qty';

  @override
  String get invDetailAdjustModeBoxesOnly => 'Boxes only';

  @override
  String get invDetailAdjustModeCarton => 'By carton';

  @override
  String get invDetailAdjustModeSkuCorrect => 'SKU Correct';

  @override
  String get invDetailReasonSkuCorrect => 'Correction reason * (required)';

  @override
  String get invDetailReasonAdjust => 'Adjust reason * (required)';

  @override
  String get invDetailReasonSkuCorrectHint =>
      'e.g. Wrong SKU entered, pending → official SKU';

  @override
  String get invDetailReasonAdjustHint =>
      'e.g. Inventory variance, loss, return restocking';

  @override
  String get invDetailErrReasonRequired => 'Reason is required (required)';

  @override
  String get invDetailErrSelectNewSku =>
      'Please select a new SKU from the dropdown';

  @override
  String get invDetailErrSameSkuNotAllowed =>
      'New and old SKU cannot be the same';

  @override
  String get invDetailErrNoInventoryId =>
      'Cannot get inventory record ID, please close and retry';

  @override
  String get invDetailErrAtLeastOneBoxesGroup =>
      'Please enter at least one box count (> 0)';

  @override
  String get invDetailErrAtLeastOneCartonGroup =>
      'At least one carton group is required';

  @override
  String get invDetailErrValidCartonGroup =>
      'Please enter valid boxes and pcs/box (both > 0)';

  @override
  String get invDetailErrValidQtyGte0 => 'Please enter a valid qty (≥ 0)';

  @override
  String get invDetailConfirmSkuCorrect => 'Confirm Correction';

  @override
  String get invDetailConfirmBoxesAdjust => 'Confirm Boxes Adjust';

  @override
  String get invDetailConfirmAdjust => 'Confirm Adjust';

  @override
  String get invDetailAdjustedTotalRow => 'Adjusted total stock: ';

  @override
  String get invDetailBoxesLabelStar => 'Boxes *';

  @override
  String get invDetailUnitsLabelStar => 'Pcs/box *';

  @override
  String get invDetailNoteOptional => 'Note (optional)';

  @override
  String get invDetailQtyUnknownHeader => 'Qty to be filled';

  @override
  String invDetailBoxesOnlyHeader(int boxes) {
    return '$boxes boxes · carton qty TBD';
  }

  @override
  String invDetailBoxesAndPcs(int boxes, int qty) {
    return '$boxes boxes · $qty pcs';
  }

  @override
  String get invDetailStockIn => 'Stock In';

  @override
  String get invDetailStockOut => 'Stock Out';

  @override
  String get invDetailAdjust => 'Adjust';

  @override
  String get invDetailConfirmPendingLabel => 'Confirm Official';

  @override
  String get invDetailSplitPendingLabel => 'Split to Official SKUs';

  @override
  String get invDetailSkuDetail => 'SKU Details';

  @override
  String get invDetailLocDetail => 'Location Details';

  @override
  String get invDetailRecentOps => 'Recent Operations';

  @override
  String get invDetailViewAll => 'View all records';

  @override
  String get invDetailLoadFailed => 'Load failed, tap to retry';

  @override
  String get invDetailNoRecords => 'No operations yet';

  @override
  String get invDetailConfirmOfficialTitle => 'Confirm as Official Stock';

  @override
  String get invDetailPendingToOfficial => 'Pending → Official Stock';

  @override
  String get invDetailCorrectSkuCode => 'Also correct SKU code';

  @override
  String get invDetailSearchNewSku => 'Search new SKU code or name';

  @override
  String get invDetailConfirmReasonLabel => 'Reason *';

  @override
  String get invDetailConfirmReasonHint => 'Please explain the reason';

  @override
  String get invDetailErrReasonEmpty => 'Please fill in reason';

  @override
  String get invDetailErrSelectNewSkuCode =>
      'Please select a new SKU code from dropdown';

  @override
  String get invDetailConfirmedOfficial => 'Confirmed as official stock';

  @override
  String get invDetailConfirmToOfficial => 'Confirm to Official';

  @override
  String get invDetailSplitTitle => 'Split to Official SKUs';

  @override
  String invDetailSplitSource(String sku) {
    return 'Source pending: $sku';
  }

  @override
  String invDetailSplitSourceInfo(String locationCode, String sourceLabel) {
    return '$locationCode  ·  Entry mode: $sourceLabel';
  }

  @override
  String invDetailSplitTotalConserve(int amount, String unit) {
    return 'Total $amount $unit  ·  Conserve by $unit';
  }

  @override
  String get invDetailSplitBalanced => '✓ Balanced';

  @override
  String invDetailSplitProgress(int total, int original) {
    return '$total / $original allocated';
  }

  @override
  String get invDetailSplitNoSku => 'No SKU selected';

  @override
  String get invDetailSplitModeByCarton => 'By carton';

  @override
  String get invDetailSplitModeBoxesOnly => 'Boxes only';

  @override
  String get invDetailSplitModeByQty => 'By total qty';

  @override
  String get invDetailSplitSearchSku => 'Search SKU';

  @override
  String get invDetailSplitBoxesLabel => 'Boxes';

  @override
  String get invDetailSplitBoxesSuffix => 'box(es)';

  @override
  String get invDetailSplitUnitsLabel => 'Pcs/box';

  @override
  String get invDetailSplitUnitsSuffix => 'pcs/box';

  @override
  String get invDetailSplitCartonTBD => '· Carton qty TBD';

  @override
  String get invDetailSplitTotalQtyLabel => 'Total qty';

  @override
  String get invDetailSplitTotalQtySuffix => 'pcs';

  @override
  String invDetailSplitCalcPcs(int qty) {
    return '= $qty pcs';
  }

  @override
  String get invDetailAddSplitTarget => 'Add split target';

  @override
  String get invDetailSplitReasonLabel => 'Split reason *';

  @override
  String get invDetailSplitReasonHint =>
      'Please explain the reason for splitting';

  @override
  String get invDetailErrSplitReasonEmpty => 'Please fill in split reason';

  @override
  String invDetailErrSplitSelectSku(int index) {
    return 'Entry $index: please select SKU from dropdown';
  }

  @override
  String invDetailErrSplitBoxesMustBePositive(int index) {
    return 'Entry $index: boxes must be > 0';
  }

  @override
  String invDetailErrSplitUnitsMustBePositive(int index) {
    return 'Entry $index: pcs/box must be > 0';
  }

  @override
  String invDetailErrSplitTotalQtyMustBePositive(int index) {
    return 'Entry $index: total qty must be > 0';
  }

  @override
  String invDetailErrSplitUnbalanced(int total, int original, String unit) {
    return 'Split total $total $unit ≠ source $original $unit, please adjust';
  }

  @override
  String get invDetailSplitSuccess => 'Split successful, official SKUs created';

  @override
  String get invDetailConfirmSplit => 'Confirm Split';

  @override
  String get invDetailSourceModeBoxesOnly => 'Boxes only';

  @override
  String get invDetailSourceModeQty => 'By total qty';

  @override
  String get invDetailSourceModeCarton => 'By carton';

  @override
  String get invDetailMergeConfirmTitle => 'Target SKU has existing stock';

  @override
  String get invDetailMergeConfirm => 'Confirm Merge';

  @override
  String get invDetailSkuSearchHint => 'Enter code or name to search';

  @override
  String get invDetailSkuNotFound => 'No matching SKUs found';

  @override
  String get invDetailSkuArchived => 'Archived';

  @override
  String get invDetailDefaultAction => 'Action';

  @override
  String get invHistoryTitle => 'Stock In/Out Records';

  @override
  String get invHistoryEmpty => 'No stock records';

  @override
  String get invHistoryEmptyFiltered => 'No matching records';

  @override
  String get invHistoryViewAll => 'View all types';

  @override
  String get invHistorySplitSrc => 'Source';

  @override
  String get invHistorySplitTargets => 'Split Targets';

  @override
  String get invHistorySplitCleared => 'Source cleared (split complete)';

  @override
  String get invHistoryReason => 'Reason';

  @override
  String get errApiNotFound => 'API not found, contact admin';

  @override
  String get errPermission => 'No permission to view';

  @override
  String get errLoadRetry => 'Load failed, please retry';

  @override
  String get userMgmtTitle => 'User Management';

  @override
  String get userMgmtCreateBtn => 'Create Account';

  @override
  String get userMgmtCreateTitle => 'Create Account';

  @override
  String get userMgmtUsernameLabel => 'Username';

  @override
  String get userMgmtDisplayNameLabel => 'Display Name';

  @override
  String get userMgmtInitPasswordLabel => 'Initial Password (min. 6 chars)';

  @override
  String get userMgmtRoleLabel => 'Role';

  @override
  String get userMgmtRoleAdmin => 'Admin';

  @override
  String get userMgmtRoleSupervisor => 'Supervisor';

  @override
  String get userMgmtRoleStaff => 'Staff';

  @override
  String get userMgmtCreateValidation =>
      'Please fill all fields, password min. 6 chars';

  @override
  String get userMgmtCreateFailed => 'Create failed';

  @override
  String get userMgmtEditRoleTitle => 'Change Role';

  @override
  String userMgmtLoadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String get userMgmtMe => 'Me';

  @override
  String get userMgmtDisabled => 'Disabled';

  @override
  String userMgmtToggleTitle(String action) {
    return 'Confirm $action';
  }

  @override
  String userMgmtToggleContent(String action, String notice) {
    return 'Are you sure to $action this account?$notice';
  }

  @override
  String get userMgmtDisableNotice =>
      ' After disabling, this user cannot log in.';

  @override
  String get userMgmtEnable => 'enable';

  @override
  String get userMgmtDisable => 'disable';

  @override
  String get userMgmtResetPasswordTitle => 'Reset Password';

  @override
  String get userMgmtNewPasswordLabel => 'New Password (min. 6 chars)';

  @override
  String get userMgmtPasswordTooShort => 'Password must be at least 6 chars';

  @override
  String get userMgmtPasswordReset => 'Password reset';

  @override
  String get userMgmtResetFailed => 'Reset failed';

  @override
  String get userMgmtResetBtn => 'Reset';

  @override
  String get userMgmtOperationFailed => 'Operation failed';

  @override
  String clearDoneMsg(
      Object inv, Object sku, Object loc, Object tx, Object log, Object imp) {
    return 'Cleared: inventory $inv, SKU $sku, location $loc, transactions $tx, logs $log, imports $imp';
  }
}
