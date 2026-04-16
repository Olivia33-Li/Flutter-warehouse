import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'仓库管理系统'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @continue_.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continue_;

  /// No description provided for @loginUsername.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get loginUsername;

  /// No description provided for @loginPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get loginPassword;

  /// No description provided for @loginRememberMe.
  ///
  /// In zh, this message translates to:
  /// **'记住我'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In zh, this message translates to:
  /// **'忘记密码？'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In zh, this message translates to:
  /// **'还没有账号？'**
  String get loginNoAccount;

  /// No description provided for @loginRegister.
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get loginRegister;

  /// No description provided for @loginEmptyError.
  ///
  /// In zh, this message translates to:
  /// **'请输入用户名和密码'**
  String get loginEmptyError;

  /// No description provided for @loginFailedNetwork.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请检查网络'**
  String get loginFailedNetwork;

  /// No description provided for @loginRecentTitle.
  ///
  /// In zh, this message translates to:
  /// **'最近登录'**
  String get loginRecentTitle;

  /// No description provided for @loginClearAll.
  ///
  /// In zh, this message translates to:
  /// **'清除全部'**
  String get loginClearAll;

  /// No description provided for @loginClearAllTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空记录'**
  String get loginClearAllTitle;

  /// No description provided for @loginClearAllContent.
  ///
  /// In zh, this message translates to:
  /// **'确定清除本设备所有已记住的账号？'**
  String get loginClearAllContent;

  /// No description provided for @loginUseOtherAccount.
  ///
  /// In zh, this message translates to:
  /// **'使用其他账号登录'**
  String get loginUseOtherAccount;

  /// No description provided for @registerTitle.
  ///
  /// In zh, this message translates to:
  /// **'注册账号'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'创建账号后即可使用仓库管理系统'**
  String get registerSubtitle;

  /// No description provided for @registerName.
  ///
  /// In zh, this message translates to:
  /// **'姓名 / 显示名'**
  String get registerName;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get registerConfirmPassword;

  /// No description provided for @registerButton.
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已有账号？'**
  String get registerHaveAccount;

  /// No description provided for @registerValidation.
  ///
  /// In zh, this message translates to:
  /// **'请填写完整信息，密码至少6位'**
  String get registerValidation;

  /// No description provided for @registerPasswordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入的密码不一致'**
  String get registerPasswordMismatch;

  /// No description provided for @registerFailed.
  ///
  /// In zh, this message translates to:
  /// **'注册失败'**
  String get registerFailed;

  /// No description provided for @passwordRuleLength.
  ///
  /// In zh, this message translates to:
  /// **'6–20 位字符'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleLowercase.
  ///
  /// In zh, this message translates to:
  /// **'包含小写字母'**
  String get passwordRuleLowercase;

  /// No description provided for @passwordRuleDigit.
  ///
  /// In zh, this message translates to:
  /// **'包含数字'**
  String get passwordRuleDigit;

  /// No description provided for @passwordRuleAlnum.
  ///
  /// In zh, this message translates to:
  /// **'仅限小写字母和数字'**
  String get passwordRuleAlnum;

  /// No description provided for @forgotTitle.
  ///
  /// In zh, this message translates to:
  /// **'忘记密码'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'请联系管理员重置您的账号密码。\n填写用户名后提交申请，管理员会尽快处理。'**
  String get forgotSubtitle;

  /// No description provided for @forgotAdminContact.
  ///
  /// In zh, this message translates to:
  /// **'联系管理员'**
  String get forgotAdminContact;

  /// No description provided for @forgotAdminDesc.
  ///
  /// In zh, this message translates to:
  /// **'仓库管理系统的密码由管理员统一管理。请联系您的仓库主管或系统管理员，告知您的用户名，由管理员为您重置密码。'**
  String get forgotAdminDesc;

  /// No description provided for @forgotNote.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）—— 如：联系方式 / 具体情况'**
  String get forgotNote;

  /// No description provided for @forgotSubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交申请'**
  String get forgotSubmit;

  /// No description provided for @forgotDismiss.
  ///
  /// In zh, this message translates to:
  /// **'我知道了'**
  String get forgotDismiss;

  /// No description provided for @forgotSuccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'申请已提交'**
  String get forgotSuccessTitle;

  /// No description provided for @forgotSuccessDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理员收到您的申请后将重置密码\n并告知您临时密码，请耐心等待。'**
  String get forgotSuccessDesc;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In zh, this message translates to:
  /// **'返回登录'**
  String get forgotBackToLogin;

  /// No description provided for @forgotEmptyError.
  ///
  /// In zh, this message translates to:
  /// **'请输入您的用户名'**
  String get forgotEmptyError;

  /// No description provided for @forgotSubmitFailed.
  ///
  /// In zh, this message translates to:
  /// **'提交失败，请重试'**
  String get forgotSubmitFailed;

  /// No description provided for @forceChangeTitle.
  ///
  /// In zh, this message translates to:
  /// **'请修改密码'**
  String get forceChangeTitle;

  /// No description provided for @forceChangeNotice.
  ///
  /// In zh, this message translates to:
  /// **'管理员已重置您的密码。请先修改密码后再继续使用系统。'**
  String get forceChangeNotice;

  /// No description provided for @forceChangeOldPassword.
  ///
  /// In zh, this message translates to:
  /// **'当前密码（临时密码）'**
  String get forceChangeOldPassword;

  /// No description provided for @forceChangeNewPassword.
  ///
  /// In zh, this message translates to:
  /// **'新密码（至少 6 位）'**
  String get forceChangeNewPassword;

  /// No description provided for @forceChangeConfirmPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认新密码'**
  String get forceChangeConfirmPassword;

  /// No description provided for @forceChangeButton.
  ///
  /// In zh, this message translates to:
  /// **'确认修改'**
  String get forceChangeButton;

  /// No description provided for @forceChangeEmptyError.
  ///
  /// In zh, this message translates to:
  /// **'请填写所有字段'**
  String get forceChangeEmptyError;

  /// No description provided for @forceChangeShortError.
  ///
  /// In zh, this message translates to:
  /// **'新密码至少需要 6 位'**
  String get forceChangeShortError;

  /// No description provided for @forceChangeMismatchError.
  ///
  /// In zh, this message translates to:
  /// **'两次输入的新密码不一致'**
  String get forceChangeMismatchError;

  /// No description provided for @forceChangeSameError.
  ///
  /// In zh, this message translates to:
  /// **'新密码不能与当前密码相同'**
  String get forceChangeSameError;

  /// No description provided for @forceChangeFailed.
  ///
  /// In zh, this message translates to:
  /// **'修改失败，请重试'**
  String get forceChangeFailed;

  /// No description provided for @navSku.
  ///
  /// In zh, this message translates to:
  /// **'SKU'**
  String get navSku;

  /// No description provided for @navLocation.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get navLocation;

  /// No description provided for @navScanner.
  ///
  /// In zh, this message translates to:
  /// **'扫码'**
  String get navScanner;

  /// No description provided for @navHistory.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @skuScreenTitle.
  ///
  /// In zh, this message translates to:
  /// **'SKU 搜索'**
  String get skuScreenTitle;

  /// No description provided for @skuSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索 SKU / 名称 / 条码...'**
  String get skuSearchHint;

  /// No description provided for @skuFilterActive.
  ///
  /// In zh, this message translates to:
  /// **'在用'**
  String get skuFilterActive;

  /// No description provided for @skuFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'含已归档'**
  String get skuFilterAll;

  /// No description provided for @skuFilterArchived.
  ///
  /// In zh, this message translates to:
  /// **'仅归档'**
  String get skuFilterArchived;

  /// No description provided for @skuEmptyArchived.
  ///
  /// In zh, this message translates to:
  /// **'暂无归档 SKU'**
  String get skuEmptyArchived;

  /// No description provided for @skuEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无 SKU'**
  String get skuEmpty;

  /// No description provided for @skuNoResult.
  ///
  /// In zh, this message translates to:
  /// **'未找到 \"{query}\"'**
  String skuNoResult(String query);

  /// No description provided for @skuSearchTip.
  ///
  /// In zh, this message translates to:
  /// **'尝试缩短关键词，或忽略分隔符搜索'**
  String get skuSearchTip;

  /// No description provided for @skuNoStock.
  ///
  /// In zh, this message translates to:
  /// **'暂无库存'**
  String get skuNoStock;

  /// No description provided for @unitBox.
  ///
  /// In zh, this message translates to:
  /// **'箱'**
  String get unitBox;

  /// No description provided for @unitPiece.
  ///
  /// In zh, this message translates to:
  /// **'件'**
  String get unitPiece;

  /// No description provided for @skuTotalQty.
  ///
  /// In zh, this message translates to:
  /// **'共 {qty} {unit}'**
  String skuTotalQty(int qty, String unit);

  /// No description provided for @locationScreenTitle.
  ///
  /// In zh, this message translates to:
  /// **'库位搜索'**
  String get locationScreenTitle;

  /// No description provided for @locationSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索库位编号或描述...'**
  String get locationSearchHint;

  /// No description provided for @locationEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无库位'**
  String get locationEmpty;

  /// No description provided for @locationNoResult.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配库位'**
  String get locationNoResult;

  /// No description provided for @locationNewButton.
  ///
  /// In zh, this message translates to:
  /// **'新建库位'**
  String get locationNewButton;

  /// No description provided for @locationNoStock.
  ///
  /// In zh, this message translates to:
  /// **'暂无库存'**
  String get locationNoStock;

  /// No description provided for @locationTotalQty.
  ///
  /// In zh, this message translates to:
  /// **'共 {qty} 件'**
  String locationTotalQty(int qty);

  /// No description provided for @scannerTitle.
  ///
  /// In zh, this message translates to:
  /// **'扫码查询'**
  String get scannerTitle;

  /// No description provided for @scannerHint.
  ///
  /// In zh, this message translates to:
  /// **'将条码/二维码对准框内'**
  String get scannerHint;

  /// No description provided for @scannerViewDetail.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get scannerViewDetail;

  /// No description provided for @scannerStockLocations.
  ///
  /// In zh, this message translates to:
  /// **'库存位置:'**
  String get scannerStockLocations;

  /// No description provided for @scannerOutOfStock.
  ///
  /// In zh, this message translates to:
  /// **'该商品已断货'**
  String get scannerOutOfStock;

  /// No description provided for @scannerAllZero.
  ///
  /// In zh, this message translates to:
  /// **'所有位置库存为 0'**
  String get scannerAllZero;

  /// No description provided for @scannerRestock.
  ///
  /// In zh, this message translates to:
  /// **'去补货'**
  String get scannerRestock;

  /// No description provided for @scannerContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续扫码'**
  String get scannerContinue;

  /// No description provided for @scannerNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到该商品'**
  String get scannerNotFound;

  /// No description provided for @scannerBarcode.
  ///
  /// In zh, this message translates to:
  /// **'条码: {code}'**
  String scannerBarcode(String code);

  /// No description provided for @scannerAddProduct.
  ///
  /// In zh, this message translates to:
  /// **'新增商品'**
  String get scannerAddProduct;

  /// No description provided for @scannerMultipleFound.
  ///
  /// In zh, this message translates to:
  /// **'找到多个匹配'**
  String get scannerMultipleFound;

  /// No description provided for @scannerTotalStock.
  ///
  /// In zh, this message translates to:
  /// **'总库存: {qty} 箱'**
  String scannerTotalStock(int qty);

  /// No description provided for @scannerQtyPiece.
  ///
  /// In zh, this message translates to:
  /// **'{qty} 件'**
  String scannerQtyPiece(int qty);

  /// No description provided for @historyTitle.
  ///
  /// In zh, this message translates to:
  /// **'操作记录'**
  String get historyTitle;

  /// No description provided for @historyAllUsers.
  ///
  /// In zh, this message translates to:
  /// **'全部用户'**
  String get historyAllUsers;

  /// No description provided for @historyEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无记录'**
  String get historyEmpty;

  /// No description provided for @historyFilterDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get historyFilterDate;

  /// No description provided for @historyFilterAction.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get historyFilterAction;

  /// No description provided for @historyFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get historyFilterAll;

  /// No description provided for @historyToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get historyToday;

  /// No description provided for @historyThisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get historyThisWeek;

  /// No description provided for @historyThisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get historyThisMonth;

  /// No description provided for @historyCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get historyCustom;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsEditProfile.
  ///
  /// In zh, this message translates to:
  /// **'编辑个人信息'**
  String get settingsEditProfile;

  /// No description provided for @settingsDisplayName.
  ///
  /// In zh, this message translates to:
  /// **'显示名称'**
  String get settingsDisplayName;

  /// No description provided for @settingsNameEmpty.
  ///
  /// In zh, this message translates to:
  /// **'名称不能为空'**
  String get settingsNameEmpty;

  /// No description provided for @settingsProfileUpdated.
  ///
  /// In zh, this message translates to:
  /// **'个人信息已更新'**
  String get settingsProfileUpdated;

  /// No description provided for @settingsUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新失败'**
  String get settingsUpdateFailed;

  /// No description provided for @settingsChangePassword.
  ///
  /// In zh, this message translates to:
  /// **'修改密码'**
  String get settingsChangePassword;

  /// No description provided for @settingsOldPassword.
  ///
  /// In zh, this message translates to:
  /// **'原密码'**
  String get settingsOldPassword;

  /// No description provided for @settingsNewPassword.
  ///
  /// In zh, this message translates to:
  /// **'新密码（至少6位）'**
  String get settingsNewPassword;

  /// No description provided for @settingsPasswordChanged.
  ///
  /// In zh, this message translates to:
  /// **'密码修改成功'**
  String get settingsPasswordChanged;

  /// No description provided for @settingsPasswordChangeFailed.
  ///
  /// In zh, this message translates to:
  /// **'修改失败'**
  String get settingsPasswordChangeFailed;

  /// No description provided for @settingsSwitchAccount.
  ///
  /// In zh, this message translates to:
  /// **'切换账号'**
  String get settingsSwitchAccount;

  /// No description provided for @settingsSwitchAccountSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'退出当前账号并返回登录页'**
  String get settingsSwitchAccountSubtitle;

  /// No description provided for @settingsSectionManage.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get settingsSectionManage;

  /// No description provided for @settingsUserManagement.
  ///
  /// In zh, this message translates to:
  /// **'用户管理'**
  String get settingsUserManagement;

  /// No description provided for @settingsUserManagementSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'创建账号 / 分配角色 / 停用账号'**
  String get settingsUserManagementSubtitle;

  /// No description provided for @settingsPasswordResetRequests.
  ///
  /// In zh, this message translates to:
  /// **'密码重置申请'**
  String get settingsPasswordResetRequests;

  /// No description provided for @settingsPasswordResetRequestsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'处理用户的忘记密码申请'**
  String get settingsPasswordResetRequestsSubtitle;

  /// No description provided for @settingsSectionData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get settingsSectionData;

  /// No description provided for @settingsDataImport.
  ///
  /// In zh, this message translates to:
  /// **'数据导入'**
  String get settingsDataImport;

  /// No description provided for @settingsDataImportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'SKU 主档 / 库位主档 / 库存明细'**
  String get settingsDataImportSubtitle;

  /// No description provided for @settingsExportExcel.
  ///
  /// In zh, this message translates to:
  /// **'导出 Excel'**
  String get settingsExportExcel;

  /// No description provided for @settingsExportExcelSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'导出全部 SKU、库位、库存及流水记录'**
  String get settingsExportExcelSubtitle;

  /// No description provided for @settingsExporting.
  ///
  /// In zh, this message translates to:
  /// **'正在生成 Excel，请稍候...'**
  String get settingsExporting;

  /// No description provided for @settingsExportDone.
  ///
  /// In zh, this message translates to:
  /// **'已下载: {filename}'**
  String settingsExportDone(String filename);

  /// No description provided for @settingsSectionDanger.
  ///
  /// In zh, this message translates to:
  /// **'危险区域'**
  String get settingsSectionDanger;

  /// No description provided for @settingsClearAllData.
  ///
  /// In zh, this message translates to:
  /// **'清空所有业务数据'**
  String get settingsClearAllData;

  /// No description provided for @settingsClearAllDataSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'清空库存、SKU、库位、流水、日志及导入记录，仅保留用户账号'**
  String get settingsClearAllDataSubtitle;

  /// No description provided for @settingsClearDataTitle.
  ///
  /// In zh, this message translates to:
  /// **'危险操作'**
  String get settingsClearDataTitle;

  /// No description provided for @settingsClearDataContent.
  ///
  /// In zh, this message translates to:
  /// **'此操作将清空以下所有数据：\n\n• 全部库存记录\n• 全部 SKU 主档\n• 全部库位主档\n• 全部出入库流水\n• 全部操作日志\n• 全部导入记录\n\n仅保留用户账号。\n\n此操作不可恢复！'**
  String get settingsClearDataContent;

  /// No description provided for @settingsSecondConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'二次确认'**
  String get settingsSecondConfirmTitle;

  /// No description provided for @settingsSecondConfirmContent.
  ///
  /// In zh, this message translates to:
  /// **'请输入【清空数据】以确认操作：'**
  String get settingsSecondConfirmContent;

  /// No description provided for @settingsClearDataHint.
  ///
  /// In zh, this message translates to:
  /// **'清空数据'**
  String get settingsClearDataHint;

  /// No description provided for @settingsInputIncorrect.
  ///
  /// In zh, this message translates to:
  /// **'输入不正确'**
  String get settingsInputIncorrect;

  /// No description provided for @settingsConfirmClear.
  ///
  /// In zh, this message translates to:
  /// **'确认清空'**
  String get settingsConfirmClear;

  /// No description provided for @settingsLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get settingsLogout;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'切换界面显示语言'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsSectionDisplay.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get settingsSectionDisplay;

  /// No description provided for @langZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get langSystem;

  /// No description provided for @langSelectTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get langSelectTitle;

  /// No description provided for @skuFormTitle.
  ///
  /// In zh, this message translates to:
  /// **'SKU 信息'**
  String get skuFormTitle;

  /// No description provided for @skuFormSkuCode.
  ///
  /// In zh, this message translates to:
  /// **'SKU 编号'**
  String get skuFormSkuCode;

  /// No description provided for @skuFormName.
  ///
  /// In zh, this message translates to:
  /// **'名称（可选）'**
  String get skuFormName;

  /// No description provided for @skuFormBarcode.
  ///
  /// In zh, this message translates to:
  /// **'条码（可选）'**
  String get skuFormBarcode;

  /// No description provided for @skuFormCartonQty.
  ///
  /// In zh, this message translates to:
  /// **'箱规（件/箱，可选）'**
  String get skuFormCartonQty;

  /// No description provided for @skuFormSkuEmpty.
  ///
  /// In zh, this message translates to:
  /// **'SKU 编号不能为空'**
  String get skuFormSkuEmpty;

  /// No description provided for @skuFormSaveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get skuFormSaveSuccess;

  /// No description provided for @skuFormArchive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get skuFormArchive;

  /// No description provided for @skuFormUnarchive.
  ///
  /// In zh, this message translates to:
  /// **'取消归档'**
  String get skuFormUnarchive;

  /// No description provided for @skuFormDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get skuFormDelete;

  /// No description provided for @skuFormConfirmArchive.
  ///
  /// In zh, this message translates to:
  /// **'确认归档此 SKU？'**
  String get skuFormConfirmArchive;

  /// No description provided for @skuFormConfirmUnarchive.
  ///
  /// In zh, this message translates to:
  /// **'确认取消归档此 SKU？'**
  String get skuFormConfirmUnarchive;

  /// No description provided for @skuFormConfirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除此 SKU？此操作不可恢复。'**
  String get skuFormConfirmDelete;

  /// No description provided for @inventoryAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'库存操作'**
  String get inventoryAddTitle;

  /// No description provided for @inventoryTabIn.
  ///
  /// In zh, this message translates to:
  /// **'入库'**
  String get inventoryTabIn;

  /// No description provided for @inventoryTabOut.
  ///
  /// In zh, this message translates to:
  /// **'出库'**
  String get inventoryTabOut;

  /// No description provided for @inventoryTabAdjust.
  ///
  /// In zh, this message translates to:
  /// **'调整'**
  String get inventoryTabAdjust;

  /// No description provided for @inventorySearchSku.
  ///
  /// In zh, this message translates to:
  /// **'搜索 SKU...'**
  String get inventorySearchSku;

  /// No description provided for @inventorySearchLocation.
  ///
  /// In zh, this message translates to:
  /// **'搜索库位...'**
  String get inventorySearchLocation;

  /// No description provided for @inventoryQty.
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get inventoryQty;

  /// No description provided for @inventoryNote.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get inventoryNote;

  /// No description provided for @inventorySubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get inventorySubmit;

  /// No description provided for @inventorySuccess.
  ///
  /// In zh, this message translates to:
  /// **'操作成功'**
  String get inventorySuccess;

  /// No description provided for @inventoryNewSku.
  ///
  /// In zh, this message translates to:
  /// **'新建 SKU'**
  String get inventoryNewSku;

  /// No description provided for @inventoryNewLocation.
  ///
  /// In zh, this message translates to:
  /// **'新建库位'**
  String get inventoryNewLocation;

  /// No description provided for @inventorySelectSku.
  ///
  /// In zh, this message translates to:
  /// **'请选择 SKU'**
  String get inventorySelectSku;

  /// No description provided for @inventorySelectLocation.
  ///
  /// In zh, this message translates to:
  /// **'请选择库位'**
  String get inventorySelectLocation;

  /// No description provided for @inventoryQtyError.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效数量'**
  String get inventoryQtyError;

  /// No description provided for @errorRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get errorRetry;

  /// No description provided for @operationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败: {error}'**
  String operationFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
