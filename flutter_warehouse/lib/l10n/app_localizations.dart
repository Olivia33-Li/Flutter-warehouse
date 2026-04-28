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
  /// **'请填写完整信息'**
  String get registerValidation;

  /// No description provided for @registerPasswordRules.
  ///
  /// In zh, this message translates to:
  /// **'密码不符合要求'**
  String get registerPasswordRules;

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

  /// No description provided for @skuNoSpec.
  ///
  /// In zh, this message translates to:
  /// **'（无箱规）'**
  String get skuNoSpec;

  /// No description provided for @skuLoosePcs.
  ///
  /// In zh, this message translates to:
  /// **'散{qty}件'**
  String skuLoosePcs(int qty);

  /// No description provided for @locationScreenTitle.
  ///
  /// In zh, this message translates to:
  /// **'位置管理'**
  String get locationScreenTitle;

  /// No description provided for @locationSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索位置码 / 备注...'**
  String get locationSearchHint;

  /// No description provided for @locationEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无位置'**
  String get locationEmpty;

  /// No description provided for @locationNoResult.
  ///
  /// In zh, this message translates to:
  /// **'未找到 \"{query}\"'**
  String locationNoResult(String query);

  /// No description provided for @locationSearchTip.
  ///
  /// In zh, this message translates to:
  /// **'尝试缩短关键词，或忽略大小写搜索'**
  String get locationSearchTip;

  /// No description provided for @locationCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个库位'**
  String locationCount(int count);

  /// No description provided for @locationNewButton.
  ///
  /// In zh, this message translates to:
  /// **'新增位置'**
  String get locationNewButton;

  /// No description provided for @locationAddInventory.
  ///
  /// In zh, this message translates to:
  /// **'录入库存'**
  String get locationAddInventory;

  /// No description provided for @locationNewTitle.
  ///
  /// In zh, this message translates to:
  /// **'新增位置'**
  String get locationNewTitle;

  /// No description provided for @locationCode.
  ///
  /// In zh, this message translates to:
  /// **'位置代码 *'**
  String get locationCode;

  /// No description provided for @locationDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述（可选）'**
  String get locationDescription;

  /// No description provided for @locationCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get locationCreate;

  /// No description provided for @locationCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败'**
  String get locationCreateFailed;

  /// No description provided for @locationEmpty2.
  ///
  /// In zh, this message translates to:
  /// **'空位置'**
  String get locationEmpty2;

  /// No description provided for @locationChecked.
  ///
  /// In zh, this message translates to:
  /// **'检查 {date}'**
  String locationChecked(String date);

  /// No description provided for @dateToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{days}天前'**
  String dateDaysAgo(int days);

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

  /// No description provided for @settingsConfirmNewPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认新密码'**
  String get settingsConfirmNewPassword;

  /// No description provided for @settingsPasswordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次密码不一致'**
  String get settingsPasswordMismatch;

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

  /// No description provided for @saveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get saveFailed;

  /// No description provided for @skuFormEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑 SKU'**
  String get skuFormEditTitle;

  /// No description provided for @skuFormNewTitle.
  ///
  /// In zh, this message translates to:
  /// **'新增 SKU'**
  String get skuFormNewTitle;

  /// No description provided for @skuFormSkuCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'SKU 编号 *'**
  String get skuFormSkuCodeLabel;

  /// No description provided for @skuFormProductName.
  ///
  /// In zh, this message translates to:
  /// **'产品名称'**
  String get skuFormProductName;

  /// No description provided for @skuFormBarcodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'条码'**
  String get skuFormBarcodeLabel;

  /// No description provided for @skuFormBarcodeAdminOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅管理员可修改条码'**
  String get skuFormBarcodeAdminOnly;

  /// No description provided for @skuFormViewBarcodeHistory.
  ///
  /// In zh, this message translates to:
  /// **'查看条码历史'**
  String get skuFormViewBarcodeHistory;

  /// No description provided for @skuFormCartonQtyLabel.
  ///
  /// In zh, this message translates to:
  /// **'每箱个数'**
  String get skuFormCartonQtyLabel;

  /// No description provided for @skuFormCreateButton.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get skuFormCreateButton;

  /// No description provided for @skuFormSaveButton.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get skuFormSaveButton;

  /// No description provided for @barcodeHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'条码变更历史'**
  String get barcodeHistoryTitle;

  /// No description provided for @barcodeHistoryCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前: {barcode}'**
  String barcodeHistoryCurrent(String barcode);

  /// No description provided for @barcodeHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无条码变更记录'**
  String get barcodeHistoryEmpty;

  /// No description provided for @barcodeSourceManual.
  ///
  /// In zh, this message translates to:
  /// **'手动编辑'**
  String get barcodeSourceManual;

  /// No description provided for @barcodeSourceImport.
  ///
  /// In zh, this message translates to:
  /// **'批量导入'**
  String get barcodeSourceImport;

  /// No description provided for @barcodeCurrentLabel.
  ///
  /// In zh, this message translates to:
  /// **'当前'**
  String get barcodeCurrentLabel;

  /// No description provided for @pwdResetTitle.
  ///
  /// In zh, this message translates to:
  /// **'密码重置申请'**
  String get pwdResetTitle;

  /// No description provided for @pwdResetHandleTitle.
  ///
  /// In zh, this message translates to:
  /// **'处理申请 — {name}'**
  String pwdResetHandleTitle(String name);

  /// No description provided for @pwdResetInfoUsername.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get pwdResetInfoUsername;

  /// No description provided for @pwdResetInfoTime.
  ///
  /// In zh, this message translates to:
  /// **'申请时间'**
  String get pwdResetInfoTime;

  /// No description provided for @pwdResetInfoNote.
  ///
  /// In zh, this message translates to:
  /// **'用户备注'**
  String get pwdResetInfoNote;

  /// No description provided for @pwdResetAction.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get pwdResetAction;

  /// No description provided for @pwdResetActionComplete.
  ///
  /// In zh, this message translates to:
  /// **'重置密码'**
  String get pwdResetActionComplete;

  /// No description provided for @pwdResetActionReject.
  ///
  /// In zh, this message translates to:
  /// **'拒绝申请'**
  String get pwdResetActionReject;

  /// No description provided for @pwdResetTempPassword.
  ///
  /// In zh, this message translates to:
  /// **'临时密码 *（至少 6 位）'**
  String get pwdResetTempPassword;

  /// No description provided for @pwdResetForceChangeNotice.
  ///
  /// In zh, this message translates to:
  /// **'用户下次登录时将被强制修改此密码。'**
  String get pwdResetForceChangeNotice;

  /// No description provided for @pwdResetRejectReason.
  ///
  /// In zh, this message translates to:
  /// **'拒绝原因（可选）'**
  String get pwdResetRejectReason;

  /// No description provided for @pwdResetNoteOptional.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get pwdResetNoteOptional;

  /// No description provided for @pwdResetNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：已通知用户'**
  String get pwdResetNoteHint;

  /// No description provided for @pwdResetPasswordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'密码至少需要 6 位'**
  String get pwdResetPasswordTooShort;

  /// No description provided for @pwdResetOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get pwdResetOperationFailed;

  /// No description provided for @pwdResetConfirmComplete.
  ///
  /// In zh, this message translates to:
  /// **'确认重置'**
  String get pwdResetConfirmComplete;

  /// No description provided for @pwdResetConfirmReject.
  ///
  /// In zh, this message translates to:
  /// **'确认拒绝'**
  String get pwdResetConfirmReject;

  /// No description provided for @pwdResetDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除记录'**
  String get pwdResetDeleteTitle;

  /// No description provided for @pwdResetDeleteContent.
  ///
  /// In zh, this message translates to:
  /// **'确认删除 @{username} 的申请记录？'**
  String pwdResetDeleteContent(String username);

  /// No description provided for @pwdResetDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get pwdResetDelete;

  /// No description provided for @pwdResetEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无申请记录'**
  String get pwdResetEmpty;

  /// No description provided for @pwdResetHandle.
  ///
  /// In zh, this message translates to:
  /// **'处理'**
  String get pwdResetHandle;

  /// No description provided for @pwdResetRequestTime.
  ///
  /// In zh, this message translates to:
  /// **'申请时间：{time}'**
  String pwdResetRequestTime(String time);

  /// No description provided for @pwdResetResolver.
  ///
  /// In zh, this message translates to:
  /// **'处理人：{resolver}'**
  String pwdResetResolver(String resolver);

  /// No description provided for @pwdResetStatusAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get pwdResetStatusAll;

  /// No description provided for @pwdResetStatusPending.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get pwdResetStatusPending;

  /// No description provided for @pwdResetStatusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get pwdResetStatusCompleted;

  /// No description provided for @pwdResetStatusRejected.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get pwdResetStatusRejected;

  /// No description provided for @pwdResetStatusUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get pwdResetStatusUnknown;

  /// No description provided for @historyAllTime.
  ///
  /// In zh, this message translates to:
  /// **'全部时间'**
  String get historyAllTime;

  /// No description provided for @historyToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get historyToday;

  /// No description provided for @historyLast7Days.
  ///
  /// In zh, this message translates to:
  /// **'近7天'**
  String get historyLast7Days;

  /// No description provided for @historyLast30Days.
  ///
  /// In zh, this message translates to:
  /// **'近30天'**
  String get historyLast30Days;

  /// No description provided for @historyCustomRange.
  ///
  /// In zh, this message translates to:
  /// **'自定义时间'**
  String get historyCustomRange;

  /// No description provided for @historyCustomRangeTitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义时间范围'**
  String get historyCustomRangeTitle;

  /// No description provided for @historyStartDate.
  ///
  /// In zh, this message translates to:
  /// **'开始日期'**
  String get historyStartDate;

  /// No description provided for @historyEndDate.
  ///
  /// In zh, this message translates to:
  /// **'结束日期'**
  String get historyEndDate;

  /// No description provided for @historyPleaseSelect.
  ///
  /// In zh, this message translates to:
  /// **'请选择'**
  String get historyPleaseSelect;

  /// No description provided for @historyClear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get historyClear;

  /// No description provided for @historyApply.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get historyApply;

  /// No description provided for @historySearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索操作记录...'**
  String get historySearchHint;

  /// No description provided for @historyTotalRecords.
  ///
  /// In zh, this message translates to:
  /// **'共 {total} 条记录'**
  String historyTotalRecords(int total);

  /// No description provided for @historyNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无操作记录'**
  String get historyNoRecords;

  /// No description provided for @historyActionTypeLabel.
  ///
  /// In zh, this message translates to:
  /// **'操作类型'**
  String get historyActionTypeLabel;

  /// No description provided for @historyEntityLabel.
  ///
  /// In zh, this message translates to:
  /// **'对象'**
  String get historyEntityLabel;

  /// No description provided for @historyEntityLocation.
  ///
  /// In zh, this message translates to:
  /// **'库位'**
  String get historyEntityLocation;

  /// No description provided for @historyEntityInventory.
  ///
  /// In zh, this message translates to:
  /// **'库存'**
  String get historyEntityInventory;

  /// No description provided for @historyUserLabel.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get historyUserLabel;

  /// No description provided for @historyTimeLabel.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get historyTimeLabel;

  /// No description provided for @historyAllUsersTab.
  ///
  /// In zh, this message translates to:
  /// **'全部用户'**
  String get historyAllUsersTab;

  /// No description provided for @historyMyRecords.
  ///
  /// In zh, this message translates to:
  /// **'我的记录'**
  String get historyMyRecords;

  /// No description provided for @historyFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get historyFilterAll;

  /// No description provided for @historyFilterImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get historyFilterImport;

  /// No description provided for @historyFilterNew.
  ///
  /// In zh, this message translates to:
  /// **'新增'**
  String get historyFilterNew;

  /// No description provided for @historyFilterEntry.
  ///
  /// In zh, this message translates to:
  /// **'录入'**
  String get historyFilterEntry;

  /// No description provided for @historyFilterAdjust.
  ///
  /// In zh, this message translates to:
  /// **'调整'**
  String get historyFilterAdjust;

  /// No description provided for @historyFilterTransfer.
  ///
  /// In zh, this message translates to:
  /// **'转移'**
  String get historyFilterTransfer;

  /// No description provided for @historyFilterCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get historyFilterCopy;

  /// No description provided for @historyFilterCheck.
  ///
  /// In zh, this message translates to:
  /// **'检查'**
  String get historyFilterCheck;

  /// No description provided for @historyFilterIn.
  ///
  /// In zh, this message translates to:
  /// **'入库'**
  String get historyFilterIn;

  /// No description provided for @historyFilterOut.
  ///
  /// In zh, this message translates to:
  /// **'出库'**
  String get historyFilterOut;

  /// No description provided for @historyEntitySku.
  ///
  /// In zh, this message translates to:
  /// **'SKU'**
  String get historyEntitySku;

  /// No description provided for @historyEntityLocationLabel.
  ///
  /// In zh, this message translates to:
  /// **'库位'**
  String get historyEntityLocationLabel;

  /// No description provided for @historyEntityInventoryLabel.
  ///
  /// In zh, this message translates to:
  /// **'库存'**
  String get historyEntityInventoryLabel;

  /// No description provided for @historyPieceSuffix.
  ///
  /// In zh, this message translates to:
  /// **'件'**
  String get historyPieceSuffix;

  /// No description provided for @inventoryAddManualTitle.
  ///
  /// In zh, this message translates to:
  /// **'手动录入库存'**
  String get inventoryAddManualTitle;

  /// No description provided for @inventorySkuSection.
  ///
  /// In zh, this message translates to:
  /// **'SKU'**
  String get inventorySkuSection;

  /// No description provided for @inventoryLocationSection.
  ///
  /// In zh, this message translates to:
  /// **'库位'**
  String get inventoryLocationSection;

  /// No description provided for @inventoryInitialStockSection.
  ///
  /// In zh, this message translates to:
  /// **'初始库存'**
  String get inventoryInitialStockSection;

  /// No description provided for @inventoryNewSkuLabel.
  ///
  /// In zh, this message translates to:
  /// **'新建 SKU'**
  String get inventoryNewSkuLabel;

  /// No description provided for @inventorySearchExisting.
  ///
  /// In zh, this message translates to:
  /// **'搜索已有'**
  String get inventorySearchExisting;

  /// No description provided for @inventorySearchSkuHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索 SKU 编号 / 名称 / 条码'**
  String get inventorySearchSkuHint;

  /// No description provided for @inventoryNewSkuTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建 \"{name}\"'**
  String inventoryNewSkuTitle(String name);

  /// No description provided for @inventorySkuNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到，'**
  String get inventorySkuNotFound;

  /// No description provided for @inventoryCreateNewSku.
  ///
  /// In zh, this message translates to:
  /// **'点击新建此 SKU'**
  String get inventoryCreateNewSku;

  /// No description provided for @inventorySkuCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'SKU 编号 *'**
  String get inventorySkuCodeLabel;

  /// No description provided for @inventoryProductNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'商品名称'**
  String get inventoryProductNameLabel;

  /// No description provided for @inventoryBarcodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'条形码（可选）'**
  String get inventoryBarcodeLabel;

  /// No description provided for @inventoryNewLocationLabel.
  ///
  /// In zh, this message translates to:
  /// **'新建库位'**
  String get inventoryNewLocationLabel;

  /// No description provided for @inventorySearchLocationHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索库位编号'**
  String get inventorySearchLocationHint;

  /// No description provided for @inventoryNewLocationTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建 \"{name}\"'**
  String inventoryNewLocationTitle(String name);

  /// No description provided for @inventoryLocationNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到，'**
  String get inventoryLocationNotFound;

  /// No description provided for @inventoryCreateNewLocation.
  ///
  /// In zh, this message translates to:
  /// **'点击新建此库位'**
  String get inventoryCreateNewLocation;

  /// No description provided for @inventoryLocationCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'库位编号 *'**
  String get inventoryLocationCodeLabel;

  /// No description provided for @inventoryLocationDescLabel.
  ///
  /// In zh, this message translates to:
  /// **'描述（可选）'**
  String get inventoryLocationDescLabel;

  /// No description provided for @inventoryPendingTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂存 / 待清点'**
  String get inventoryPendingTitle;

  /// No description provided for @inventoryPendingSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'货已到位，数量暂未确认'**
  String get inventoryPendingSubtitle;

  /// No description provided for @inventoryModeCarton.
  ///
  /// In zh, this message translates to:
  /// **'按箱规'**
  String get inventoryModeCarton;

  /// No description provided for @inventoryModeBoxOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅箱数'**
  String get inventoryModeBoxOnly;

  /// No description provided for @inventoryModeQty.
  ///
  /// In zh, this message translates to:
  /// **'按总数量'**
  String get inventoryModeQty;

  /// No description provided for @inventoryBoxesLabel.
  ///
  /// In zh, this message translates to:
  /// **'箱数 *'**
  String get inventoryBoxesLabel;

  /// No description provided for @inventoryBoxesSuffix.
  ///
  /// In zh, this message translates to:
  /// **'箱'**
  String get inventoryBoxesSuffix;

  /// No description provided for @inventoryUnitsLabel.
  ///
  /// In zh, this message translates to:
  /// **'每箱件数 *'**
  String get inventoryUnitsLabel;

  /// No description provided for @inventoryTotalQtyLabel.
  ///
  /// In zh, this message translates to:
  /// **'总件数 *'**
  String get inventoryTotalQtyLabel;

  /// No description provided for @inventoryTotalQtySuffix.
  ///
  /// In zh, this message translates to:
  /// **'件'**
  String get inventoryTotalQtySuffix;

  /// No description provided for @inventoryNoteLabel.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get inventoryNoteLabel;

  /// No description provided for @inventoryAddNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'添加备注'**
  String get inventoryAddNoteHint;

  /// No description provided for @inventoryConfirmPending.
  ///
  /// In zh, this message translates to:
  /// **'确认暂存'**
  String get inventoryConfirmPending;

  /// No description provided for @inventorySaveStock.
  ///
  /// In zh, this message translates to:
  /// **'保存库存'**
  String get inventorySaveStock;

  /// No description provided for @inventoryStockSaved.
  ///
  /// In zh, this message translates to:
  /// **'库存已保存'**
  String get inventoryStockSaved;

  /// No description provided for @inventorySelectOrCreate.
  ///
  /// In zh, this message translates to:
  /// **'请选择 SKU 或新建'**
  String get inventorySelectOrCreate;

  /// No description provided for @inventorySkuCodeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'SKU 编号不能为空'**
  String get inventorySkuCodeEmpty;

  /// No description provided for @inventoryLocationCodeEmpty.
  ///
  /// In zh, this message translates to:
  /// **'库位编号不能为空'**
  String get inventoryLocationCodeEmpty;

  /// No description provided for @inventoryValidBoxCount.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效箱数'**
  String get inventoryValidBoxCount;

  /// No description provided for @inventoryValidUnits.
  ///
  /// In zh, this message translates to:
  /// **'请输入每箱件数'**
  String get inventoryValidUnits;

  /// No description provided for @inventoryValidQty.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效件数'**
  String get inventoryValidQty;

  /// No description provided for @inventoryTotal.
  ///
  /// In zh, this message translates to:
  /// **'合计'**
  String get inventoryTotal;

  /// No description provided for @inventoryBoxesTotal.
  ///
  /// In zh, this message translates to:
  /// **'{boxes} 箱 · 箱规待确认'**
  String inventoryBoxesTotal(int boxes);

  /// No description provided for @inventoryQtyTotal.
  ///
  /// In zh, this message translates to:
  /// **'合计 {qty} 件'**
  String inventoryQtyTotal(int qty);

  /// No description provided for @inventoryPendingNote.
  ///
  /// In zh, this message translates to:
  /// **'将标记为\"暂存\"状态，数量不计入正式合计。'**
  String get inventoryPendingNote;

  /// No description provided for @skuDetailNewLocation.
  ///
  /// In zh, this message translates to:
  /// **'新增库位'**
  String get skuDetailNewLocation;

  /// No description provided for @skuDetailLocationSection.
  ///
  /// In zh, this message translates to:
  /// **'库位'**
  String get skuDetailLocationSection;

  /// No description provided for @skuDetailNewLocationButton.
  ///
  /// In zh, this message translates to:
  /// **'+ 新建库位'**
  String get skuDetailNewLocationButton;

  /// No description provided for @skuDetailSearchLocationHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索库位编号'**
  String get skuDetailSearchLocationHint;

  /// No description provided for @skuDetailNewLocationTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建 \"{name}\"'**
  String skuDetailNewLocationTitle(String name);

  /// No description provided for @skuDetailLocationNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到，点击新建'**
  String get skuDetailLocationNotFound;

  /// No description provided for @skuDetailLocationCodeHint.
  ///
  /// In zh, this message translates to:
  /// **'库位编号 *'**
  String get skuDetailLocationCodeHint;

  /// No description provided for @skuDetailLocationDescHint.
  ///
  /// In zh, this message translates to:
  /// **'描述（可选）'**
  String get skuDetailLocationDescHint;

  /// No description provided for @skuDetailInitialStock.
  ///
  /// In zh, this message translates to:
  /// **'初始库存'**
  String get skuDetailInitialStock;

  /// No description provided for @skuDetailPendingTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂存 / 待清点'**
  String get skuDetailPendingTitle;

  /// No description provided for @skuDetailPendingSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'货已到位，数量暂未确认'**
  String get skuDetailPendingSubtitle;

  /// No description provided for @skuDetailModeCarton.
  ///
  /// In zh, this message translates to:
  /// **'按箱规'**
  String get skuDetailModeCarton;

  /// No description provided for @skuDetailModeBoxOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅箱数'**
  String get skuDetailModeBoxOnly;

  /// No description provided for @skuDetailModeQty.
  ///
  /// In zh, this message translates to:
  /// **'按总数量'**
  String get skuDetailModeQty;

  /// No description provided for @skuDetailBoxesLabel.
  ///
  /// In zh, this message translates to:
  /// **'箱数'**
  String get skuDetailBoxesLabel;

  /// No description provided for @skuDetailBoxesSuffix.
  ///
  /// In zh, this message translates to:
  /// **'箱'**
  String get skuDetailBoxesSuffix;

  /// No description provided for @skuDetailUnitsLabel.
  ///
  /// In zh, this message translates to:
  /// **'每箱件数'**
  String get skuDetailUnitsLabel;

  /// No description provided for @skuDetailUnitsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'件/箱'**
  String get skuDetailUnitsSuffix;

  /// No description provided for @skuDetailBoxesOnlyHelp.
  ///
  /// In zh, this message translates to:
  /// **'仅记录箱数，每箱件数可后续补充'**
  String get skuDetailBoxesOnlyHelp;

  /// No description provided for @skuDetailTotalLabel.
  ///
  /// In zh, this message translates to:
  /// **'初始总件数'**
  String get skuDetailTotalLabel;

  /// No description provided for @skuDetailTotalSuffix.
  ///
  /// In zh, this message translates to:
  /// **'件'**
  String get skuDetailTotalSuffix;

  /// No description provided for @skuDetailNoteLabel.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get skuDetailNoteLabel;

  /// No description provided for @skuDetailCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get skuDetailCancel;

  /// No description provided for @skuDetailCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get skuDetailCreate;

  /// No description provided for @skuDetailSelectSku.
  ///
  /// In zh, this message translates to:
  /// **'请选择 SKU'**
  String get skuDetailSelectSku;

  /// No description provided for @skuDetailValidBoxes.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的箱数和每箱件数'**
  String get skuDetailValidBoxes;

  /// No description provided for @skuDetailValidBoxesOnly.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效箱数'**
  String get skuDetailValidBoxesOnly;

  /// No description provided for @skuDetailValidQty.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的数量'**
  String get skuDetailValidQty;

  /// No description provided for @skuDetailConfirmPending.
  ///
  /// In zh, this message translates to:
  /// **'确认暂存'**
  String get skuDetailConfirmPending;

  /// No description provided for @skuDetailSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get skuDetailSave;

  /// No description provided for @skuDetailDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get skuDetailDeleteConfirmTitle;

  /// No description provided for @skuDetailDeleteConfirmContent.
  ///
  /// In zh, this message translates to:
  /// **'确定删除 {location} 中的\n{sku} 当前库存记录吗？\n此操作不可恢复。'**
  String skuDetailDeleteConfirmContent(String location, String sku);

  /// No description provided for @skuDetailDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get skuDetailDelete;

  /// No description provided for @skuDetailDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败: {error}'**
  String skuDetailDeleteFailed(String error);

  /// No description provided for @skuDetailArchiveWithStockContent.
  ///
  /// In zh, this message translates to:
  /// **'{skuCode} 仍有 {count} 条库存记录。\n\n归档后该 SKU 不允许新入库，但现有库存仍可查看和出库。\n\n确认归档？'**
  String skuDetailArchiveWithStockContent(String skuCode, int count);

  /// No description provided for @skuDetailArchiveContent.
  ///
  /// In zh, this message translates to:
  /// **'确定归档 SKU {skuCode}？归档后不允许新入库。'**
  String skuDetailArchiveContent(String skuCode);

  /// No description provided for @skuDetailArchiveTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认归档'**
  String get skuDetailArchiveTitle;

  /// No description provided for @skuDetailConfirmArchive.
  ///
  /// In zh, this message translates to:
  /// **'确认归档'**
  String get skuDetailConfirmArchive;

  /// No description provided for @skuDetailArchived.
  ///
  /// In zh, this message translates to:
  /// **'{skuCode} 已归档'**
  String skuDetailArchived(String skuCode);

  /// No description provided for @skuDetailOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败: {error}'**
  String skuDetailOperationFailed(String error);

  /// No description provided for @skuDetailRestoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复 SKU'**
  String get skuDetailRestoreTitle;

  /// No description provided for @skuDetailRestoreContent.
  ///
  /// In zh, this message translates to:
  /// **'确定将 {skuCode} 恢复为\"在用\"状态？'**
  String skuDetailRestoreContent(String skuCode);

  /// No description provided for @skuDetailConfirmRestore.
  ///
  /// In zh, this message translates to:
  /// **'确认恢复'**
  String get skuDetailConfirmRestore;

  /// No description provided for @skuDetailRestored.
  ///
  /// In zh, this message translates to:
  /// **'{skuCode} 已恢复为在用'**
  String skuDetailRestored(String skuCode);

  /// No description provided for @skuDetailArchivedNotice.
  ///
  /// In zh, this message translates to:
  /// **'此 SKU 已归档，不允许新入库。现有库存仍可查看和出库。'**
  String get skuDetailArchivedNotice;

  /// No description provided for @skuDetailTotalStock.
  ///
  /// In zh, this message translates to:
  /// **'总库存'**
  String get skuDetailTotalStock;

  /// No description provided for @skuDetailTotalBoxes.
  ///
  /// In zh, this message translates to:
  /// **'{boxes} 箱'**
  String skuDetailTotalBoxes(int boxes);

  /// No description provided for @skuDetailTotalQtyPieces.
  ///
  /// In zh, this message translates to:
  /// **'{qty} 件'**
  String skuDetailTotalQtyPieces(int qty);

  /// No description provided for @skuDetailLocationCol.
  ///
  /// In zh, this message translates to:
  /// **'库位'**
  String get skuDetailLocationCol;

  /// No description provided for @skuDetailBoxesCol.
  ///
  /// In zh, this message translates to:
  /// **'箱数'**
  String get skuDetailBoxesCol;

  /// No description provided for @skuDetailDefaultCarton.
  ///
  /// In zh, this message translates to:
  /// **'默认箱规'**
  String get skuDetailDefaultCarton;

  /// No description provided for @skuDetailCartonQtyDisplay.
  ///
  /// In zh, this message translates to:
  /// **'{qty} 件/箱'**
  String skuDetailCartonQtyDisplay(int qty);

  /// No description provided for @skuDetailSpecCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 种箱规'**
  String skuDetailSpecCount(int count);

  /// No description provided for @skuDetailStockLocations.
  ///
  /// In zh, this message translates to:
  /// **'库存位置'**
  String get skuDetailStockLocations;

  /// No description provided for @skuDetailAddLocation.
  ///
  /// In zh, this message translates to:
  /// **'添加库位'**
  String get skuDetailAddLocation;

  /// No description provided for @skuDetailBadgePending.
  ///
  /// In zh, this message translates to:
  /// **'待清点'**
  String get skuDetailBadgePending;

  /// No description provided for @skuDetailBadgeBoxOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅箱数'**
  String get skuDetailBadgeBoxOnly;

  /// No description provided for @skuDetailBadgeCarton.
  ///
  /// In zh, this message translates to:
  /// **'按箱规'**
  String get skuDetailBadgeCarton;

  /// No description provided for @skuDetailUnknownLocation.
  ///
  /// In zh, this message translates to:
  /// **'未知位置'**
  String get skuDetailUnknownLocation;

  /// No description provided for @skuDetailStockDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get skuDetailStockDelete;

  /// No description provided for @skuDetailSkuStock.
  ///
  /// In zh, this message translates to:
  /// **'库存 SKU ({total})'**
  String skuDetailSkuStock(int total);

  /// No description provided for @skuDetailSkuStockShown.
  ///
  /// In zh, this message translates to:
  /// **'库存 SKU ({shown} / {total})'**
  String skuDetailSkuStockShown(int shown, int total);

  /// No description provided for @skuDetailTransferLabel.
  ///
  /// In zh, this message translates to:
  /// **'转移'**
  String get skuDetailTransferLabel;

  /// No description provided for @skuDetailCopyLabel.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get skuDetailCopyLabel;

  /// No description provided for @skuDetailNoMatchingSku.
  ///
  /// In zh, this message translates to:
  /// **'暂无匹配的 SKU'**
  String get skuDetailNoMatchingSku;

  /// No description provided for @skuDetailClearFilter.
  ///
  /// In zh, this message translates to:
  /// **'清除筛选'**
  String get skuDetailClearFilter;

  /// No description provided for @skuDetailFilterStock.
  ///
  /// In zh, this message translates to:
  /// **'库存:'**
  String get skuDetailFilterStock;

  /// No description provided for @skuDetailFilterBusiness.
  ///
  /// In zh, this message translates to:
  /// **'业务:'**
  String get skuDetailFilterBusiness;

  /// No description provided for @skuDetailFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get skuDetailFilterAll;

  /// No description provided for @skuDetailFilterHasStock.
  ///
  /// In zh, this message translates to:
  /// **'有库存'**
  String get skuDetailFilterHasStock;

  /// No description provided for @skuDetailFilterZeroStock.
  ///
  /// In zh, this message translates to:
  /// **'0库存'**
  String get skuDetailFilterZeroStock;

  /// No description provided for @skuDetailFilterNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get skuDetailFilterNormal;

  /// No description provided for @skuDetailFilterPending.
  ///
  /// In zh, this message translates to:
  /// **'暂存'**
  String get skuDetailFilterPending;

  /// No description provided for @skuDetailChecked.
  ///
  /// In zh, this message translates to:
  /// **'已检查'**
  String get skuDetailChecked;

  /// No description provided for @skuDetailLastCheck.
  ///
  /// In zh, this message translates to:
  /// **'上次检查'**
  String get skuDetailLastCheck;

  /// No description provided for @skuDetailNoCheckRecord.
  ///
  /// In zh, this message translates to:
  /// **'无检查记录'**
  String get skuDetailNoCheckRecord;

  /// No description provided for @skuDetailLastChange.
  ///
  /// In zh, this message translates to:
  /// **'上次变更'**
  String get skuDetailLastChange;

  /// No description provided for @skuDetailNoChangeRecord.
  ///
  /// In zh, this message translates to:
  /// **'无变更记录'**
  String get skuDetailNoChangeRecord;

  /// No description provided for @skuDetailTotalBoxesLabel.
  ///
  /// In zh, this message translates to:
  /// **'总箱数'**
  String get skuDetailTotalBoxesLabel;

  /// No description provided for @skuDetailTotalPiecesLabel.
  ///
  /// In zh, this message translates to:
  /// **'总件数'**
  String get skuDetailTotalPiecesLabel;

  /// No description provided for @skuDetailChangeRecords.
  ///
  /// In zh, this message translates to:
  /// **'{locationCode} 变更记录'**
  String skuDetailChangeRecords(String locationCode);

  /// No description provided for @skuDetailLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败: {error}'**
  String skuDetailLoadFailed(String error);

  /// No description provided for @skuDetailNoChangeRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无变更记录'**
  String get skuDetailNoChangeRecords;

  /// No description provided for @skuDetailViewAllRecords.
  ///
  /// In zh, this message translates to:
  /// **'查看全部 {total} 条记录'**
  String skuDetailViewAllRecords(int total);

  /// No description provided for @skuDetailViewHistoryPage.
  ///
  /// In zh, this message translates to:
  /// **'在操作记录页查看'**
  String get skuDetailViewHistoryPage;

  /// No description provided for @skuDetailNoSkuHere.
  ///
  /// In zh, this message translates to:
  /// **'该库位暂无可操作的 SKU'**
  String get skuDetailNoSkuHere;

  /// No description provided for @skuDetailCheckInventory.
  ///
  /// In zh, this message translates to:
  /// **'请确认库位 {code} 是否已录入库存，\n或联系管理员检查数据'**
  String skuDetailCheckInventory(String code);

  /// No description provided for @skuDetailCreateSkuError.
  ///
  /// In zh, this message translates to:
  /// **'请输入 SKU 编码'**
  String get skuDetailCreateSkuError;

  /// No description provided for @skuDetailCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败: {error}'**
  String skuDetailCreateFailed(String error);

  /// No description provided for @skuDetailPendingMarkTitle.
  ///
  /// In zh, this message translates to:
  /// **'标记为暂存 / 待清点'**
  String get skuDetailPendingMarkTitle;

  /// No description provided for @skuDetailPendingMarkSubtitle1.
  ///
  /// In zh, this message translates to:
  /// **'此记录将归入暂存分类，可填写实际数量'**
  String get skuDetailPendingMarkSubtitle1;

  /// No description provided for @skuDetailPendingMarkSubtitle2.
  ///
  /// In zh, this message translates to:
  /// **'勾选后归入暂存分类，数量仍正常录入'**
  String get skuDetailPendingMarkSubtitle2;

  /// No description provided for @skuDetailNewSkuCode.
  ///
  /// In zh, this message translates to:
  /// **'SKU 编码 *'**
  String get skuDetailNewSkuCode;

  /// No description provided for @skuDetailNewSkuName.
  ///
  /// In zh, this message translates to:
  /// **'货号名称（可选）'**
  String get skuDetailNewSkuName;

  /// No description provided for @skuDetailEmptyFilterMsg.
  ///
  /// In zh, this message translates to:
  /// **'当前筛选「{parts}」下暂无 SKU'**
  String skuDetailEmptyFilterMsg(String parts);

  /// No description provided for @skuDetailNoInventory.
  ///
  /// In zh, this message translates to:
  /// **'暂无库存 SKU'**
  String get skuDetailNoInventory;

  /// No description provided for @skuDetailQtyLinePending.
  ///
  /// In zh, this message translates to:
  /// **'待补充库存信息'**
  String get skuDetailQtyLinePending;

  /// No description provided for @skuDetailQtyLineBoxes.
  ///
  /// In zh, this message translates to:
  /// **'{boxes}箱 · 箱规待确认'**
  String skuDetailQtyLineBoxes(int boxes);

  /// No description provided for @skuDetailQtyLineCarton.
  ///
  /// In zh, this message translates to:
  /// **'{boxes}箱 · {qty}件'**
  String skuDetailQtyLineCarton(int boxes, int qty);

  /// No description provided for @skuDetailSelectedSkus.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 种 SKU，请选择目标库位'**
  String skuDetailSelectedSkus(int count);

  /// No description provided for @skuDetailTargetLocationHint.
  ///
  /// In zh, this message translates to:
  /// **'输入库位编码...'**
  String get skuDetailTargetLocationHint;

  /// No description provided for @skuDetailEnterCodeToSearch.
  ///
  /// In zh, this message translates to:
  /// **'输入库位编码以搜索目标位置'**
  String get skuDetailEnterCodeToSearch;

  /// No description provided for @skuDetailLoadTargetFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载目标库位失败'**
  String get skuDetailLoadTargetFailed;

  /// No description provided for @skuDetailCreateLocationFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建库位失败: {error}'**
  String skuDetailCreateLocationFailed(String error);

  /// No description provided for @skuDetailNewAndTransfer.
  ///
  /// In zh, this message translates to:
  /// **'新建库位 \"{code}\" 并{action}到此'**
  String skuDetailNewAndTransfer(String code, String action);

  /// No description provided for @skuDetailSelectedSkuCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 种 SKU'**
  String skuDetailSelectedSkuCount(int count);

  /// No description provided for @skuDetailConflictMsg.
  ///
  /// In zh, this message translates to:
  /// **'目标库位已有 {count} 种相同 SKU，请选择处理方式：'**
  String skuDetailConflictMsg(int count);

  /// No description provided for @skuDetailMerge.
  ///
  /// In zh, this message translates to:
  /// **'合并'**
  String get skuDetailMerge;

  /// No description provided for @skuDetailMergeDesc.
  ///
  /// In zh, this message translates to:
  /// **'将来源库存合并到目标已有库存中'**
  String get skuDetailMergeDesc;

  /// No description provided for @skuDetailOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'覆盖'**
  String get skuDetailOverwrite;

  /// No description provided for @skuDetailOverwriteDesc.
  ///
  /// In zh, this message translates to:
  /// **'用来源库存替换目标已有库存'**
  String get skuDetailOverwriteDesc;

  /// No description provided for @skuDetailStack.
  ///
  /// In zh, this message translates to:
  /// **'叠加'**
  String get skuDetailStack;

  /// No description provided for @skuDetailStackDesc.
  ///
  /// In zh, this message translates to:
  /// **'将来源库存叠加到目标已有库存中'**
  String get skuDetailStackDesc;

  /// No description provided for @skuDetailNoConflict.
  ///
  /// In zh, this message translates to:
  /// **'无冲突 SKU（{count} 种，将直接{action}）：'**
  String skuDetailNoConflict(int count, String action);

  /// No description provided for @skuDetailTransferDeleteNotice.
  ///
  /// In zh, this message translates to:
  /// **'转移完成后，原库位对应的 SKU 库存数据将被删除。'**
  String get skuDetailTransferDeleteNotice;

  /// No description provided for @skuDetailTransferFailed.
  ///
  /// In zh, this message translates to:
  /// **'{action}失败: {error}'**
  String skuDetailTransferFailed(String action, String error);

  /// No description provided for @skuDetailBulkTitle.
  ///
  /// In zh, this message translates to:
  /// **'批量{action}库存'**
  String skuDetailBulkTitle(String action);

  /// No description provided for @skuDetailBulkSelectHint.
  ///
  /// In zh, this message translates to:
  /// **'选择要{action}的 SKU（来源：{code}）'**
  String skuDetailBulkSelectHint(String action, String code);

  /// No description provided for @skuDetailSkuCountSuffix.
  ///
  /// In zh, this message translates to:
  /// **'{count} 种 SKU · '**
  String skuDetailSkuCountSuffix(int count);

  /// No description provided for @skuDetailSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 种'**
  String skuDetailSelectedCount(int count);

  /// No description provided for @skuDetailDeselectAll.
  ///
  /// In zh, this message translates to:
  /// **'取消全选'**
  String get skuDetailDeselectAll;

  /// No description provided for @skuDetailSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get skuDetailSelectAll;

  /// No description provided for @skuDetailReturn.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get skuDetailReturn;

  /// No description provided for @skuDetailConfirmActionCount.
  ///
  /// In zh, this message translates to:
  /// **'确认{action} {count} 种'**
  String skuDetailConfirmActionCount(String action, int count);

  /// No description provided for @skuDetailNextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get skuDetailNextStep;

  /// No description provided for @skuDetailNextStepWithCount.
  ///
  /// In zh, this message translates to:
  /// **'下一步（已选 {count} 种）'**
  String skuDetailNextStepWithCount(int count);

  /// No description provided for @skuDetailConfirmAction.
  ///
  /// In zh, this message translates to:
  /// **'确认{action}'**
  String skuDetailConfirmAction(String action);

  /// No description provided for @skuDetailRouteLabel.
  ///
  /// In zh, this message translates to:
  /// **'{src} → {dst}，共 {total} 种 SKU'**
  String skuDetailRouteLabel(String src, String dst, int total);

  /// No description provided for @skuDetailDirectAction.
  ///
  /// In zh, this message translates to:
  /// **'直接{action}'**
  String skuDetailDirectAction(String action);

  /// No description provided for @skuDetailResultSection.
  ///
  /// In zh, this message translates to:
  /// **'{title}（{count} 种）'**
  String skuDetailResultSection(String title, int count);

  /// No description provided for @skuDetailTransferDone.
  ///
  /// In zh, this message translates to:
  /// **'{action}完成'**
  String skuDetailTransferDone(String action);

  /// No description provided for @importTitle.
  ///
  /// In zh, this message translates to:
  /// **'批量导入'**
  String get importTitle;

  /// No description provided for @importSelectType.
  ///
  /// In zh, this message translates to:
  /// **'选择导入类型'**
  String get importSelectType;

  /// No description provided for @importRecordsTab.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get importRecordsTab;

  /// No description provided for @importHistoryTab.
  ///
  /// In zh, this message translates to:
  /// **'导入记录'**
  String get importHistoryTab;

  /// No description provided for @importHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入记录'**
  String get importHistoryTitle;

  /// No description provided for @importSkuMasterLabel.
  ///
  /// In zh, this message translates to:
  /// **'SKU 主档导入'**
  String get importSkuMasterLabel;

  /// No description provided for @importSkuMasterSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'批量新增或更新 SKU 基础资料'**
  String get importSkuMasterSubtitle;

  /// No description provided for @importLocationMasterLabel.
  ///
  /// In zh, this message translates to:
  /// **'库位主档导入'**
  String get importLocationMasterLabel;

  /// No description provided for @importLocationMasterSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'批量新增或更新库位'**
  String get importLocationMasterSubtitle;

  /// No description provided for @importInventoryLabel.
  ///
  /// In zh, this message translates to:
  /// **'库存明细导入'**
  String get importInventoryLabel;

  /// No description provided for @importInventorySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'批量录入库存数量（SKU 和库位须已存在）'**
  String get importInventorySubtitle;

  /// No description provided for @importSkuBarcodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'SKU 条码批量更新'**
  String get importSkuBarcodeLabel;

  /// No description provided for @importSkuBarcodeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'仅更新已有 SKU 的条形码字段'**
  String get importSkuBarcodeSubtitle;

  /// No description provided for @importSkuCartonLabel.
  ///
  /// In zh, this message translates to:
  /// **'SKU 箱规批量更新'**
  String get importSkuCartonLabel;

  /// No description provided for @importSkuCartonSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'仅更新已有 SKU 的默认箱规字段'**
  String get importSkuCartonSubtitle;

  /// No description provided for @importTemplateColumns.
  ///
  /// In zh, this message translates to:
  /// **'模板列说明：'**
  String get importTemplateColumns;

  /// No description provided for @importReselect.
  ///
  /// In zh, this message translates to:
  /// **'重新选择'**
  String get importReselect;

  /// No description provided for @importConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认导入 ({count} 条)'**
  String importConfirm(int count);

  /// No description provided for @importNoData.
  ///
  /// In zh, this message translates to:
  /// **'无可导入数据'**
  String get importNoData;

  /// No description provided for @importReimport.
  ///
  /// In zh, this message translates to:
  /// **'重新导入'**
  String get importReimport;

  /// No description provided for @importDownloadTemplate.
  ///
  /// In zh, this message translates to:
  /// **'下载模板'**
  String get importDownloadTemplate;

  /// No description provided for @importValidating.
  ///
  /// In zh, this message translates to:
  /// **'校验中…'**
  String get importValidating;

  /// No description provided for @importImporting.
  ///
  /// In zh, this message translates to:
  /// **'导入中…'**
  String get importImporting;

  /// No description provided for @importSelectFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get importSelectFile;

  /// No description provided for @importColName.
  ///
  /// In zh, this message translates to:
  /// **'列名'**
  String get importColName;

  /// No description provided for @importColRequired.
  ///
  /// In zh, this message translates to:
  /// **'必填'**
  String get importColRequired;

  /// No description provided for @importColDesc.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get importColDesc;

  /// No description provided for @importReqRequired.
  ///
  /// In zh, this message translates to:
  /// **'必填'**
  String get importReqRequired;

  /// No description provided for @importReqEitherA.
  ///
  /// In zh, this message translates to:
  /// **'二选A'**
  String get importReqEitherA;

  /// No description provided for @importReqEitherB.
  ///
  /// In zh, this message translates to:
  /// **'二选B'**
  String get importReqEitherB;

  /// No description provided for @importReqOptional.
  ///
  /// In zh, this message translates to:
  /// **'可选'**
  String get importReqOptional;

  /// No description provided for @importValidationOkWithErrors.
  ///
  /// In zh, this message translates to:
  /// **'校验完成（含部分错误）'**
  String get importValidationOkWithErrors;

  /// No description provided for @importValidationAllErrors.
  ///
  /// In zh, this message translates to:
  /// **'校验完成（全部行有错误）'**
  String get importValidationAllErrors;

  /// No description provided for @importValidationPassed.
  ///
  /// In zh, this message translates to:
  /// **'校验通过，可以导入'**
  String get importValidationPassed;

  /// No description provided for @importFilename.
  ///
  /// In zh, this message translates to:
  /// **'文件: {filename}'**
  String importFilename(String filename);

  /// No description provided for @importStatTotal.
  ///
  /// In zh, this message translates to:
  /// **'共'**
  String get importStatTotal;

  /// No description provided for @importStatCreate.
  ///
  /// In zh, this message translates to:
  /// **'待创建'**
  String get importStatCreate;

  /// No description provided for @importStatUpdate.
  ///
  /// In zh, this message translates to:
  /// **'待更新'**
  String get importStatUpdate;

  /// No description provided for @importStatSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get importStatSkip;

  /// No description provided for @importStatError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get importStatError;

  /// No description provided for @importErrorDetails.
  ///
  /// In zh, this message translates to:
  /// **'错误详情：'**
  String get importErrorDetails;

  /// No description provided for @importRowLabel.
  ///
  /// In zh, this message translates to:
  /// **'第 {row} 行  '**
  String importRowLabel(int row);

  /// No description provided for @importMoreErrors.
  ///
  /// In zh, this message translates to:
  /// **'… 还有 {count} 条错误（请修正文件后重新选择）'**
  String importMoreErrors(int count);

  /// No description provided for @importPreviewData.
  ///
  /// In zh, this message translates to:
  /// **'将写入数据预览：'**
  String get importPreviewData;

  /// No description provided for @importMoreRows.
  ///
  /// In zh, this message translates to:
  /// **'… 还有 {count} 条（确认后将全部写入）'**
  String importMoreRows(int count);

  /// No description provided for @importCreate.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get importCreate;

  /// No description provided for @importUpdate.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get importUpdate;

  /// No description provided for @importDoneTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入完成'**
  String get importDoneTitle;

  /// No description provided for @importDoneWithErrors.
  ///
  /// In zh, this message translates to:
  /// **'导入完成（有部分问题）'**
  String get importDoneWithErrors;

  /// No description provided for @importResultTotal.
  ///
  /// In zh, this message translates to:
  /// **'共'**
  String get importResultTotal;

  /// No description provided for @importResultCreate.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get importResultCreate;

  /// No description provided for @importResultUpdate.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get importResultUpdate;

  /// No description provided for @importResultSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get importResultSkip;

  /// No description provided for @importResultError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get importResultError;

  /// No description provided for @importRowErrorDetails.
  ///
  /// In zh, this message translates to:
  /// **'行级错误详情：'**
  String get importRowErrorDetails;

  /// No description provided for @importMoreRowErrors.
  ///
  /// In zh, this message translates to:
  /// **'… 还有 {count} 条错误'**
  String importMoreRowErrors(int count);

  /// No description provided for @importValidationFailed.
  ///
  /// In zh, this message translates to:
  /// **'校验失败，请检查文件格式'**
  String get importValidationFailed;

  /// No description provided for @importValidationError.
  ///
  /// In zh, this message translates to:
  /// **'校验失败: {error}'**
  String importValidationError(String error);

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败，请检查文件格式'**
  String get importFailed;

  /// No description provided for @importError.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String importError(String error);

  /// No description provided for @importHistoryTotal.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条记录'**
  String importHistoryTotal(int count);

  /// No description provided for @importHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无导入记录'**
  String get importHistoryEmpty;

  /// No description provided for @importHistoryLoadMore.
  ///
  /// In zh, this message translates to:
  /// **'加载更多'**
  String get importHistoryLoadMore;

  /// No description provided for @importExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败: {error}'**
  String importExportFailed(String error);

  /// No description provided for @importStatusSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get importStatusSuccess;

  /// No description provided for @importStatusPartial.
  ///
  /// In zh, this message translates to:
  /// **'部分成功'**
  String get importStatusPartial;

  /// No description provided for @importStatusAllFailed.
  ///
  /// In zh, this message translates to:
  /// **'全部失败'**
  String get importStatusAllFailed;

  /// No description provided for @importStatusSkipped.
  ///
  /// In zh, this message translates to:
  /// **'完成（有跳过）'**
  String get importStatusSkipped;

  /// No description provided for @importHistoryStatTotal.
  ///
  /// In zh, this message translates to:
  /// **'共'**
  String get importHistoryStatTotal;

  /// No description provided for @importHistoryStatCreate.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get importHistoryStatCreate;

  /// No description provided for @importHistoryStatUpdate.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get importHistoryStatUpdate;

  /// No description provided for @importHistoryStatSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get importHistoryStatSkip;

  /// No description provided for @importHistoryStatError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get importHistoryStatError;

  /// No description provided for @importHistoryRowErrors.
  ///
  /// In zh, this message translates to:
  /// **'行级错误详情：'**
  String get importHistoryRowErrors;

  /// No description provided for @importHistoryMoreErrors.
  ///
  /// In zh, this message translates to:
  /// **'… 还有 {count} 条错误'**
  String importHistoryMoreErrors(int count);

  /// No description provided for @importExporting.
  ///
  /// In zh, this message translates to:
  /// **'导出中…'**
  String get importExporting;

  /// No description provided for @importExportDetail.
  ///
  /// In zh, this message translates to:
  /// **'导出详情 Excel'**
  String get importExportDetail;

  /// No description provided for @importFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get importFilterAll;

  /// No description provided for @importFilterSku.
  ///
  /// In zh, this message translates to:
  /// **'SKU 主档'**
  String get importFilterSku;

  /// No description provided for @importFilterLocation.
  ///
  /// In zh, this message translates to:
  /// **'库位主档'**
  String get importFilterLocation;

  /// No description provided for @importFilterInventory.
  ///
  /// In zh, this message translates to:
  /// **'库存明细'**
  String get importFilterInventory;

  /// No description provided for @importFilterBarcodeUpdate.
  ///
  /// In zh, this message translates to:
  /// **'条码更新'**
  String get importFilterBarcodeUpdate;

  /// No description provided for @importFilterCartonUpdate.
  ///
  /// In zh, this message translates to:
  /// **'箱规更新'**
  String get importFilterCartonUpdate;

  /// No description provided for @importRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get importRefresh;

  /// No description provided for @historyBulkSkuCount.
  ///
  /// In zh, this message translates to:
  /// **'{total} 种SKU'**
  String historyBulkSkuCount(int total);

  /// No description provided for @badgeActionCreate.
  ///
  /// In zh, this message translates to:
  /// **'新增'**
  String get badgeActionCreate;

  /// No description provided for @badgeActionUpdate.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get badgeActionUpdate;

  /// No description provided for @badgeActionDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get badgeActionDelete;

  /// No description provided for @auditBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基础信息'**
  String get auditBasicInfo;

  /// No description provided for @auditActionType.
  ///
  /// In zh, this message translates to:
  /// **'操作类型'**
  String get auditActionType;

  /// No description provided for @auditEntity.
  ///
  /// In zh, this message translates to:
  /// **'操作对象'**
  String get auditEntity;

  /// No description provided for @auditEntityId.
  ///
  /// In zh, this message translates to:
  /// **'对象 ID'**
  String get auditEntityId;

  /// No description provided for @auditOperator.
  ///
  /// In zh, this message translates to:
  /// **'操作人'**
  String get auditOperator;

  /// No description provided for @auditTime.
  ///
  /// In zh, this message translates to:
  /// **'操作时间'**
  String get auditTime;

  /// No description provided for @auditDescription.
  ///
  /// In zh, this message translates to:
  /// **'操作说明'**
  String get auditDescription;

  /// No description provided for @auditFieldChanges.
  ///
  /// In zh, this message translates to:
  /// **'字段变更'**
  String get auditFieldChanges;

  /// No description provided for @auditBefore.
  ///
  /// In zh, this message translates to:
  /// **'变更前'**
  String get auditBefore;

  /// No description provided for @auditAfter.
  ///
  /// In zh, this message translates to:
  /// **'变更后'**
  String get auditAfter;

  /// No description provided for @auditNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get auditNone;

  /// No description provided for @auditStockInTitle.
  ///
  /// In zh, this message translates to:
  /// **'入库内容'**
  String get auditStockInTitle;

  /// No description provided for @auditStockOutTitle.
  ///
  /// In zh, this message translates to:
  /// **'出库内容'**
  String get auditStockOutTitle;

  /// No description provided for @auditAdjustTitle.
  ///
  /// In zh, this message translates to:
  /// **'调整内容'**
  String get auditAdjustTitle;

  /// No description provided for @auditEntryTitle.
  ///
  /// In zh, this message translates to:
  /// **'录入内容'**
  String get auditEntryTitle;

  /// No description provided for @auditDeleteStockTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除内容'**
  String get auditDeleteStockTitle;

  /// No description provided for @auditStructureTitle.
  ///
  /// In zh, this message translates to:
  /// **'修改内容'**
  String get auditStructureTitle;

  /// No description provided for @auditTransferTitle.
  ///
  /// In zh, this message translates to:
  /// **'转移路径'**
  String get auditTransferTitle;

  /// No description provided for @auditCopyTitle.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get auditCopyTitle;

  /// No description provided for @auditCheckTitle.
  ///
  /// In zh, this message translates to:
  /// **'检查状态'**
  String get auditCheckTitle;

  /// No description provided for @auditLocationOpTitle.
  ///
  /// In zh, this message translates to:
  /// **'库位信息'**
  String get auditLocationOpTitle;

  /// No description provided for @auditLocation.
  ///
  /// In zh, this message translates to:
  /// **'库位'**
  String get auditLocation;

  /// No description provided for @auditSku.
  ///
  /// In zh, this message translates to:
  /// **'SKU'**
  String get auditSku;

  /// No description provided for @auditQtyAdded.
  ///
  /// In zh, this message translates to:
  /// **'+{qty}件'**
  String auditQtyAdded(int qty);

  /// No description provided for @auditQtyReduced.
  ///
  /// In zh, this message translates to:
  /// **'-{qty}件'**
  String auditQtyReduced(int qty);

  /// No description provided for @auditQtyPcs.
  ///
  /// In zh, this message translates to:
  /// **'{qty}件'**
  String auditQtyPcs(int qty);

  /// No description provided for @auditQtyBoxes.
  ///
  /// In zh, this message translates to:
  /// **'{boxes}箱'**
  String auditQtyBoxes(int boxes);

  /// No description provided for @auditQtyPcsPerBox.
  ///
  /// In zh, this message translates to:
  /// **'{qty}件/箱'**
  String auditQtyPcsPerBox(int qty);

  /// No description provided for @auditBeforeAfterChange.
  ///
  /// In zh, this message translates to:
  /// **'前后变化'**
  String get auditBeforeAfterChange;

  /// No description provided for @auditChangeLabel.
  ///
  /// In zh, this message translates to:
  /// **'变化'**
  String get auditChangeLabel;

  /// No description provided for @auditBeforeLabel.
  ///
  /// In zh, this message translates to:
  /// **'操作前'**
  String get auditBeforeLabel;

  /// No description provided for @auditAfterLabel.
  ///
  /// In zh, this message translates to:
  /// **'操作后'**
  String get auditAfterLabel;

  /// No description provided for @auditNoStock.
  ///
  /// In zh, this message translates to:
  /// **'无库存'**
  String get auditNoStock;

  /// No description provided for @auditNote.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get auditNote;

  /// No description provided for @auditDeletedNotice.
  ///
  /// In zh, this message translates to:
  /// **'该 SKU 在此库位的所有库存数据已删除，此操作不可恢复。'**
  String get auditDeletedNotice;

  /// No description provided for @auditAdjustMode.
  ///
  /// In zh, this message translates to:
  /// **'调整方式'**
  String get auditAdjustMode;

  /// No description provided for @auditAdjustModeConfig.
  ///
  /// In zh, this message translates to:
  /// **'按箱规调整'**
  String get auditAdjustModeConfig;

  /// No description provided for @auditAdjustModeQty.
  ///
  /// In zh, this message translates to:
  /// **'按总数量调整'**
  String get auditAdjustModeQty;

  /// No description provided for @auditFirstEntry.
  ///
  /// In zh, this message translates to:
  /// **'首次录入 · 共{qty}件'**
  String auditFirstEntry(int qty);

  /// No description provided for @auditSourceLocation.
  ///
  /// In zh, this message translates to:
  /// **'来源库位'**
  String get auditSourceLocation;

  /// No description provided for @auditTargetLocation.
  ///
  /// In zh, this message translates to:
  /// **'目标库位'**
  String get auditTargetLocation;

  /// No description provided for @auditSkuTotal.
  ///
  /// In zh, this message translates to:
  /// **'{total} 种SKU'**
  String auditSkuTotal(int total);

  /// No description provided for @auditAffectedDetails.
  ///
  /// In zh, this message translates to:
  /// **'涉及明细'**
  String get auditAffectedDetails;

  /// No description provided for @auditDirectTransfer.
  ///
  /// In zh, this message translates to:
  /// **'直接转移'**
  String get auditDirectTransfer;

  /// No description provided for @auditDirectTransferDesc.
  ///
  /// In zh, this message translates to:
  /// **'目标库位原无此 SKU，直接写入'**
  String get auditDirectTransferDesc;

  /// No description provided for @auditMerged.
  ///
  /// In zh, this message translates to:
  /// **'合并'**
  String get auditMerged;

  /// No description provided for @auditMergedDesc.
  ///
  /// In zh, this message translates to:
  /// **'与目标库位已有库存合并，按箱规叠加'**
  String get auditMergedDesc;

  /// No description provided for @auditOverwritten.
  ///
  /// In zh, this message translates to:
  /// **'覆盖'**
  String get auditOverwritten;

  /// No description provided for @auditOverwrittenDesc.
  ///
  /// In zh, this message translates to:
  /// **'用来源库存替换了目标库位的原有库存'**
  String get auditOverwrittenDesc;

  /// No description provided for @auditImpactResult.
  ///
  /// In zh, this message translates to:
  /// **'影响结果'**
  String get auditImpactResult;

  /// No description provided for @auditTransferDeleteNotice.
  ///
  /// In zh, this message translates to:
  /// **'转移完成后，来源库位中对应的 SKU 库存数据已被删除。\n目标库位已新增或更新上述 SKU 的库存。'**
  String get auditTransferDeleteNotice;

  /// No description provided for @auditDirectCopy.
  ///
  /// In zh, this message translates to:
  /// **'直接复制'**
  String get auditDirectCopy;

  /// No description provided for @auditDirectCopyDesc.
  ///
  /// In zh, this message translates to:
  /// **'目标库位原无此 SKU，直接写入'**
  String get auditDirectCopyDesc;

  /// No description provided for @auditStacked.
  ///
  /// In zh, this message translates to:
  /// **'叠加'**
  String get auditStacked;

  /// No description provided for @auditStackedDesc.
  ///
  /// In zh, this message translates to:
  /// **'与目标库位已有库存叠加，按箱规合并'**
  String get auditStackedDesc;

  /// No description provided for @auditCopySourceUnchanged.
  ///
  /// In zh, this message translates to:
  /// **'来源库位无变化（复制操作不删除来源数据）'**
  String get auditCopySourceUnchanged;

  /// No description provided for @auditCheckedChange.
  ///
  /// In zh, this message translates to:
  /// **'状态变化'**
  String get auditCheckedChange;

  /// No description provided for @auditMarkChecked.
  ///
  /// In zh, this message translates to:
  /// **'未检查  →  已检查'**
  String get auditMarkChecked;

  /// No description provided for @auditUnmarkChecked.
  ///
  /// In zh, this message translates to:
  /// **'已检查  →  未检查'**
  String get auditUnmarkChecked;

  /// No description provided for @auditCheckedBy.
  ///
  /// In zh, this message translates to:
  /// **'检查人'**
  String get auditCheckedBy;

  /// No description provided for @auditCheckedAt.
  ///
  /// In zh, this message translates to:
  /// **'检查时间'**
  String get auditCheckedAt;

  /// No description provided for @auditLocationCode.
  ///
  /// In zh, this message translates to:
  /// **'库位编码'**
  String get auditLocationCode;

  /// No description provided for @auditDescription2.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get auditDescription2;

  /// No description provided for @auditTotalSkuCount.
  ///
  /// In zh, this message translates to:
  /// **'{total} 种SKU'**
  String auditTotalSkuCount(int total);

  /// No description provided for @auditTargetLocationChange.
  ///
  /// In zh, this message translates to:
  /// **'目标库位变化'**
  String get auditTargetLocationChange;

  /// No description provided for @auditSkuTypeCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 种'**
  String auditSkuTypeCount(int count);

  /// No description provided for @auditGroupTitle.
  ///
  /// In zh, this message translates to:
  /// **'{title}（{count}种）'**
  String auditGroupTitle(String title, int count);

  /// No description provided for @auditQtyPcsBold.
  ///
  /// In zh, this message translates to:
  /// **'{qty}件'**
  String auditQtyPcsBold(int qty);

  /// No description provided for @auditBusinessActionStockIn.
  ///
  /// In zh, this message translates to:
  /// **'入库'**
  String get auditBusinessActionStockIn;

  /// No description provided for @auditBusinessActionStockOut.
  ///
  /// In zh, this message translates to:
  /// **'出库'**
  String get auditBusinessActionStockOut;

  /// No description provided for @auditBusinessActionAdjust.
  ///
  /// In zh, this message translates to:
  /// **'调整'**
  String get auditBusinessActionAdjust;

  /// No description provided for @auditBusinessActionEntry.
  ///
  /// In zh, this message translates to:
  /// **'录入'**
  String get auditBusinessActionEntry;

  /// No description provided for @auditBusinessActionDeleteStock.
  ///
  /// In zh, this message translates to:
  /// **'删除库存'**
  String get auditBusinessActionDeleteStock;

  /// No description provided for @auditBusinessActionStructure.
  ///
  /// In zh, this message translates to:
  /// **'结构修改'**
  String get auditBusinessActionStructure;

  /// No description provided for @auditBusinessActionTransfer.
  ///
  /// In zh, this message translates to:
  /// **'批量转移'**
  String get auditBusinessActionTransfer;

  /// No description provided for @auditBusinessActionTransferIn.
  ///
  /// In zh, this message translates to:
  /// **'批量转入'**
  String get auditBusinessActionTransferIn;

  /// No description provided for @auditBusinessActionCopy.
  ///
  /// In zh, this message translates to:
  /// **'批量复制'**
  String get auditBusinessActionCopy;

  /// No description provided for @auditBusinessActionCopyIn.
  ///
  /// In zh, this message translates to:
  /// **'批量复制进入'**
  String get auditBusinessActionCopyIn;

  /// No description provided for @auditBusinessActionNewLocation.
  ///
  /// In zh, this message translates to:
  /// **'新建库位'**
  String get auditBusinessActionNewLocation;

  /// No description provided for @auditBusinessActionEditLocation.
  ///
  /// In zh, this message translates to:
  /// **'编辑库位'**
  String get auditBusinessActionEditLocation;

  /// No description provided for @auditBusinessActionDeleteLocation.
  ///
  /// In zh, this message translates to:
  /// **'删除库位'**
  String get auditBusinessActionDeleteLocation;

  /// No description provided for @auditBusinessActionMarkChecked.
  ///
  /// In zh, this message translates to:
  /// **'标记已检查'**
  String get auditBusinessActionMarkChecked;

  /// No description provided for @auditBusinessActionUnmarkChecked.
  ///
  /// In zh, this message translates to:
  /// **'取消已检查'**
  String get auditBusinessActionUnmarkChecked;

  /// No description provided for @auditBusinessActionNewSku.
  ///
  /// In zh, this message translates to:
  /// **'新建SKU'**
  String get auditBusinessActionNewSku;

  /// No description provided for @auditBusinessActionEditSku.
  ///
  /// In zh, this message translates to:
  /// **'编辑SKU'**
  String get auditBusinessActionEditSku;

  /// No description provided for @auditBusinessActionDeleteSku.
  ///
  /// In zh, this message translates to:
  /// **'删除SKU'**
  String get auditBusinessActionDeleteSku;

  /// No description provided for @skuDetailInitialPreviewCarton.
  ///
  /// In zh, this message translates to:
  /// **'初始库存：{boxes}箱 × {units}件/箱 = {qty}件'**
  String skuDetailInitialPreviewCarton(int boxes, int units, int qty);

  /// No description provided for @skuDetailInitialPreviewBoxOnly.
  ///
  /// In zh, this message translates to:
  /// **'初始库存：{qty} 箱（每箱件数待定）'**
  String skuDetailInitialPreviewBoxOnly(int qty);

  /// No description provided for @skuDetailInitialPreviewQty.
  ///
  /// In zh, this message translates to:
  /// **'初始库存：{qty} 件'**
  String skuDetailInitialPreviewQty(int qty);

  /// No description provided for @locDetailAddSkuTitle.
  ///
  /// In zh, this message translates to:
  /// **'新增 SKU'**
  String get locDetailAddSkuTitle;

  /// No description provided for @locDetailEditStock.
  ///
  /// In zh, this message translates to:
  /// **'编辑库存'**
  String get locDetailEditStock;

  /// No description provided for @locDetailReselectSku.
  ///
  /// In zh, this message translates to:
  /// **'重新选择'**
  String get locDetailReselectSku;

  /// No description provided for @locDetailSearchSkuHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索编码 / 名称 / 条码'**
  String get locDetailSearchSkuHint;

  /// No description provided for @locDetailNewSkuButton.
  ///
  /// In zh, this message translates to:
  /// **'+ 新建货号'**
  String get locDetailNewSkuButton;

  /// No description provided for @locDetailOperationFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试'**
  String get locDetailOperationFailedRetry;

  /// No description provided for @locDetailParamError.
  ///
  /// In zh, this message translates to:
  /// **'参数错误，请检查输入'**
  String get locDetailParamError;

  /// No description provided for @locDetailTotalPcs.
  ///
  /// In zh, this message translates to:
  /// **'共 {qty} 件'**
  String locDetailTotalPcs(int qty);

  /// No description provided for @locDetailConfigCarton.
  ///
  /// In zh, this message translates to:
  /// **'{boxes}箱 × {units}件/箱'**
  String locDetailConfigCarton(int boxes, int units);

  /// No description provided for @errPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'权限不足，无法执行此操作'**
  String get errPermissionDenied;

  /// No description provided for @errSessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录已过期，请重新登录'**
  String get errSessionExpired;

  /// No description provided for @errResourceNotFound.
  ///
  /// In zh, this message translates to:
  /// **'目标资源不存在，请刷新后重试'**
  String get errResourceNotFound;

  /// No description provided for @errRequestFailed.
  ///
  /// In zh, this message translates to:
  /// **'请求失败（{code}），请重试'**
  String errRequestFailed(int code);

  /// No description provided for @errCannotConnectServer.
  ///
  /// In zh, this message translates to:
  /// **'无法连接服务器，请检查网络'**
  String get errCannotConnectServer;

  /// No description provided for @errNetworkFailed.
  ///
  /// In zh, this message translates to:
  /// **'网络请求失败，请重试'**
  String get errNetworkFailed;

  /// No description provided for @errOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试'**
  String get errOperationFailed;

  /// No description provided for @invDetailQtyUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未填写'**
  String get invDetailQtyUnknown;

  /// No description provided for @invDetailBoxesSuffix.
  ///
  /// In zh, this message translates to:
  /// **'箱'**
  String get invDetailBoxesSuffix;

  /// No description provided for @invDetailPieceSuffix.
  ///
  /// In zh, this message translates to:
  /// **'件'**
  String get invDetailPieceSuffix;

  /// No description provided for @invDetailUnitsPerBoxSuffix.
  ///
  /// In zh, this message translates to:
  /// **'件/箱'**
  String get invDetailUnitsPerBoxSuffix;

  /// No description provided for @invDetailCurrentStatusPending.
  ///
  /// In zh, this message translates to:
  /// **'当前状态: 待清点'**
  String get invDetailCurrentStatusPending;

  /// No description provided for @invDetailCurrentStock.
  ///
  /// In zh, this message translates to:
  /// **'当前库存: {label}'**
  String invDetailCurrentStock(String label);

  /// No description provided for @invDetailQtyEntryMode.
  ///
  /// In zh, this message translates to:
  /// **'录入方式'**
  String get invDetailQtyEntryMode;

  /// No description provided for @invDetailModeByCarton.
  ///
  /// In zh, this message translates to:
  /// **'按箱规'**
  String get invDetailModeByCarton;

  /// No description provided for @invDetailModeBoxesOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅箱数'**
  String get invDetailModeBoxesOnly;

  /// No description provided for @invDetailModeByQty.
  ///
  /// In zh, this message translates to:
  /// **'按总数量'**
  String get invDetailModeByQty;

  /// No description provided for @invDetailBoxesLabel.
  ///
  /// In zh, this message translates to:
  /// **'箱数 *'**
  String get invDetailBoxesLabel;

  /// No description provided for @invDetailPendingBoxes.
  ///
  /// In zh, this message translates to:
  /// **'暂存箱数: '**
  String get invDetailPendingBoxes;

  /// No description provided for @invDetailStockInBoxes.
  ///
  /// In zh, this message translates to:
  /// **'入库箱数: '**
  String get invDetailStockInBoxes;

  /// No description provided for @invDetailBoxesValue.
  ///
  /// In zh, this message translates to:
  /// **'{boxes} 箱'**
  String invDetailBoxesValue(int boxes);

  /// No description provided for @invDetailCartonTBD.
  ///
  /// In zh, this message translates to:
  /// **'  · 箱规待确认'**
  String get invDetailCartonTBD;

  /// No description provided for @invDetailStockInTotal.
  ///
  /// In zh, this message translates to:
  /// **'入库总量: '**
  String get invDetailStockInTotal;

  /// No description provided for @invDetailAddQty.
  ///
  /// In zh, this message translates to:
  /// **'+ {qty} 件'**
  String invDetailAddQty(int qty);

  /// No description provided for @invDetailNewTotal.
  ///
  /// In zh, this message translates to:
  /// **'  →  {total} 件'**
  String invDetailNewTotal(int total);

  /// No description provided for @invDetailStockInQtyLabel.
  ///
  /// In zh, this message translates to:
  /// **'入库件数 *'**
  String get invDetailStockInQtyLabel;

  /// No description provided for @invDetailAddConfigRow.
  ///
  /// In zh, this message translates to:
  /// **'+ 添加规格'**
  String get invDetailAddConfigRow;

  /// No description provided for @invDetailPendingMarkNote.
  ///
  /// In zh, this message translates to:
  /// **'将标记此库存为【待清点】，当前数量不变。后续确认后可通过【调整】更新数量。'**
  String get invDetailPendingMarkNote;

  /// No description provided for @invDetailErrInvalidBoxes.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效箱数'**
  String get invDetailErrInvalidBoxes;

  /// No description provided for @invDetailErrInvalidBoxesAndUnits.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的箱数和每箱件数'**
  String get invDetailErrInvalidBoxesAndUnits;

  /// No description provided for @invDetailErrInvalidQty.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效件数'**
  String get invDetailErrInvalidQty;

  /// No description provided for @invDetailConfirmPendingBtn.
  ///
  /// In zh, this message translates to:
  /// **'确认暂存'**
  String get invDetailConfirmPendingBtn;

  /// No description provided for @invDetailConfirmStockIn.
  ///
  /// In zh, this message translates to:
  /// **'确认入库'**
  String get invDetailConfirmStockIn;

  /// No description provided for @invDetailStockInTitle.
  ///
  /// In zh, this message translates to:
  /// **'入库'**
  String get invDetailStockInTitle;

  /// No description provided for @invDetailStockOutTitle.
  ///
  /// In zh, this message translates to:
  /// **'出库'**
  String get invDetailStockOutTitle;

  /// No description provided for @invDetailOutTotal.
  ///
  /// In zh, this message translates to:
  /// **'出库总量: '**
  String get invDetailOutTotal;

  /// No description provided for @invDetailOutBoxesValue.
  ///
  /// In zh, this message translates to:
  /// **'{boxes} 箱'**
  String invDetailOutBoxesValue(int boxes);

  /// No description provided for @invDetailOutPcsValue.
  ///
  /// In zh, this message translates to:
  /// **'{qty} 件'**
  String invDetailOutPcsValue(int qty);

  /// No description provided for @invDetailRemainCartonBoxes.
  ///
  /// In zh, this message translates to:
  /// **'  →  剩余 {boxes} 箱'**
  String invDetailRemainCartonBoxes(int boxes);

  /// No description provided for @invDetailRemainBoxes.
  ///
  /// In zh, this message translates to:
  /// **'  →  剩余 {boxes} 箱'**
  String invDetailRemainBoxes(int boxes);

  /// No description provided for @invDetailRemainPcs.
  ///
  /// In zh, this message translates to:
  /// **'  →  剩余 {qty} 件'**
  String invDetailRemainPcs(int qty);

  /// No description provided for @invDetailNoCartonData.
  ///
  /// In zh, this message translates to:
  /// **'当前无箱规数据，请使用其他模式'**
  String get invDetailNoCartonData;

  /// No description provided for @invDetailSelectOutBoxes.
  ///
  /// In zh, this message translates to:
  /// **'选择出库箱数:'**
  String get invDetailSelectOutBoxes;

  /// No description provided for @invDetailOutBoxesColHeader.
  ///
  /// In zh, this message translates to:
  /// **'出库箱数'**
  String get invDetailOutBoxesColHeader;

  /// No description provided for @invDetailUnitsPerBoxDisplay.
  ///
  /// In zh, this message translates to:
  /// **'{units}件/箱'**
  String invDetailUnitsPerBoxDisplay(int units);

  /// No description provided for @invDetailTotalBoxesDisplay.
  ///
  /// In zh, this message translates to:
  /// **'共{boxes}箱'**
  String invDetailTotalBoxesDisplay(int boxes);

  /// No description provided for @invDetailOutMaxBoxes.
  ///
  /// In zh, this message translates to:
  /// **'出库 (最多{boxes}箱)'**
  String invDetailOutMaxBoxes(int boxes);

  /// No description provided for @invDetailExceedBoxes.
  ///
  /// In zh, this message translates to:
  /// **'超出可用{boxes}箱'**
  String invDetailExceedBoxes(int boxes);

  /// No description provided for @invDetailEqPcs.
  ///
  /// In zh, this message translates to:
  /// **'= {qty}件'**
  String invDetailEqPcs(int qty);

  /// No description provided for @invDetailOutBoxesLabel.
  ///
  /// In zh, this message translates to:
  /// **'出库箱数 * (最多 {boxes} 箱)'**
  String invDetailOutBoxesLabel(int boxes);

  /// No description provided for @invDetailBoxesOnlyHelp.
  ///
  /// In zh, this message translates to:
  /// **'适用：箱规不确定，仅按箱数出库。'**
  String get invDetailBoxesOnlyHelp;

  /// No description provided for @invDetailOutQtyLabel.
  ///
  /// In zh, this message translates to:
  /// **'出库件数 *'**
  String get invDetailOutQtyLabel;

  /// No description provided for @invDetailErrNegativeBoxes.
  ///
  /// In zh, this message translates to:
  /// **'出库箱数不能为负数'**
  String get invDetailErrNegativeBoxes;

  /// No description provided for @invDetailErrExceedCartonBoxes.
  ///
  /// In zh, this message translates to:
  /// **'{units}件/箱：超过可用箱数 ({boxes} 箱)'**
  String invDetailErrExceedCartonBoxes(int units, int boxes);

  /// No description provided for @invDetailErrAtLeastOneCarton.
  ///
  /// In zh, this message translates to:
  /// **'请至少输入一种箱规的出库数量'**
  String get invDetailErrAtLeastOneCarton;

  /// No description provided for @invDetailErrExceedStockBoxes.
  ///
  /// In zh, this message translates to:
  /// **'出库数量不能超过当前库存（{boxes} 箱）'**
  String invDetailErrExceedStockBoxes(int boxes);

  /// No description provided for @invDetailErrExceedStockPcs.
  ///
  /// In zh, this message translates to:
  /// **'出库数量不能超过当前库存（{qty} 件）'**
  String invDetailErrExceedStockPcs(int qty);

  /// No description provided for @invDetailConfirmStockOut.
  ///
  /// In zh, this message translates to:
  /// **'确认出库'**
  String get invDetailConfirmStockOut;

  /// No description provided for @invDetailAdjustTitle.
  ///
  /// In zh, this message translates to:
  /// **'库存调整'**
  String get invDetailAdjustTitle;

  /// No description provided for @invDetailAdjustedTotalLabel.
  ///
  /// In zh, this message translates to:
  /// **'调整后总件数 *'**
  String get invDetailAdjustedTotalLabel;

  /// No description provided for @invDetailAdjustQtyHelp.
  ///
  /// In zh, this message translates to:
  /// **'适用场景：盘点差异、货损等，直接修正总件数。'**
  String get invDetailAdjustQtyHelp;

  /// No description provided for @invDetailBoxesOnlyPanelHelp.
  ///
  /// In zh, this message translates to:
  /// **'每箱件数保持不变，仅修改各规格箱数：'**
  String get invDetailBoxesOnlyPanelHelp;

  /// No description provided for @invDetailSubtotalPcs.
  ///
  /// In zh, this message translates to:
  /// **'={qty}件'**
  String invDetailSubtotalPcs(int qty);

  /// No description provided for @invDetailCartonGroupsLabel.
  ///
  /// In zh, this message translates to:
  /// **'各箱规库存（最多3组）:'**
  String get invDetailCartonGroupsLabel;

  /// No description provided for @invDetailAddCarton.
  ///
  /// In zh, this message translates to:
  /// **'新增箱规'**
  String get invDetailAddCarton;

  /// No description provided for @invDetailAddFirstCarton.
  ///
  /// In zh, this message translates to:
  /// **'添加第一组箱规'**
  String get invDetailAddFirstCarton;

  /// No description provided for @invDetailUnitsPerBoxLabel.
  ///
  /// In zh, this message translates to:
  /// **'件/箱'**
  String get invDetailUnitsPerBoxLabel;

  /// No description provided for @invDetailBoxesAdjustLabel.
  ///
  /// In zh, this message translates to:
  /// **'箱数'**
  String get invDetailBoxesAdjustLabel;

  /// No description provided for @invDetailSkuCorrectCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前：'**
  String get invDetailSkuCorrectCurrent;

  /// No description provided for @invDetailSkuCorrectSelectHint.
  ///
  /// In zh, this message translates to:
  /// **'（请从下方选择）'**
  String get invDetailSkuCorrectSelectHint;

  /// No description provided for @invDetailSkuCorrectSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索新 SKU 编码或名称'**
  String get invDetailSkuCorrectSearch;

  /// No description provided for @invDetailQtyRetained.
  ///
  /// In zh, this message translates to:
  /// **'库存数量 {label} 将保留不变'**
  String invDetailQtyRetained(String label);

  /// No description provided for @invDetailAdjustModeMixed.
  ///
  /// In zh, this message translates to:
  /// **'混合'**
  String get invDetailAdjustModeMixed;

  /// No description provided for @invDetailAdjustModeQty.
  ///
  /// In zh, this message translates to:
  /// **'总数量'**
  String get invDetailAdjustModeQty;

  /// No description provided for @invDetailAdjustModeBoxesOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅箱数'**
  String get invDetailAdjustModeBoxesOnly;

  /// No description provided for @invDetailAdjustModeCarton.
  ///
  /// In zh, this message translates to:
  /// **'按箱规'**
  String get invDetailAdjustModeCarton;

  /// No description provided for @invDetailAdjustModeSkuCorrect.
  ///
  /// In zh, this message translates to:
  /// **'SKU更正'**
  String get invDetailAdjustModeSkuCorrect;

  /// No description provided for @invDetailReasonSkuCorrect.
  ///
  /// In zh, this message translates to:
  /// **'更正原因 *（必填）'**
  String get invDetailReasonSkuCorrect;

  /// No description provided for @invDetailReasonAdjust.
  ///
  /// In zh, this message translates to:
  /// **'调整原因 *（必填）'**
  String get invDetailReasonAdjust;

  /// No description provided for @invDetailReasonSkuCorrectHint.
  ///
  /// In zh, this message translates to:
  /// **'例：录错货号、暂存转正式SKU'**
  String get invDetailReasonSkuCorrectHint;

  /// No description provided for @invDetailReasonAdjustHint.
  ///
  /// In zh, this message translates to:
  /// **'例：盘点差异、货损、退货补库'**
  String get invDetailReasonAdjustHint;

  /// No description provided for @invDetailErrReasonRequired.
  ///
  /// In zh, this message translates to:
  /// **'请填写原因（必填）'**
  String get invDetailErrReasonRequired;

  /// No description provided for @invDetailErrSelectNewSku.
  ///
  /// In zh, this message translates to:
  /// **'请从下拉列表中选择新 SKU'**
  String get invDetailErrSelectNewSku;

  /// No description provided for @invDetailErrSameSkuNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'新旧 SKU 不能相同'**
  String get invDetailErrSameSkuNotAllowed;

  /// No description provided for @invDetailErrNoInventoryId.
  ///
  /// In zh, this message translates to:
  /// **'无法获取库存记录 ID，请关闭后重试'**
  String get invDetailErrNoInventoryId;

  /// No description provided for @invDetailErrAtLeastOneBoxesGroup.
  ///
  /// In zh, this message translates to:
  /// **'至少填写一组的箱数（> 0）'**
  String get invDetailErrAtLeastOneBoxesGroup;

  /// No description provided for @invDetailErrAtLeastOneCartonGroup.
  ///
  /// In zh, this message translates to:
  /// **'至少需要一组箱规'**
  String get invDetailErrAtLeastOneCartonGroup;

  /// No description provided for @invDetailErrValidCartonGroup.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的箱数和每箱件数（均需 > 0）'**
  String get invDetailErrValidCartonGroup;

  /// No description provided for @invDetailErrValidQtyGte0.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效件数（≥ 0）'**
  String get invDetailErrValidQtyGte0;

  /// No description provided for @invDetailErrMixedEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请至少输入一条箱规或散件数'**
  String get invDetailErrMixedEmpty;

  /// No description provided for @invDetailErrMixedInvalidSpec.
  ///
  /// In zh, this message translates to:
  /// **'所有箱规的箱数和每箱件数均需大于 0'**
  String get invDetailErrMixedInvalidSpec;

  /// No description provided for @invDetailLoosePcsLabel.
  ///
  /// In zh, this message translates to:
  /// **'散件（不足整箱）'**
  String get invDetailLoosePcsLabel;

  /// No description provided for @invDetailCartonSpecsLabel.
  ///
  /// In zh, this message translates to:
  /// **'箱规'**
  String get invDetailCartonSpecsLabel;

  /// No description provided for @invDetailConfirmSkuCorrect.
  ///
  /// In zh, this message translates to:
  /// **'确认更正'**
  String get invDetailConfirmSkuCorrect;

  /// No description provided for @invDetailConfirmBoxesAdjust.
  ///
  /// In zh, this message translates to:
  /// **'确认箱数调整'**
  String get invDetailConfirmBoxesAdjust;

  /// No description provided for @invDetailConfirmAdjust.
  ///
  /// In zh, this message translates to:
  /// **'确认调整'**
  String get invDetailConfirmAdjust;

  /// No description provided for @invDetailAdjustedTotalRow.
  ///
  /// In zh, this message translates to:
  /// **'调整后总库存: '**
  String get invDetailAdjustedTotalRow;

  /// No description provided for @invDetailBoxesLabelStar.
  ///
  /// In zh, this message translates to:
  /// **'箱数 *'**
  String get invDetailBoxesLabelStar;

  /// No description provided for @invDetailUnitsLabelStar.
  ///
  /// In zh, this message translates to:
  /// **'每箱件数 *'**
  String get invDetailUnitsLabelStar;

  /// No description provided for @invDetailNoteOptional.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get invDetailNoteOptional;

  /// No description provided for @invDetailQtyUnknownHeader.
  ///
  /// In zh, this message translates to:
  /// **'待补充库存信息'**
  String get invDetailQtyUnknownHeader;

  /// No description provided for @invDetailBoxesOnlyHeader.
  ///
  /// In zh, this message translates to:
  /// **'{boxes}箱 · 箱规待确认'**
  String invDetailBoxesOnlyHeader(int boxes);

  /// No description provided for @invDetailBoxesAndPcs.
  ///
  /// In zh, this message translates to:
  /// **'{boxes}箱 · {qty}件'**
  String invDetailBoxesAndPcs(int boxes, int qty);

  /// No description provided for @invDetailStockIn.
  ///
  /// In zh, this message translates to:
  /// **'入库'**
  String get invDetailStockIn;

  /// No description provided for @invDetailStockOut.
  ///
  /// In zh, this message translates to:
  /// **'出库'**
  String get invDetailStockOut;

  /// No description provided for @invDetailAdjust.
  ///
  /// In zh, this message translates to:
  /// **'库存调整'**
  String get invDetailAdjust;

  /// No description provided for @invDetailConfirmPendingLabel.
  ///
  /// In zh, this message translates to:
  /// **'确认为正式'**
  String get invDetailConfirmPendingLabel;

  /// No description provided for @invDetailSplitPendingLabel.
  ///
  /// In zh, this message translates to:
  /// **'拆分为正式SKU'**
  String get invDetailSplitPendingLabel;

  /// No description provided for @invDetailSkuDetail.
  ///
  /// In zh, this message translates to:
  /// **'SKU 详情'**
  String get invDetailSkuDetail;

  /// No description provided for @invDetailLocDetail.
  ///
  /// In zh, this message translates to:
  /// **'库位详情'**
  String get invDetailLocDetail;

  /// No description provided for @invDetailRecentOps.
  ///
  /// In zh, this message translates to:
  /// **'最近操作'**
  String get invDetailRecentOps;

  /// No description provided for @invDetailViewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部记录'**
  String get invDetailViewAll;

  /// No description provided for @invDetailLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败，点击重试'**
  String get invDetailLoadFailed;

  /// No description provided for @invDetailNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无操作记录'**
  String get invDetailNoRecords;

  /// No description provided for @invDetailConfirmOfficialTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认为正式库存'**
  String get invDetailConfirmOfficialTitle;

  /// No description provided for @invDetailPendingToOfficial.
  ///
  /// In zh, this message translates to:
  /// **'暂存 → 正式库存'**
  String get invDetailPendingToOfficial;

  /// No description provided for @invDetailCorrectSkuCode.
  ///
  /// In zh, this message translates to:
  /// **'同时更正SKU编码'**
  String get invDetailCorrectSkuCode;

  /// No description provided for @invDetailSearchNewSku.
  ///
  /// In zh, this message translates to:
  /// **'搜索新 SKU 编码或名称'**
  String get invDetailSearchNewSku;

  /// No description provided for @invDetailConfirmReasonLabel.
  ///
  /// In zh, this message translates to:
  /// **'原因 *'**
  String get invDetailConfirmReasonLabel;

  /// No description provided for @invDetailConfirmReasonHint.
  ///
  /// In zh, this message translates to:
  /// **'请说明确认原因'**
  String get invDetailConfirmReasonHint;

  /// No description provided for @invDetailErrReasonEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请填写原因'**
  String get invDetailErrReasonEmpty;

  /// No description provided for @invDetailErrSelectNewSkuCode.
  ///
  /// In zh, this message translates to:
  /// **'请从下拉列表中选择新SKU编码'**
  String get invDetailErrSelectNewSkuCode;

  /// No description provided for @invDetailConfirmedOfficial.
  ///
  /// In zh, this message translates to:
  /// **'已确认为正式库存'**
  String get invDetailConfirmedOfficial;

  /// No description provided for @invDetailConfirmToOfficial.
  ///
  /// In zh, this message translates to:
  /// **'确认转正式'**
  String get invDetailConfirmToOfficial;

  /// No description provided for @invDetailSplitTitle.
  ///
  /// In zh, this message translates to:
  /// **'拆分为正式SKU'**
  String get invDetailSplitTitle;

  /// No description provided for @invDetailSplitSource.
  ///
  /// In zh, this message translates to:
  /// **'原暂存: {sku}'**
  String invDetailSplitSource(String sku);

  /// No description provided for @invDetailSplitSourceInfo.
  ///
  /// In zh, this message translates to:
  /// **'{locationCode}  ·  录入方式：{sourceLabel}'**
  String invDetailSplitSourceInfo(String locationCode, String sourceLabel);

  /// No description provided for @invDetailSplitTotalConserve.
  ///
  /// In zh, this message translates to:
  /// **'总量 {amount} {unit}  ·  按{unit}守恒'**
  String invDetailSplitTotalConserve(int amount, String unit);

  /// No description provided for @invDetailSplitBalanced.
  ///
  /// In zh, this message translates to:
  /// **'✓ 已平衡'**
  String get invDetailSplitBalanced;

  /// No description provided for @invDetailSplitProgress.
  ///
  /// In zh, this message translates to:
  /// **'已分 {total} / {original}'**
  String invDetailSplitProgress(int total, int original);

  /// No description provided for @invDetailSplitNoSku.
  ///
  /// In zh, this message translates to:
  /// **'未选择SKU'**
  String get invDetailSplitNoSku;

  /// No description provided for @invDetailSplitModeByCarton.
  ///
  /// In zh, this message translates to:
  /// **'按箱规'**
  String get invDetailSplitModeByCarton;

  /// No description provided for @invDetailSplitModeBoxesOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅箱数'**
  String get invDetailSplitModeBoxesOnly;

  /// No description provided for @invDetailSplitModeByQty.
  ///
  /// In zh, this message translates to:
  /// **'按总数量'**
  String get invDetailSplitModeByQty;

  /// No description provided for @invDetailSplitSearchSku.
  ///
  /// In zh, this message translates to:
  /// **'搜索 SKU'**
  String get invDetailSplitSearchSku;

  /// No description provided for @invDetailSplitBoxesLabel.
  ///
  /// In zh, this message translates to:
  /// **'箱数'**
  String get invDetailSplitBoxesLabel;

  /// No description provided for @invDetailSplitBoxesSuffix.
  ///
  /// In zh, this message translates to:
  /// **'箱'**
  String get invDetailSplitBoxesSuffix;

  /// No description provided for @invDetailSplitUnitsLabel.
  ///
  /// In zh, this message translates to:
  /// **'件/箱'**
  String get invDetailSplitUnitsLabel;

  /// No description provided for @invDetailSplitUnitsSuffix.
  ///
  /// In zh, this message translates to:
  /// **'件/箱'**
  String get invDetailSplitUnitsSuffix;

  /// No description provided for @invDetailSplitCartonTBD.
  ///
  /// In zh, this message translates to:
  /// **'· 箱规待确认'**
  String get invDetailSplitCartonTBD;

  /// No description provided for @invDetailSplitTotalQtyLabel.
  ///
  /// In zh, this message translates to:
  /// **'总件数'**
  String get invDetailSplitTotalQtyLabel;

  /// No description provided for @invDetailSplitTotalQtySuffix.
  ///
  /// In zh, this message translates to:
  /// **'件'**
  String get invDetailSplitTotalQtySuffix;

  /// No description provided for @invDetailSplitCalcPcs.
  ///
  /// In zh, this message translates to:
  /// **'= {qty} 件'**
  String invDetailSplitCalcPcs(int qty);

  /// No description provided for @invDetailAddSplitTarget.
  ///
  /// In zh, this message translates to:
  /// **'添加拆分目标'**
  String get invDetailAddSplitTarget;

  /// No description provided for @invDetailSplitReasonLabel.
  ///
  /// In zh, this message translates to:
  /// **'拆分原因 *'**
  String get invDetailSplitReasonLabel;

  /// No description provided for @invDetailSplitReasonHint.
  ///
  /// In zh, this message translates to:
  /// **'请说明拆分原因'**
  String get invDetailSplitReasonHint;

  /// No description provided for @invDetailErrSplitReasonEmpty.
  ///
  /// In zh, this message translates to:
  /// **'请填写拆分原因'**
  String get invDetailErrSplitReasonEmpty;

  /// No description provided for @invDetailErrSplitSelectSku.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 条：请从下拉列表中选择SKU'**
  String invDetailErrSplitSelectSku(int index);

  /// No description provided for @invDetailErrSplitBoxesMustBePositive.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 条箱数必须大于0'**
  String invDetailErrSplitBoxesMustBePositive(int index);

  /// No description provided for @invDetailErrSplitUnitsMustBePositive.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 条件/箱必须大于0'**
  String invDetailErrSplitUnitsMustBePositive(int index);

  /// No description provided for @invDetailErrSplitTotalQtyMustBePositive.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 条总件数必须大于0'**
  String invDetailErrSplitTotalQtyMustBePositive(int index);

  /// No description provided for @invDetailErrSplitUnbalanced.
  ///
  /// In zh, this message translates to:
  /// **'拆分总量 {total} {unit} ≠ 原暂存 {original} {unit}，请调整'**
  String invDetailErrSplitUnbalanced(int total, int original, String unit);

  /// No description provided for @invDetailSplitSuccess.
  ///
  /// In zh, this message translates to:
  /// **'拆分成功，正式SKU已创建'**
  String get invDetailSplitSuccess;

  /// No description provided for @invDetailConfirmSplit.
  ///
  /// In zh, this message translates to:
  /// **'确认拆分'**
  String get invDetailConfirmSplit;

  /// No description provided for @invDetailSourceModeBoxesOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅箱数'**
  String get invDetailSourceModeBoxesOnly;

  /// No description provided for @invDetailSourceModeQty.
  ///
  /// In zh, this message translates to:
  /// **'按总数量'**
  String get invDetailSourceModeQty;

  /// No description provided for @invDetailSourceModeCarton.
  ///
  /// In zh, this message translates to:
  /// **'按箱规'**
  String get invDetailSourceModeCarton;

  /// No description provided for @invDetailMergeConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'目标SKU已有库存'**
  String get invDetailMergeConfirmTitle;

  /// No description provided for @invDetailMergeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认合并'**
  String get invDetailMergeConfirm;

  /// No description provided for @invDetailSkuSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'输入编码或品名搜索'**
  String get invDetailSkuSearchHint;

  /// No description provided for @invDetailSkuNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的SKU'**
  String get invDetailSkuNotFound;

  /// No description provided for @invDetailSkuArchived.
  ///
  /// In zh, this message translates to:
  /// **'已停用'**
  String get invDetailSkuArchived;

  /// No description provided for @invDetailDefaultAction.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get invDetailDefaultAction;

  /// No description provided for @invHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'入出库记录'**
  String get invHistoryTitle;

  /// No description provided for @invHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无出入库记录'**
  String get invHistoryEmpty;

  /// No description provided for @invHistoryEmptyFiltered.
  ///
  /// In zh, this message translates to:
  /// **'没有符合条件的记录'**
  String get invHistoryEmptyFiltered;

  /// No description provided for @invHistoryViewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部类型'**
  String get invHistoryViewAll;

  /// No description provided for @invHistorySplitSrc.
  ///
  /// In zh, this message translates to:
  /// **'原暂存'**
  String get invHistorySplitSrc;

  /// No description provided for @invHistorySplitTargets.
  ///
  /// In zh, this message translates to:
  /// **'拆分目标'**
  String get invHistorySplitTargets;

  /// No description provided for @invHistorySplitCleared.
  ///
  /// In zh, this message translates to:
  /// **'原记录已清零（拆分完成）'**
  String get invHistorySplitCleared;

  /// No description provided for @invHistoryReason.
  ///
  /// In zh, this message translates to:
  /// **'原因'**
  String get invHistoryReason;

  /// No description provided for @errApiNotFound.
  ///
  /// In zh, this message translates to:
  /// **'接口不存在，请联系管理员'**
  String get errApiNotFound;

  /// No description provided for @errPermission.
  ///
  /// In zh, this message translates to:
  /// **'无权限查看此记录'**
  String get errPermission;

  /// No description provided for @errLoadRetry.
  ///
  /// In zh, this message translates to:
  /// **'加载失败，请重试'**
  String get errLoadRetry;

  /// No description provided for @userMgmtTitle.
  ///
  /// In zh, this message translates to:
  /// **'用户管理'**
  String get userMgmtTitle;

  /// No description provided for @userMgmtCreateBtn.
  ///
  /// In zh, this message translates to:
  /// **'创建账号'**
  String get userMgmtCreateBtn;

  /// No description provided for @userMgmtCreateTitle.
  ///
  /// In zh, this message translates to:
  /// **'创建账号'**
  String get userMgmtCreateTitle;

  /// No description provided for @userMgmtUsernameLabel.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get userMgmtUsernameLabel;

  /// No description provided for @userMgmtDisplayNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'显示名称'**
  String get userMgmtDisplayNameLabel;

  /// No description provided for @userMgmtInitPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'初始密码（至少6位）'**
  String get userMgmtInitPasswordLabel;

  /// No description provided for @userMgmtRoleLabel.
  ///
  /// In zh, this message translates to:
  /// **'角色'**
  String get userMgmtRoleLabel;

  /// No description provided for @userMgmtRoleAdmin.
  ///
  /// In zh, this message translates to:
  /// **'管理员'**
  String get userMgmtRoleAdmin;

  /// No description provided for @userMgmtRoleSupervisor.
  ///
  /// In zh, this message translates to:
  /// **'仓库主管'**
  String get userMgmtRoleSupervisor;

  /// No description provided for @userMgmtRoleStaff.
  ///
  /// In zh, this message translates to:
  /// **'普通员工'**
  String get userMgmtRoleStaff;

  /// No description provided for @userMgmtCreateValidation.
  ///
  /// In zh, this message translates to:
  /// **'请填写完整信息，密码至少6位'**
  String get userMgmtCreateValidation;

  /// No description provided for @userMgmtCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败'**
  String get userMgmtCreateFailed;

  /// No description provided for @userMgmtEditRoleTitle.
  ///
  /// In zh, this message translates to:
  /// **'修改角色'**
  String get userMgmtEditRoleTitle;

  /// No description provided for @userMgmtLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败: {error}'**
  String userMgmtLoadFailed(String error);

  /// No description provided for @userMgmtMe.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get userMgmtMe;

  /// No description provided for @userMgmtDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已停用'**
  String get userMgmtDisabled;

  /// No description provided for @userMgmtToggleTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认{action}'**
  String userMgmtToggleTitle(String action);

  /// No description provided for @userMgmtToggleContent.
  ///
  /// In zh, this message translates to:
  /// **'确定要{action}该账号吗？{notice}'**
  String userMgmtToggleContent(String action, String notice);

  /// No description provided for @userMgmtDisableNotice.
  ///
  /// In zh, this message translates to:
  /// **'停用后该用户将无法登录。'**
  String get userMgmtDisableNotice;

  /// No description provided for @userMgmtEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get userMgmtEnable;

  /// No description provided for @userMgmtDisable.
  ///
  /// In zh, this message translates to:
  /// **'停用'**
  String get userMgmtDisable;

  /// No description provided for @userMgmtResetPasswordTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置密码'**
  String get userMgmtResetPasswordTitle;

  /// No description provided for @userMgmtNewPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'新密码（至少6位）'**
  String get userMgmtNewPasswordLabel;

  /// No description provided for @userMgmtPasswordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'密码至少6位'**
  String get userMgmtPasswordTooShort;

  /// No description provided for @userMgmtPasswordReset.
  ///
  /// In zh, this message translates to:
  /// **'密码已重置'**
  String get userMgmtPasswordReset;

  /// No description provided for @userMgmtResetFailed.
  ///
  /// In zh, this message translates to:
  /// **'重置失败'**
  String get userMgmtResetFailed;

  /// No description provided for @userMgmtResetBtn.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get userMgmtResetBtn;

  /// No description provided for @userMgmtOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get userMgmtOperationFailed;

  /// No description provided for @clearDoneMsg.
  ///
  /// In zh, this message translates to:
  /// **'清空完成：库存 {inv} 条，SKU {sku} 条，库位 {loc} 条，流水 {tx} 条，日志 {log} 条，导入记录 {imp} 条'**
  String clearDoneMsg(
      Object inv, Object sku, Object loc, Object tx, Object log, Object imp);
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
