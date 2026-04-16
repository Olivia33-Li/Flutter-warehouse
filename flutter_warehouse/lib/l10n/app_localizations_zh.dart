// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '仓库管理系统';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get save => '保存';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get continue_ => '继续';

  @override
  String get loginUsername => '用户名';

  @override
  String get loginPassword => '密码';

  @override
  String get loginRememberMe => '记住我';

  @override
  String get loginForgotPassword => '忘记密码？';

  @override
  String get loginButton => '登录';

  @override
  String get loginNoAccount => '还没有账号？';

  @override
  String get loginRegister => '注册';

  @override
  String get loginEmptyError => '请输入用户名和密码';

  @override
  String get loginFailedNetwork => '登录失败，请检查网络';

  @override
  String get loginRecentTitle => '最近登录';

  @override
  String get loginClearAll => '清除全部';

  @override
  String get loginClearAllTitle => '清空记录';

  @override
  String get loginClearAllContent => '确定清除本设备所有已记住的账号？';

  @override
  String get loginUseOtherAccount => '使用其他账号登录';

  @override
  String get registerTitle => '注册账号';

  @override
  String get registerSubtitle => '创建账号后即可使用仓库管理系统';

  @override
  String get registerName => '姓名 / 显示名';

  @override
  String get registerConfirmPassword => '确认密码';

  @override
  String get registerButton => '注册';

  @override
  String get registerHaveAccount => '已有账号？';

  @override
  String get registerValidation => '请填写完整信息，密码至少6位';

  @override
  String get registerPasswordMismatch => '两次输入的密码不一致';

  @override
  String get registerFailed => '注册失败';

  @override
  String get passwordRuleLength => '6–20 位字符';

  @override
  String get passwordRuleLowercase => '包含小写字母';

  @override
  String get passwordRuleDigit => '包含数字';

  @override
  String get passwordRuleAlnum => '仅限小写字母和数字';

  @override
  String get forgotTitle => '忘记密码';

  @override
  String get forgotSubtitle => '请联系管理员重置您的账号密码。\n填写用户名后提交申请，管理员会尽快处理。';

  @override
  String get forgotAdminContact => '联系管理员';

  @override
  String get forgotAdminDesc =>
      '仓库管理系统的密码由管理员统一管理。请联系您的仓库主管或系统管理员，告知您的用户名，由管理员为您重置密码。';

  @override
  String get forgotNote => '备注（可选）—— 如：联系方式 / 具体情况';

  @override
  String get forgotSubmit => '提交申请';

  @override
  String get forgotDismiss => '我知道了';

  @override
  String get forgotSuccessTitle => '申请已提交';

  @override
  String get forgotSuccessDesc => '管理员收到您的申请后将重置密码\n并告知您临时密码，请耐心等待。';

  @override
  String get forgotBackToLogin => '返回登录';

  @override
  String get forgotEmptyError => '请输入您的用户名';

  @override
  String get forgotSubmitFailed => '提交失败，请重试';

  @override
  String get forceChangeTitle => '请修改密码';

  @override
  String get forceChangeNotice => '管理员已重置您的密码。请先修改密码后再继续使用系统。';

  @override
  String get forceChangeOldPassword => '当前密码（临时密码）';

  @override
  String get forceChangeNewPassword => '新密码（至少 6 位）';

  @override
  String get forceChangeConfirmPassword => '确认新密码';

  @override
  String get forceChangeButton => '确认修改';

  @override
  String get forceChangeEmptyError => '请填写所有字段';

  @override
  String get forceChangeShortError => '新密码至少需要 6 位';

  @override
  String get forceChangeMismatchError => '两次输入的新密码不一致';

  @override
  String get forceChangeSameError => '新密码不能与当前密码相同';

  @override
  String get forceChangeFailed => '修改失败，请重试';

  @override
  String get navSku => 'SKU';

  @override
  String get navLocation => '位置';

  @override
  String get navScanner => '扫码';

  @override
  String get navHistory => '记录';

  @override
  String get navSettings => '设置';

  @override
  String get skuScreenTitle => 'SKU 搜索';

  @override
  String get skuSearchHint => '搜索 SKU / 名称 / 条码...';

  @override
  String get skuFilterActive => '在用';

  @override
  String get skuFilterAll => '含已归档';

  @override
  String get skuFilterArchived => '仅归档';

  @override
  String get skuEmptyArchived => '暂无归档 SKU';

  @override
  String get skuEmpty => '暂无 SKU';

  @override
  String skuNoResult(String query) {
    return '未找到 \"$query\"';
  }

  @override
  String get skuSearchTip => '尝试缩短关键词，或忽略分隔符搜索';

  @override
  String get skuNoStock => '暂无库存';

  @override
  String get unitBox => '箱';

  @override
  String get unitPiece => '件';

  @override
  String skuTotalQty(int qty, String unit) {
    return '共 $qty $unit';
  }

  @override
  String get locationScreenTitle => '库位搜索';

  @override
  String get locationSearchHint => '搜索库位编号或描述...';

  @override
  String get locationEmpty => '暂无库位';

  @override
  String get locationNoResult => '未找到匹配库位';

  @override
  String get locationNewButton => '新建库位';

  @override
  String get locationNoStock => '暂无库存';

  @override
  String locationTotalQty(int qty) {
    return '共 $qty 件';
  }

  @override
  String get scannerTitle => '扫码查询';

  @override
  String get scannerHint => '将条码/二维码对准框内';

  @override
  String get scannerViewDetail => '查看详情';

  @override
  String get scannerStockLocations => '库存位置:';

  @override
  String get scannerOutOfStock => '该商品已断货';

  @override
  String get scannerAllZero => '所有位置库存为 0';

  @override
  String get scannerRestock => '去补货';

  @override
  String get scannerContinue => '继续扫码';

  @override
  String get scannerNotFound => '未找到该商品';

  @override
  String scannerBarcode(String code) {
    return '条码: $code';
  }

  @override
  String get scannerAddProduct => '新增商品';

  @override
  String get scannerMultipleFound => '找到多个匹配';

  @override
  String scannerTotalStock(int qty) {
    return '总库存: $qty 箱';
  }

  @override
  String scannerQtyPiece(int qty) {
    return '$qty 件';
  }

  @override
  String get historyTitle => '操作记录';

  @override
  String get historyAllUsers => '全部用户';

  @override
  String get historyEmpty => '暂无记录';

  @override
  String get historyFilterDate => '日期';

  @override
  String get historyFilterAction => '操作';

  @override
  String get historyFilterAll => '全部';

  @override
  String get historyToday => '今天';

  @override
  String get historyThisWeek => '本周';

  @override
  String get historyThisMonth => '本月';

  @override
  String get historyCustom => '自定义';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsEditProfile => '编辑个人信息';

  @override
  String get settingsDisplayName => '显示名称';

  @override
  String get settingsNameEmpty => '名称不能为空';

  @override
  String get settingsProfileUpdated => '个人信息已更新';

  @override
  String get settingsUpdateFailed => '更新失败';

  @override
  String get settingsChangePassword => '修改密码';

  @override
  String get settingsOldPassword => '原密码';

  @override
  String get settingsNewPassword => '新密码（至少6位）';

  @override
  String get settingsPasswordChanged => '密码修改成功';

  @override
  String get settingsPasswordChangeFailed => '修改失败';

  @override
  String get settingsSwitchAccount => '切换账号';

  @override
  String get settingsSwitchAccountSubtitle => '退出当前账号并返回登录页';

  @override
  String get settingsSectionManage => '管理';

  @override
  String get settingsUserManagement => '用户管理';

  @override
  String get settingsUserManagementSubtitle => '创建账号 / 分配角色 / 停用账号';

  @override
  String get settingsPasswordResetRequests => '密码重置申请';

  @override
  String get settingsPasswordResetRequestsSubtitle => '处理用户的忘记密码申请';

  @override
  String get settingsSectionData => '数据';

  @override
  String get settingsDataImport => '数据导入';

  @override
  String get settingsDataImportSubtitle => 'SKU 主档 / 库位主档 / 库存明细';

  @override
  String get settingsExportExcel => '导出 Excel';

  @override
  String get settingsExportExcelSubtitle => '导出全部 SKU、库位、库存及流水记录';

  @override
  String get settingsExporting => '正在生成 Excel，请稍候...';

  @override
  String settingsExportDone(String filename) {
    return '已下载: $filename';
  }

  @override
  String get settingsSectionDanger => '危险区域';

  @override
  String get settingsClearAllData => '清空所有业务数据';

  @override
  String get settingsClearAllDataSubtitle => '清空库存、SKU、库位、流水、日志及导入记录，仅保留用户账号';

  @override
  String get settingsClearDataTitle => '危险操作';

  @override
  String get settingsClearDataContent =>
      '此操作将清空以下所有数据：\n\n• 全部库存记录\n• 全部 SKU 主档\n• 全部库位主档\n• 全部出入库流水\n• 全部操作日志\n• 全部导入记录\n\n仅保留用户账号。\n\n此操作不可恢复！';

  @override
  String get settingsSecondConfirmTitle => '二次确认';

  @override
  String get settingsSecondConfirmContent => '请输入【清空数据】以确认操作：';

  @override
  String get settingsClearDataHint => '清空数据';

  @override
  String get settingsInputIncorrect => '输入不正确';

  @override
  String get settingsConfirmClear => '确认清空';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSubtitle => '切换界面显示语言';

  @override
  String get settingsSectionDisplay => '显示';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get langSystem => '跟随系统';

  @override
  String get langSelectTitle => '选择语言';

  @override
  String get skuFormTitle => 'SKU 信息';

  @override
  String get skuFormSkuCode => 'SKU 编号';

  @override
  String get skuFormName => '名称（可选）';

  @override
  String get skuFormBarcode => '条码（可选）';

  @override
  String get skuFormCartonQty => '箱规（件/箱，可选）';

  @override
  String get skuFormSkuEmpty => 'SKU 编号不能为空';

  @override
  String get skuFormSaveSuccess => '保存成功';

  @override
  String get skuFormArchive => '归档';

  @override
  String get skuFormUnarchive => '取消归档';

  @override
  String get skuFormDelete => '删除';

  @override
  String get skuFormConfirmArchive => '确认归档此 SKU？';

  @override
  String get skuFormConfirmUnarchive => '确认取消归档此 SKU？';

  @override
  String get skuFormConfirmDelete => '确认删除此 SKU？此操作不可恢复。';

  @override
  String get inventoryAddTitle => '库存操作';

  @override
  String get inventoryTabIn => '入库';

  @override
  String get inventoryTabOut => '出库';

  @override
  String get inventoryTabAdjust => '调整';

  @override
  String get inventorySearchSku => '搜索 SKU...';

  @override
  String get inventorySearchLocation => '搜索库位...';

  @override
  String get inventoryQty => '数量';

  @override
  String get inventoryNote => '备注（可选）';

  @override
  String get inventorySubmit => '提交';

  @override
  String get inventorySuccess => '操作成功';

  @override
  String get inventoryNewSku => '新建 SKU';

  @override
  String get inventoryNewLocation => '新建库位';

  @override
  String get inventorySelectSku => '请选择 SKU';

  @override
  String get inventorySelectLocation => '请选择库位';

  @override
  String get inventoryQtyError => '请输入有效数量';

  @override
  String get errorRetry => '重试';

  @override
  String operationFailed(String error) {
    return '操作失败: $error';
  }
}
