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
  String get registerValidation => '请填写完整信息';

  @override
  String get registerPasswordRules => '密码不符合要求';

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
  String get skuNoSpec => '（无箱规）';

  @override
  String skuLoosePcs(int qty) {
    return '散$qty件';
  }

  @override
  String get locationScreenTitle => '位置管理';

  @override
  String get locationSearchHint => '搜索位置码 / 备注...';

  @override
  String get locationEmpty => '暂无位置';

  @override
  String locationNoResult(String query) {
    return '未找到 \"$query\"';
  }

  @override
  String get locationSearchTip => '尝试缩短关键词，或忽略大小写搜索';

  @override
  String locationCount(int count) {
    return '$count 个库位';
  }

  @override
  String get locationNewButton => '新增位置';

  @override
  String get locationAddInventory => '录入库存';

  @override
  String get locationNewTitle => '新增位置';

  @override
  String get locationCode => '位置代码 *';

  @override
  String get locationDescription => '描述（可选）';

  @override
  String get locationCreate => '创建';

  @override
  String get locationCreateFailed => '创建失败';

  @override
  String get locationEmpty2 => '空位置';

  @override
  String locationChecked(String date) {
    return '检查 $date';
  }

  @override
  String get dateToday => '今天';

  @override
  String get dateYesterday => '昨天';

  @override
  String dateDaysAgo(int days) {
    return '$days天前';
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
  String get settingsConfirmNewPassword => '确认新密码';

  @override
  String get settingsPasswordMismatch => '两次密码不一致';

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

  @override
  String get saveFailed => '保存失败';

  @override
  String get skuFormEditTitle => '编辑 SKU';

  @override
  String get skuFormNewTitle => '新增 SKU';

  @override
  String get skuFormSkuCodeLabel => 'SKU 编号 *';

  @override
  String get skuFormProductName => '产品名称';

  @override
  String get skuFormBarcodeLabel => '条码';

  @override
  String get skuFormBarcodeAdminOnly => '仅管理员可修改条码';

  @override
  String get skuFormViewBarcodeHistory => '查看条码历史';

  @override
  String get skuFormCartonQtyLabel => '每箱个数';

  @override
  String get skuFormCreateButton => '创建';

  @override
  String get skuFormSaveButton => '保存';

  @override
  String get barcodeHistoryTitle => '条码变更历史';

  @override
  String barcodeHistoryCurrent(String barcode) {
    return '当前: $barcode';
  }

  @override
  String get barcodeHistoryEmpty => '暂无条码变更记录';

  @override
  String get barcodeSourceManual => '手动编辑';

  @override
  String get barcodeSourceImport => '批量导入';

  @override
  String get barcodeCurrentLabel => '当前';

  @override
  String get pwdResetTitle => '密码重置申请';

  @override
  String pwdResetHandleTitle(String name) {
    return '处理申请 — $name';
  }

  @override
  String get pwdResetInfoUsername => '用户名';

  @override
  String get pwdResetInfoTime => '申请时间';

  @override
  String get pwdResetInfoNote => '用户备注';

  @override
  String get pwdResetAction => '操作';

  @override
  String get pwdResetActionComplete => '重置密码';

  @override
  String get pwdResetActionReject => '拒绝申请';

  @override
  String get pwdResetTempPassword => '临时密码 *（至少 6 位）';

  @override
  String get pwdResetForceChangeNotice => '用户下次登录时将被强制修改此密码。';

  @override
  String get pwdResetRejectReason => '拒绝原因（可选）';

  @override
  String get pwdResetNoteOptional => '备注（可选）';

  @override
  String get pwdResetNoteHint => '例如：已通知用户';

  @override
  String get pwdResetPasswordTooShort => '密码至少需要 6 位';

  @override
  String get pwdResetOperationFailed => '操作失败';

  @override
  String get pwdResetConfirmComplete => '确认重置';

  @override
  String get pwdResetConfirmReject => '确认拒绝';

  @override
  String get pwdResetDeleteTitle => '删除记录';

  @override
  String pwdResetDeleteContent(String username) {
    return '确认删除 @$username 的申请记录？';
  }

  @override
  String get pwdResetDelete => '删除';

  @override
  String get pwdResetEmpty => '暂无申请记录';

  @override
  String get pwdResetHandle => '处理';

  @override
  String pwdResetRequestTime(String time) {
    return '申请时间：$time';
  }

  @override
  String pwdResetResolver(String resolver) {
    return '处理人：$resolver';
  }

  @override
  String get pwdResetStatusAll => '全部';

  @override
  String get pwdResetStatusPending => '待处理';

  @override
  String get pwdResetStatusCompleted => '已完成';

  @override
  String get pwdResetStatusRejected => '已拒绝';

  @override
  String get pwdResetStatusUnknown => '未知';

  @override
  String get historyAllTime => '全部时间';

  @override
  String get historyToday => '今天';

  @override
  String get historyLast7Days => '近7天';

  @override
  String get historyLast30Days => '近30天';

  @override
  String get historyCustomRange => '自定义时间';

  @override
  String get historyCustomRangeTitle => '自定义时间范围';

  @override
  String get historyStartDate => '开始日期';

  @override
  String get historyEndDate => '结束日期';

  @override
  String get historyPleaseSelect => '请选择';

  @override
  String get historyClear => '清空';

  @override
  String get historyApply => '应用';

  @override
  String get historySearchHint => '搜索操作记录...';

  @override
  String historyTotalRecords(int total) {
    return '共 $total 条记录';
  }

  @override
  String get historyNoRecords => '暂无操作记录';

  @override
  String get historyActionTypeLabel => '操作类型';

  @override
  String get historyEntityLabel => '对象';

  @override
  String get historyEntityLocation => '库位';

  @override
  String get historyEntityInventory => '库存';

  @override
  String get historyUserLabel => '用户';

  @override
  String get historyTimeLabel => '时间';

  @override
  String get historyAllUsersTab => '全部用户';

  @override
  String get historyMyRecords => '我的记录';

  @override
  String get historyFilterAll => '全部';

  @override
  String get historyFilterImport => '导入';

  @override
  String get historyFilterNew => '新增';

  @override
  String get historyFilterEntry => '录入';

  @override
  String get historyFilterAdjust => '调整';

  @override
  String get historyFilterTransfer => '转移';

  @override
  String get historyFilterCopy => '复制';

  @override
  String get historyFilterCheck => '检查';

  @override
  String get historyFilterIn => '入库';

  @override
  String get historyFilterOut => '出库';

  @override
  String get historyEntitySku => 'SKU';

  @override
  String get historyEntityLocationLabel => '库位';

  @override
  String get historyEntityInventoryLabel => '库存';

  @override
  String get historyPieceSuffix => '件';

  @override
  String get inventoryAddManualTitle => '手动录入库存';

  @override
  String get inventorySkuSection => 'SKU';

  @override
  String get inventoryLocationSection => '库位';

  @override
  String get inventoryInitialStockSection => '初始库存';

  @override
  String get inventoryNewSkuLabel => '新建 SKU';

  @override
  String get inventorySearchExisting => '搜索已有';

  @override
  String get inventorySearchSkuHint => '搜索 SKU 编号 / 名称 / 条码';

  @override
  String inventoryNewSkuTitle(String name) {
    return '新建 \"$name\"';
  }

  @override
  String get inventorySkuNotFound => '未找到，';

  @override
  String get inventoryCreateNewSku => '点击新建此 SKU';

  @override
  String get inventorySkuCodeLabel => 'SKU 编号 *';

  @override
  String get inventoryProductNameLabel => '商品名称';

  @override
  String get inventoryBarcodeLabel => '条形码（可选）';

  @override
  String get inventoryNewLocationLabel => '新建库位';

  @override
  String get inventorySearchLocationHint => '搜索库位编号';

  @override
  String inventoryNewLocationTitle(String name) {
    return '新建 \"$name\"';
  }

  @override
  String get inventoryLocationNotFound => '未找到，';

  @override
  String get inventoryCreateNewLocation => '点击新建此库位';

  @override
  String get inventoryLocationCodeLabel => '库位编号 *';

  @override
  String get inventoryLocationDescLabel => '描述（可选）';

  @override
  String get inventoryPendingTitle => '暂存 / 待清点';

  @override
  String get inventoryPendingSubtitle => '货已到位，数量暂未确认';

  @override
  String get inventoryModeCarton => '按箱规';

  @override
  String get inventoryModeBoxOnly => '仅箱数';

  @override
  String get inventoryModeQty => '按总数量';

  @override
  String get inventoryBoxesLabel => '箱数 *';

  @override
  String get inventoryBoxesSuffix => '箱';

  @override
  String get inventoryUnitsLabel => '每箱件数 *';

  @override
  String get inventoryTotalQtyLabel => '总件数 *';

  @override
  String get inventoryTotalQtySuffix => '件';

  @override
  String get inventoryNoteLabel => '备注（可选）';

  @override
  String get inventoryAddNoteHint => '添加备注';

  @override
  String get inventoryConfirmPending => '确认暂存';

  @override
  String get inventorySaveStock => '保存库存';

  @override
  String get inventoryStockSaved => '库存已保存';

  @override
  String get inventorySelectOrCreate => '请选择 SKU 或新建';

  @override
  String get inventorySkuCodeEmpty => 'SKU 编号不能为空';

  @override
  String get inventoryLocationCodeEmpty => '库位编号不能为空';

  @override
  String get inventoryValidBoxCount => '请输入有效箱数';

  @override
  String get inventoryValidUnits => '请输入每箱件数';

  @override
  String get inventoryValidQty => '请输入有效件数';

  @override
  String get inventoryTotal => '合计';

  @override
  String inventoryBoxesTotal(int boxes) {
    return '$boxes 箱 · 箱规待确认';
  }

  @override
  String inventoryQtyTotal(int qty) {
    return '合计 $qty 件';
  }

  @override
  String get inventoryPendingNote => '将标记为\"暂存\"状态，数量不计入正式合计。';

  @override
  String get skuDetailNewLocation => '新增库位';

  @override
  String get skuDetailLocationSection => '库位';

  @override
  String get skuDetailNewLocationButton => '+ 新建库位';

  @override
  String get skuDetailSearchLocationHint => '搜索库位编号';

  @override
  String skuDetailNewLocationTitle(String name) {
    return '新建 \"$name\"';
  }

  @override
  String get skuDetailLocationNotFound => '未找到，点击新建';

  @override
  String get skuDetailLocationCodeHint => '库位编号 *';

  @override
  String get skuDetailLocationDescHint => '描述（可选）';

  @override
  String get skuDetailInitialStock => '初始库存';

  @override
  String get skuDetailPendingTitle => '暂存 / 待清点';

  @override
  String get skuDetailPendingSubtitle => '货已到位，数量暂未确认';

  @override
  String get skuDetailModeCarton => '按箱规';

  @override
  String get skuDetailModeBoxOnly => '仅箱数';

  @override
  String get skuDetailModeQty => '按总数量';

  @override
  String get skuDetailBoxesLabel => '箱数';

  @override
  String get skuDetailBoxesSuffix => '箱';

  @override
  String get skuDetailUnitsLabel => '每箱件数';

  @override
  String get skuDetailUnitsSuffix => '件/箱';

  @override
  String get skuDetailBoxesOnlyHelp => '仅记录箱数，每箱件数可后续补充';

  @override
  String get skuDetailTotalLabel => '初始总件数';

  @override
  String get skuDetailTotalSuffix => '件';

  @override
  String get skuDetailNoteLabel => '备注（可选）';

  @override
  String get skuDetailCancel => '取消';

  @override
  String get skuDetailCreate => '创建';

  @override
  String get skuDetailSelectSku => '请选择 SKU';

  @override
  String get skuDetailValidBoxes => '请输入有效的箱数和每箱件数';

  @override
  String get skuDetailValidBoxesOnly => '请输入有效箱数';

  @override
  String get skuDetailValidQty => '请输入有效的数量';

  @override
  String get skuDetailConfirmPending => '确认暂存';

  @override
  String get skuDetailSave => '保存';

  @override
  String get skuDetailDeleteConfirmTitle => '确认删除';

  @override
  String skuDetailDeleteConfirmContent(String location, String sku) {
    return '确定删除 $location 中的\n$sku 当前库存记录吗？\n此操作不可恢复。';
  }

  @override
  String get skuDetailDelete => '删除';

  @override
  String skuDetailDeleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String skuDetailArchiveWithStockContent(String skuCode, int count) {
    return '$skuCode 仍有 $count 条库存记录。\n\n归档后该 SKU 不允许新入库，但现有库存仍可查看和出库。\n\n确认归档？';
  }

  @override
  String skuDetailArchiveContent(String skuCode) {
    return '确定归档 SKU $skuCode？归档后不允许新入库。';
  }

  @override
  String get skuDetailArchiveTitle => '确认归档';

  @override
  String get skuDetailConfirmArchive => '确认归档';

  @override
  String skuDetailArchived(String skuCode) {
    return '$skuCode 已归档';
  }

  @override
  String skuDetailOperationFailed(String error) {
    return '操作失败: $error';
  }

  @override
  String get skuDetailRestoreTitle => '恢复 SKU';

  @override
  String skuDetailRestoreContent(String skuCode) {
    return '确定将 $skuCode 恢复为\"在用\"状态？';
  }

  @override
  String get skuDetailConfirmRestore => '确认恢复';

  @override
  String skuDetailRestored(String skuCode) {
    return '$skuCode 已恢复为在用';
  }

  @override
  String get skuDetailArchivedNotice => '此 SKU 已归档，不允许新入库。现有库存仍可查看和出库。';

  @override
  String get skuDetailTotalStock => '总库存';

  @override
  String skuDetailTotalBoxes(int boxes) {
    return '$boxes 箱';
  }

  @override
  String skuDetailTotalQtyPieces(int qty) {
    return '$qty 件';
  }

  @override
  String get skuDetailLocationCol => '库位';

  @override
  String get skuDetailBoxesCol => '箱数';

  @override
  String get skuDetailDefaultCarton => '默认箱规';

  @override
  String skuDetailCartonQtyDisplay(int qty) {
    return '$qty 件/箱';
  }

  @override
  String skuDetailSpecCount(int count) {
    return '$count 种箱规';
  }

  @override
  String get skuDetailStockLocations => '库存位置';

  @override
  String get skuDetailAddLocation => '添加库位';

  @override
  String get skuDetailBadgePending => '待清点';

  @override
  String get skuDetailBadgeBoxOnly => '仅箱数';

  @override
  String get skuDetailBadgeCarton => '按箱规';

  @override
  String get skuDetailUnknownLocation => '未知位置';

  @override
  String get skuDetailStockDelete => '删除';

  @override
  String skuDetailSkuStock(int total) {
    return '库存 SKU ($total)';
  }

  @override
  String skuDetailSkuStockShown(int shown, int total) {
    return '库存 SKU ($shown / $total)';
  }

  @override
  String get skuDetailTransferLabel => '转移';

  @override
  String get skuDetailCopyLabel => '复制';

  @override
  String get skuDetailNoMatchingSku => '暂无匹配的 SKU';

  @override
  String get skuDetailClearFilter => '清除筛选';

  @override
  String get skuDetailFilterStock => '库存:';

  @override
  String get skuDetailFilterBusiness => '业务:';

  @override
  String get skuDetailFilterAll => '全部';

  @override
  String get skuDetailFilterHasStock => '有库存';

  @override
  String get skuDetailFilterZeroStock => '0库存';

  @override
  String get skuDetailFilterNormal => '正常';

  @override
  String get skuDetailFilterPending => '暂存';

  @override
  String get skuDetailChecked => '已检查';

  @override
  String get skuDetailCheckNow => '检查';

  @override
  String skuDetailCheckConfirm(String code) {
    return '确认将 $code 标记为已检查？';
  }

  @override
  String get skuDetailLastCheck => '上次检查';

  @override
  String get skuDetailNoCheckRecord => '无检查记录';

  @override
  String get skuDetailCheckHistory => '检查记录';

  @override
  String get checkStatusToday => '今日已检查';

  @override
  String get checkStatus3Days => '3天内已检查';

  @override
  String get checkStatus7Days => '超过7天未检查';

  @override
  String get checkStatusNever => '从未检查';

  @override
  String get checkFilterAll => '全部';

  @override
  String get checkFilterToday => '今日';

  @override
  String get checkFilter3Days => '3天内';

  @override
  String get checkFilter7Days => '7天以上';

  @override
  String get checkFilterNever => '从未';

  @override
  String get skuDetailLastChange => '上次变更';

  @override
  String get skuDetailNoChangeRecord => '无变更记录';

  @override
  String get skuDetailTotalBoxesLabel => '总箱数';

  @override
  String get skuDetailTotalPiecesLabel => '总件数';

  @override
  String skuDetailChangeRecords(String locationCode) {
    return '$locationCode 变更记录';
  }

  @override
  String skuDetailLoadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String get skuDetailNoChangeRecords => '暂无变更记录';

  @override
  String skuDetailViewAllRecords(int total) {
    return '查看全部 $total 条记录';
  }

  @override
  String get skuDetailViewHistoryPage => '在操作记录页查看';

  @override
  String get skuDetailNoSkuHere => '该库位暂无可操作的 SKU';

  @override
  String skuDetailCheckInventory(String code) {
    return '请确认库位 $code 是否已录入库存，\n或联系管理员检查数据';
  }

  @override
  String get skuDetailCreateSkuError => '请输入 SKU 编码';

  @override
  String skuDetailCreateFailed(String error) {
    return '创建失败: $error';
  }

  @override
  String get skuDetailPendingMarkTitle => '标记为暂存 / 待清点';

  @override
  String get skuDetailPendingMarkSubtitle1 => '此记录将归入暂存分类，可填写实际数量';

  @override
  String get skuDetailPendingMarkSubtitle2 => '勾选后归入暂存分类，数量仍正常录入';

  @override
  String get skuDetailNewSkuCode => 'SKU 编码 *';

  @override
  String get skuDetailNewSkuName => '货号名称（可选）';

  @override
  String skuDetailEmptyFilterMsg(String parts) {
    return '当前筛选「$parts」下暂无 SKU';
  }

  @override
  String get skuDetailNoInventory => '暂无库存 SKU';

  @override
  String get skuDetailQtyLinePending => '待补充库存信息';

  @override
  String skuDetailQtyLineBoxes(int boxes) {
    return '$boxes箱 · 箱规待确认';
  }

  @override
  String skuDetailQtyLineCarton(int boxes, int qty) {
    return '$boxes箱 · $qty件';
  }

  @override
  String skuDetailSelectedSkus(int count) {
    return '已选 $count 种 SKU，请选择目标库位';
  }

  @override
  String get skuDetailTargetLocationHint => '输入库位编码...';

  @override
  String get skuDetailEnterCodeToSearch => '输入库位编码以搜索目标位置';

  @override
  String get skuDetailLoadTargetFailed => '加载目标库位失败';

  @override
  String skuDetailCreateLocationFailed(String error) {
    return '创建库位失败: $error';
  }

  @override
  String skuDetailNewAndTransfer(String code, String action) {
    return '新建库位 \"$code\" 并$action到此';
  }

  @override
  String skuDetailSelectedSkuCount(int count) {
    return '$count 种 SKU';
  }

  @override
  String skuDetailConflictMsg(int count) {
    return '目标库位已有 $count 种相同 SKU，请选择处理方式：';
  }

  @override
  String get skuDetailMerge => '合并';

  @override
  String get skuDetailMergeDesc => '将来源库存合并到目标已有库存中';

  @override
  String get skuDetailOverwrite => '覆盖';

  @override
  String get skuDetailOverwriteDesc => '用来源库存替换目标已有库存';

  @override
  String get skuDetailStack => '叠加';

  @override
  String get skuDetailStackDesc => '将来源库存叠加到目标已有库存中';

  @override
  String skuDetailNoConflict(int count, String action) {
    return '无冲突 SKU（$count 种，将直接$action）：';
  }

  @override
  String get skuDetailTransferDeleteNotice => '转移完成后，原库位对应的 SKU 库存数据将被删除。';

  @override
  String skuDetailTransferFailed(String action, String error) {
    return '$action失败: $error';
  }

  @override
  String skuDetailBulkTitle(String action) {
    return '批量$action库存';
  }

  @override
  String skuDetailBulkSelectHint(String action, String code) {
    return '选择要$action的 SKU（来源：$code）';
  }

  @override
  String skuDetailSkuCountSuffix(int count) {
    return '$count 种 SKU · ';
  }

  @override
  String skuDetailSelectedCount(int count) {
    return '已选 $count 种';
  }

  @override
  String get skuDetailDeselectAll => '取消全选';

  @override
  String get skuDetailSelectAll => '全选';

  @override
  String get skuDetailReturn => '返回';

  @override
  String skuDetailConfirmActionCount(String action, int count) {
    return '确认$action $count 种';
  }

  @override
  String get skuDetailNextStep => '下一步';

  @override
  String skuDetailNextStepWithCount(int count) {
    return '下一步（已选 $count 种）';
  }

  @override
  String skuDetailConfirmAction(String action) {
    return '确认$action';
  }

  @override
  String skuDetailRouteLabel(String src, String dst, int total) {
    return '$src → $dst，共 $total 种 SKU';
  }

  @override
  String skuDetailDirectAction(String action) {
    return '直接$action';
  }

  @override
  String skuDetailResultSection(String title, int count) {
    return '$title（$count 种）';
  }

  @override
  String skuDetailTransferDone(String action) {
    return '$action完成';
  }

  @override
  String get importTitle => '批量导入';

  @override
  String get importSelectType => '选择导入类型';

  @override
  String get importRecordsTab => '记录';

  @override
  String get importHistoryTab => '导入记录';

  @override
  String get importHistoryTitle => '导入记录';

  @override
  String get importSkuMasterLabel => 'SKU 主档导入';

  @override
  String get importSkuMasterSubtitle => '批量新增或更新 SKU 基础资料';

  @override
  String get importLocationMasterLabel => '库位主档导入';

  @override
  String get importLocationMasterSubtitle => '批量新增或更新库位';

  @override
  String get importInventoryLabel => '库存明细导入';

  @override
  String get importInventorySubtitle => '批量录入库存数量（SKU 和库位须已存在）';

  @override
  String get importSkuBarcodeLabel => 'SKU 条码批量更新';

  @override
  String get importSkuBarcodeSubtitle => '仅更新已有 SKU 的条形码字段';

  @override
  String get importSkuCartonLabel => 'SKU 箱规批量更新';

  @override
  String get importSkuCartonSubtitle => '仅更新已有 SKU 的默认箱规字段';

  @override
  String get importTemplateColumns => '模板列说明：';

  @override
  String get importReselect => '重新选择';

  @override
  String importConfirm(int count) {
    return '确认导入 ($count 条)';
  }

  @override
  String get importNoData => '无可导入数据';

  @override
  String get importReimport => '重新导入';

  @override
  String get importDownloadTemplate => '下载模板';

  @override
  String get importValidating => '校验中…';

  @override
  String get importImporting => '导入中…';

  @override
  String get importSelectFile => '选择文件';

  @override
  String get importColName => '列名';

  @override
  String get importColRequired => '必填';

  @override
  String get importColDesc => '说明';

  @override
  String get importReqRequired => '必填';

  @override
  String get importReqEitherA => '二选A';

  @override
  String get importReqEitherB => '二选B';

  @override
  String get importReqOptional => '可选';

  @override
  String get importValidationOkWithErrors => '校验完成（含部分错误）';

  @override
  String get importValidationAllErrors => '校验完成（全部行有错误）';

  @override
  String get importValidationPassed => '校验通过，可以导入';

  @override
  String importFilename(String filename) {
    return '文件: $filename';
  }

  @override
  String get importStatTotal => '共';

  @override
  String get importStatCreate => '待创建';

  @override
  String get importStatUpdate => '待更新';

  @override
  String get importStatSkip => '跳过';

  @override
  String get importStatError => '错误';

  @override
  String get importErrorDetails => '错误详情：';

  @override
  String importRowLabel(int row) {
    return '第 $row 行  ';
  }

  @override
  String importMoreErrors(int count) {
    return '… 还有 $count 条错误（请修正文件后重新选择）';
  }

  @override
  String get importPreviewData => '将写入数据预览：';

  @override
  String importMoreRows(int count) {
    return '… 还有 $count 条（确认后将全部写入）';
  }

  @override
  String get importCreate => '新建';

  @override
  String get importUpdate => '更新';

  @override
  String get importDoneTitle => '导入完成';

  @override
  String get importDoneWithErrors => '导入完成（有部分问题）';

  @override
  String get importResultTotal => '共';

  @override
  String get importResultCreate => '新建';

  @override
  String get importResultUpdate => '更新';

  @override
  String get importResultSkip => '跳过';

  @override
  String get importResultError => '错误';

  @override
  String get importRowErrorDetails => '行级错误详情：';

  @override
  String importMoreRowErrors(int count) {
    return '… 还有 $count 条错误';
  }

  @override
  String get importValidationFailed => '校验失败，请检查文件格式';

  @override
  String importValidationError(String error) {
    return '校验失败: $error';
  }

  @override
  String get importFailed => '导入失败，请检查文件格式';

  @override
  String importError(String error) {
    return '导入失败: $error';
  }

  @override
  String importHistoryTotal(int count) {
    return '共 $count 条记录';
  }

  @override
  String get importHistoryEmpty => '暂无导入记录';

  @override
  String get importHistoryLoadMore => '加载更多';

  @override
  String importExportFailed(String error) {
    return '导出失败: $error';
  }

  @override
  String get importStatusSuccess => '成功';

  @override
  String get importStatusPartial => '部分成功';

  @override
  String get importStatusAllFailed => '全部失败';

  @override
  String get importStatusSkipped => '完成（有跳过）';

  @override
  String get importHistoryStatTotal => '共';

  @override
  String get importHistoryStatCreate => '新建';

  @override
  String get importHistoryStatUpdate => '更新';

  @override
  String get importHistoryStatSkip => '跳过';

  @override
  String get importHistoryStatError => '错误';

  @override
  String get importHistoryRowErrors => '行级错误详情：';

  @override
  String importHistoryMoreErrors(int count) {
    return '… 还有 $count 条错误';
  }

  @override
  String get importExporting => '导出中…';

  @override
  String get importExportDetail => '导出详情 Excel';

  @override
  String get importFilterAll => '全部';

  @override
  String get importFilterSku => 'SKU 主档';

  @override
  String get importFilterLocation => '库位主档';

  @override
  String get importFilterInventory => '库存明细';

  @override
  String get importFilterBarcodeUpdate => '条码更新';

  @override
  String get importFilterCartonUpdate => '箱规更新';

  @override
  String get importRefresh => '刷新';

  @override
  String historyBulkSkuCount(int total) {
    return '$total 种SKU';
  }

  @override
  String get badgeActionCreate => '新增';

  @override
  String get badgeActionUpdate => '编辑';

  @override
  String get badgeActionDelete => '删除';

  @override
  String get auditBasicInfo => '基础信息';

  @override
  String get auditActionType => '操作类型';

  @override
  String get auditEntity => '操作对象';

  @override
  String get auditEntityId => '对象 ID';

  @override
  String get auditOperator => '操作人';

  @override
  String get auditTime => '操作时间';

  @override
  String get auditDescription => '操作说明';

  @override
  String get auditFieldChanges => '字段变更';

  @override
  String get auditBefore => '变更前';

  @override
  String get auditAfter => '变更后';

  @override
  String get auditNone => '无';

  @override
  String get auditStockInTitle => '入库内容';

  @override
  String get auditStockOutTitle => '出库内容';

  @override
  String get auditAdjustTitle => '调整内容';

  @override
  String get auditEntryTitle => '录入内容';

  @override
  String get auditDeleteStockTitle => '删除内容';

  @override
  String get auditStructureTitle => '修改内容';

  @override
  String get auditTransferTitle => '转移路径';

  @override
  String get auditCopyTitle => '复制路径';

  @override
  String get auditCheckTitle => '检查状态';

  @override
  String get auditLocationOpTitle => '库位信息';

  @override
  String get auditLocation => '库位';

  @override
  String get auditSku => 'SKU';

  @override
  String auditQtyAdded(int qty) {
    return '+$qty件';
  }

  @override
  String auditQtyReduced(int qty) {
    return '-$qty件';
  }

  @override
  String auditQtyPcs(int qty) {
    return '$qty件';
  }

  @override
  String auditQtyBoxes(int boxes) {
    return '$boxes箱';
  }

  @override
  String auditQtyPcsPerBox(int qty) {
    return '$qty件/箱';
  }

  @override
  String get auditBeforeAfterChange => '前后变化';

  @override
  String get auditChangeLabel => '变化';

  @override
  String get auditBeforeLabel => '操作前';

  @override
  String get auditAfterLabel => '操作后';

  @override
  String get auditNoStock => '无库存';

  @override
  String get auditNote => '备注';

  @override
  String get auditDeletedNotice => '该 SKU 在此库位的所有库存数据已删除，此操作不可恢复。';

  @override
  String get auditAdjustMode => '调整方式';

  @override
  String get auditAdjustModeConfig => '按箱规调整';

  @override
  String get auditAdjustModeQty => '按总数量调整';

  @override
  String get auditAdjustModeMixed => '混合调整（箱+散件）';

  @override
  String get auditAdjustModeBoxesOnly => '仅箱数调整';

  @override
  String auditFirstEntry(int qty) {
    return '首次录入 · 共$qty件';
  }

  @override
  String get auditSourceLocation => '来源库位';

  @override
  String get auditTargetLocation => '目标库位';

  @override
  String auditSkuTotal(int total) {
    return '$total 种SKU';
  }

  @override
  String get auditAffectedDetails => '涉及明细';

  @override
  String get auditDirectTransfer => '直接转移';

  @override
  String get auditDirectTransferDesc => '目标库位原无此 SKU，直接写入';

  @override
  String get auditMerged => '合并';

  @override
  String get auditMergedDesc => '与目标库位已有库存合并，按箱规叠加';

  @override
  String get auditOverwritten => '覆盖';

  @override
  String get auditOverwrittenDesc => '用来源库存替换了目标库位的原有库存';

  @override
  String get auditImpactResult => '影响结果';

  @override
  String get auditTransferDeleteNotice =>
      '转移完成后，来源库位中对应的 SKU 库存数据已被删除。\n目标库位已新增或更新上述 SKU 的库存。';

  @override
  String get auditDirectCopy => '直接复制';

  @override
  String get auditDirectCopyDesc => '目标库位原无此 SKU，直接写入';

  @override
  String get auditStacked => '叠加';

  @override
  String get auditStackedDesc => '与目标库位已有库存叠加，按箱规合并';

  @override
  String get auditCopySourceUnchanged => '来源库位无变化（复制操作不删除来源数据）';

  @override
  String get auditCheckedChange => '状态变化';

  @override
  String get auditMarkChecked => '未检查  →  已检查';

  @override
  String get auditUnmarkChecked => '已检查  →  未检查';

  @override
  String get auditCheckedBy => '检查人';

  @override
  String get auditCheckedAt => '检查时间';

  @override
  String get auditLocationCode => '库位编码';

  @override
  String get auditDescription2 => '描述';

  @override
  String auditTotalSkuCount(int total) {
    return '$total 种SKU';
  }

  @override
  String get auditTargetLocationChange => '目标库位变化';

  @override
  String auditSkuTypeCount(int count) {
    return '$count 种';
  }

  @override
  String auditGroupTitle(String title, int count) {
    return '$title（$count种）';
  }

  @override
  String auditQtyPcsBold(int qty) {
    return '$qty件';
  }

  @override
  String get auditBusinessActionStockIn => '入库';

  @override
  String get auditBusinessActionStockOut => '出库';

  @override
  String get auditBusinessActionAdjust => '调整';

  @override
  String get auditBusinessActionEntry => '录入';

  @override
  String get auditBusinessActionDeleteStock => '删除库存';

  @override
  String get auditBusinessActionStructure => '结构修改';

  @override
  String get auditBusinessActionTransfer => '批量转移';

  @override
  String get auditBusinessActionTransferIn => '批量转入';

  @override
  String get auditBusinessActionCopy => '批量复制';

  @override
  String get auditBusinessActionCopyIn => '批量复制进入';

  @override
  String get auditBusinessActionNewLocation => '新建库位';

  @override
  String get auditBusinessActionEditLocation => '编辑库位';

  @override
  String get auditBusinessActionDeleteLocation => '删除库位';

  @override
  String get auditBusinessActionMarkChecked => '标记已检查';

  @override
  String get auditBusinessActionUnmarkChecked => '取消已检查';

  @override
  String get auditBusinessActionNewSku => '新建SKU';

  @override
  String get auditBusinessActionEditSku => '编辑SKU';

  @override
  String get auditBusinessActionDeleteSku => '删除SKU';

  @override
  String skuDetailInitialPreviewCarton(int boxes, int units, int qty) {
    return '初始库存：$boxes箱 × $units件/箱 = $qty件';
  }

  @override
  String skuDetailInitialPreviewBoxOnly(int qty) {
    return '初始库存：$qty 箱（每箱件数待定）';
  }

  @override
  String skuDetailInitialPreviewQty(int qty) {
    return '初始库存：$qty 件';
  }

  @override
  String get locDetailAddSkuTitle => '新增 SKU';

  @override
  String get locDetailEditStock => '编辑库存';

  @override
  String get locDetailReselectSku => '重新选择';

  @override
  String get locDetailSearchSkuHint => '搜索编码 / 名称 / 条码';

  @override
  String get locDetailNewSkuButton => '+ 新建货号';

  @override
  String get locDetailOperationFailedRetry => '操作失败，请重试';

  @override
  String get locDetailParamError => '参数错误，请检查输入';

  @override
  String locDetailTotalPcs(int qty) {
    return '共 $qty 件';
  }

  @override
  String locDetailConfigCarton(int boxes, int units) {
    return '$boxes箱 × $units件/箱';
  }

  @override
  String get errPermissionDenied => '权限不足，无法执行此操作';

  @override
  String get errSessionExpired => '登录已过期，请重新登录';

  @override
  String get errResourceNotFound => '目标资源不存在，请刷新后重试';

  @override
  String errRequestFailed(int code) {
    return '请求失败（$code），请重试';
  }

  @override
  String get errCannotConnectServer => '无法连接服务器，请检查网络';

  @override
  String get errNetworkFailed => '网络请求失败，请重试';

  @override
  String get errOperationFailed => '操作失败，请重试';

  @override
  String get invDetailQtyUnknown => '未填写';

  @override
  String get invDetailBoxesSuffix => '箱';

  @override
  String get invDetailPieceSuffix => '件';

  @override
  String get invDetailUnitsPerBoxSuffix => '件/箱';

  @override
  String get invDetailCurrentStatusPending => '当前状态: 待清点';

  @override
  String invDetailCurrentStock(String label) {
    return '当前库存: $label';
  }

  @override
  String get invDetailQtyEntryMode => '录入方式';

  @override
  String get invDetailModeByCarton => '按箱规';

  @override
  String get invDetailModeBoxesOnly => '仅箱数';

  @override
  String get invDetailModeByQty => '按总数量';

  @override
  String get invDetailBoxesLabel => '箱数 *';

  @override
  String get invDetailPendingBoxes => '暂存箱数: ';

  @override
  String get invDetailStockInBoxes => '入库箱数: ';

  @override
  String invDetailBoxesValue(int boxes) {
    return '$boxes 箱';
  }

  @override
  String get invDetailCartonTBD => '  · 箱规待确认';

  @override
  String get invDetailStockInTotal => '入库总量: ';

  @override
  String invDetailAddQty(int qty) {
    return '+ $qty 件';
  }

  @override
  String invDetailNewTotal(int total) {
    return '  →  $total 件';
  }

  @override
  String get invDetailStockInQtyLabel => '入库件数 *';

  @override
  String get invDetailAddConfigRow => '+ 添加规格';

  @override
  String get invDetailPendingMarkNote =>
      '将标记此库存为【待清点】，当前数量不变。后续确认后可通过【调整】更新数量。';

  @override
  String get invDetailErrInvalidBoxes => '请输入有效箱数';

  @override
  String get invDetailErrInvalidBoxesAndUnits => '请输入有效的箱数和每箱件数';

  @override
  String get invDetailErrInvalidQty => '请输入有效件数';

  @override
  String get invDetailConfirmPendingBtn => '确认暂存';

  @override
  String get invDetailConfirmStockIn => '确认入库';

  @override
  String get invDetailStockInTitle => '入库';

  @override
  String get invDetailStockOutTitle => '出库';

  @override
  String get invDetailOutTotal => '出库总量: ';

  @override
  String invDetailOutBoxesValue(int boxes) {
    return '$boxes 箱';
  }

  @override
  String invDetailOutPcsValue(int qty) {
    return '$qty 件';
  }

  @override
  String invDetailRemainCartonBoxes(int boxes) {
    return '  →  剩余 $boxes 箱';
  }

  @override
  String invDetailRemainBoxes(int boxes) {
    return '  →  剩余 $boxes 箱';
  }

  @override
  String invDetailRemainPcs(int qty) {
    return '  →  剩余 $qty 件';
  }

  @override
  String get invDetailNoCartonData => '当前无箱规数据，请使用其他模式';

  @override
  String get invDetailSelectOutBoxes => '选择出库箱数:';

  @override
  String get invDetailOutBoxesColHeader => '出库箱数';

  @override
  String invDetailUnitsPerBoxDisplay(int units) {
    return '$units件/箱';
  }

  @override
  String invDetailTotalBoxesDisplay(int boxes) {
    return '共$boxes箱';
  }

  @override
  String invDetailOutMaxBoxes(int boxes) {
    return '出库 (最多$boxes箱)';
  }

  @override
  String invDetailExceedBoxes(int boxes) {
    return '超出可用$boxes箱';
  }

  @override
  String invDetailEqPcs(int qty) {
    return '= $qty件';
  }

  @override
  String invDetailOutBoxesLabel(int boxes) {
    return '出库箱数 * (最多 $boxes 箱)';
  }

  @override
  String get invDetailBoxesOnlyHelp => '适用：箱规不确定，仅按箱数出库。';

  @override
  String get invDetailOutQtyLabel => '出库件数 *';

  @override
  String get invDetailErrNegativeBoxes => '出库箱数不能为负数';

  @override
  String invDetailErrExceedCartonBoxes(int units, int boxes) {
    return '$units件/箱：超过可用箱数 ($boxes 箱)';
  }

  @override
  String get invDetailErrAtLeastOneCarton => '请至少输入一种箱规的出库数量';

  @override
  String invDetailErrExceedStockBoxes(int boxes) {
    return '出库数量不能超过当前库存（$boxes 箱）';
  }

  @override
  String invDetailErrExceedStockPcs(int qty) {
    return '出库数量不能超过当前库存（$qty 件）';
  }

  @override
  String get invDetailConfirmStockOut => '确认出库';

  @override
  String get invDetailAdjustTitle => '库存调整';

  @override
  String get invDetailAdjustedTotalLabel => '调整后总件数 *';

  @override
  String get invDetailAdjustQtyHelp => '适用场景：盘点差异、货损等，直接修正总件数。';

  @override
  String get invDetailBoxesOnlyPanelHelp => '每箱件数保持不变，仅修改各规格箱数：';

  @override
  String invDetailSubtotalPcs(int qty) {
    return '=$qty件';
  }

  @override
  String get invDetailCartonGroupsLabel => '各箱规库存（最多3组）:';

  @override
  String get invDetailAddCarton => '新增箱规';

  @override
  String get invDetailAddFirstCarton => '添加第一组箱规';

  @override
  String get invDetailUnitsPerBoxLabel => '件/箱';

  @override
  String get invDetailBoxesAdjustLabel => '箱数';

  @override
  String get invDetailSkuCorrectCurrent => '当前：';

  @override
  String get invDetailSkuCorrectSelectHint => '（请从下方选择）';

  @override
  String get invDetailSkuCorrectSearch => '搜索新 SKU 编码或名称';

  @override
  String invDetailQtyRetained(String label) {
    return '库存数量 $label 将保留不变';
  }

  @override
  String get invDetailAdjustModeMixed => '混合';

  @override
  String get invDetailAdjustModeQty => '总数量';

  @override
  String get invDetailAdjustModeBoxesOnly => '仅箱数';

  @override
  String get invDetailAdjustModeCarton => '按箱规';

  @override
  String get invDetailAdjustModeSkuCorrect => 'SKU更正';

  @override
  String get invDetailReasonSkuCorrect => '更正原因 *（必填）';

  @override
  String get invDetailReasonAdjust => '调整原因 *（必填）';

  @override
  String get invDetailReasonSkuCorrectHint => '例：录错货号、暂存转正式SKU';

  @override
  String get invDetailReasonAdjustHint => '例：盘点差异、货损、退货补库';

  @override
  String get invDetailErrReasonRequired => '请填写原因（必填）';

  @override
  String get invDetailErrSelectNewSku => '请从下拉列表中选择新 SKU';

  @override
  String get invDetailErrSameSkuNotAllowed => '新旧 SKU 不能相同';

  @override
  String get invDetailErrNoInventoryId => '无法获取库存记录 ID，请关闭后重试';

  @override
  String get invDetailErrAtLeastOneBoxesGroup => '至少填写一组的箱数（> 0）';

  @override
  String get invDetailErrAtLeastOneCartonGroup => '至少需要一组箱规';

  @override
  String get invDetailErrValidCartonGroup => '请输入有效的箱数和每箱件数（均需 > 0）';

  @override
  String get invDetailErrValidQtyGte0 => '请输入有效件数（≥ 0）';

  @override
  String get invDetailErrMixedEmpty => '请至少输入一条箱规或散件数';

  @override
  String get invDetailErrMixedInvalidSpec => '所有箱规的箱数和每箱件数均需大于 0';

  @override
  String get invDetailLoosePcsLabel => '散件（不足整箱）';

  @override
  String get invDetailCartonSpecsLabel => '箱规';

  @override
  String get invDetailConfirmSkuCorrect => '确认更正';

  @override
  String get invDetailConfirmBoxesAdjust => '确认箱数调整';

  @override
  String get invDetailConfirmAdjust => '确认调整';

  @override
  String get invDetailAdjustedTotalRow => '调整后总库存: ';

  @override
  String get invDetailBoxesLabelStar => '箱数 *';

  @override
  String get invDetailUnitsLabelStar => '每箱件数 *';

  @override
  String get invDetailNoteOptional => '备注（可选）';

  @override
  String get invDetailQtyUnknownHeader => '待补充库存信息';

  @override
  String invDetailBoxesOnlyHeader(int boxes) {
    return '$boxes箱 · 箱规待确认';
  }

  @override
  String invDetailBoxesAndPcs(int boxes, int qty) {
    return '$boxes箱 · $qty件';
  }

  @override
  String get invDetailStockIn => '入库';

  @override
  String get invDetailStockOut => '出库';

  @override
  String get invDetailAdjust => '库存调整';

  @override
  String get invDetailConfirmPendingLabel => '确认为正式';

  @override
  String get invDetailSplitPendingLabel => '拆分为正式SKU';

  @override
  String get invDetailSkuDetail => 'SKU 详情';

  @override
  String get invDetailLocDetail => '库位详情';

  @override
  String get invDetailRecentOps => '最近操作';

  @override
  String get invDetailViewAll => '查看全部记录';

  @override
  String get invDetailLoadFailed => '加载失败，点击重试';

  @override
  String get invDetailNoRecords => '暂无操作记录';

  @override
  String get invDetailConfirmOfficialTitle => '确认为正式库存';

  @override
  String get invDetailPendingToOfficial => '暂存 → 正式库存';

  @override
  String get invDetailCorrectSkuCode => '同时更正SKU编码';

  @override
  String get invDetailSearchNewSku => '搜索新 SKU 编码或名称';

  @override
  String get invDetailConfirmReasonLabel => '原因 *';

  @override
  String get invDetailConfirmReasonHint => '请说明确认原因';

  @override
  String get invDetailErrReasonEmpty => '请填写原因';

  @override
  String get invDetailErrSelectNewSkuCode => '请从下拉列表中选择新SKU编码';

  @override
  String get invDetailConfirmedOfficial => '已确认为正式库存';

  @override
  String get invDetailConfirmToOfficial => '确认转正式';

  @override
  String get invDetailSplitTitle => '拆分为正式SKU';

  @override
  String invDetailSplitSource(String sku) {
    return '原暂存: $sku';
  }

  @override
  String invDetailSplitSourceInfo(String locationCode, String sourceLabel) {
    return '$locationCode  ·  录入方式：$sourceLabel';
  }

  @override
  String invDetailSplitTotalConserve(int amount, String unit) {
    return '总量 $amount $unit  ·  按$unit守恒';
  }

  @override
  String get invDetailSplitBalanced => '✓ 已平衡';

  @override
  String invDetailSplitProgress(int total, int original) {
    return '已分 $total / $original';
  }

  @override
  String get invDetailSplitNoSku => '未选择SKU';

  @override
  String get invDetailSplitModeByCarton => '按箱规';

  @override
  String get invDetailSplitModeBoxesOnly => '仅箱数';

  @override
  String get invDetailSplitModeByQty => '按总数量';

  @override
  String get invDetailSplitSearchSku => '搜索 SKU';

  @override
  String get invDetailSplitBoxesLabel => '箱数';

  @override
  String get invDetailSplitBoxesSuffix => '箱';

  @override
  String get invDetailSplitUnitsLabel => '件/箱';

  @override
  String get invDetailSplitUnitsSuffix => '件/箱';

  @override
  String get invDetailSplitCartonTBD => '· 箱规待确认';

  @override
  String get invDetailSplitTotalQtyLabel => '总件数';

  @override
  String get invDetailSplitTotalQtySuffix => '件';

  @override
  String invDetailSplitCalcPcs(int qty) {
    return '= $qty 件';
  }

  @override
  String get invDetailAddSplitTarget => '添加拆分目标';

  @override
  String get invDetailSplitReasonLabel => '拆分原因 *';

  @override
  String get invDetailSplitReasonHint => '请说明拆分原因';

  @override
  String get invDetailErrSplitReasonEmpty => '请填写拆分原因';

  @override
  String invDetailErrSplitSelectSku(int index) {
    return '第 $index 条：请从下拉列表中选择SKU';
  }

  @override
  String invDetailErrSplitBoxesMustBePositive(int index) {
    return '第 $index 条箱数必须大于0';
  }

  @override
  String invDetailErrSplitUnitsMustBePositive(int index) {
    return '第 $index 条件/箱必须大于0';
  }

  @override
  String invDetailErrSplitTotalQtyMustBePositive(int index) {
    return '第 $index 条总件数必须大于0';
  }

  @override
  String invDetailErrSplitUnbalanced(int total, int original, String unit) {
    return '拆分总量 $total $unit ≠ 原暂存 $original $unit，请调整';
  }

  @override
  String get invDetailSplitSuccess => '拆分成功，正式SKU已创建';

  @override
  String get invDetailConfirmSplit => '确认拆分';

  @override
  String get invDetailSourceModeBoxesOnly => '仅箱数';

  @override
  String get invDetailSourceModeQty => '按总数量';

  @override
  String get invDetailSourceModeCarton => '按箱规';

  @override
  String get invDetailMergeConfirmTitle => '目标SKU已有库存';

  @override
  String get invDetailMergeConfirm => '确认合并';

  @override
  String get invDetailSkuSearchHint => '输入编码或品名搜索';

  @override
  String get invDetailSkuNotFound => '未找到匹配的SKU';

  @override
  String get invDetailSkuArchived => '已停用';

  @override
  String get invDetailDefaultAction => '操作';

  @override
  String get invHistoryTitle => '入出库记录';

  @override
  String get invHistoryEmpty => '暂无出入库记录';

  @override
  String get invHistoryEmptyFiltered => '没有符合条件的记录';

  @override
  String get invHistoryViewAll => '查看全部类型';

  @override
  String get invHistorySplitSrc => '原暂存';

  @override
  String get invHistorySplitTargets => '拆分目标';

  @override
  String get invHistorySplitCleared => '原记录已清零（拆分完成）';

  @override
  String get invHistoryReason => '原因';

  @override
  String get invHistoryPendingCount => '待清点';

  @override
  String get errApiNotFound => '接口不存在，请联系管理员';

  @override
  String get errPermission => '无权限查看此记录';

  @override
  String get errLoadRetry => '加载失败，请重试';

  @override
  String get userMgmtTitle => '用户管理';

  @override
  String get userMgmtCreateBtn => '创建账号';

  @override
  String get userMgmtCreateTitle => '创建账号';

  @override
  String get userMgmtUsernameLabel => '用户名';

  @override
  String get userMgmtDisplayNameLabel => '显示名称';

  @override
  String get userMgmtInitPasswordLabel => '初始密码（至少6位）';

  @override
  String get userMgmtRoleLabel => '角色';

  @override
  String get userMgmtRoleAdmin => '管理员';

  @override
  String get userMgmtRoleSupervisor => '仓库主管';

  @override
  String get userMgmtRoleStaff => '普通员工';

  @override
  String get userMgmtCreateValidation => '请填写完整信息，密码至少6位';

  @override
  String get userMgmtCreateFailed => '创建失败';

  @override
  String get userMgmtEditRoleTitle => '修改角色';

  @override
  String userMgmtLoadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String get userMgmtMe => '我';

  @override
  String get userMgmtDisabled => '已停用';

  @override
  String userMgmtToggleTitle(String action) {
    return '确认$action';
  }

  @override
  String userMgmtToggleContent(String action, String notice) {
    return '确定要$action该账号吗？$notice';
  }

  @override
  String get userMgmtDisableNotice => '停用后该用户将无法登录。';

  @override
  String get userMgmtEnable => '启用';

  @override
  String get userMgmtDisable => '停用';

  @override
  String get userMgmtResetPasswordTitle => '重置密码';

  @override
  String get userMgmtNewPasswordLabel => '新密码（至少6位）';

  @override
  String get userMgmtPasswordTooShort => '密码至少6位';

  @override
  String get userMgmtPasswordReset => '密码已重置';

  @override
  String get userMgmtResetFailed => '重置失败';

  @override
  String get userMgmtResetBtn => '重置';

  @override
  String get userMgmtOperationFailed => '操作失败';

  @override
  String clearDoneMsg(
      Object inv, Object sku, Object loc, Object tx, Object log, Object imp) {
    return '清空完成：库存 $inv 条，SKU $sku 条，库位 $loc 条，流水 $tx 条，日志 $log 条，导入记录 $imp 条';
  }
}
