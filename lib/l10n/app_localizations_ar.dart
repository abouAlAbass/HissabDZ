// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Invoice Pro';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get invoices => 'الفواتير';

  @override
  String get invoiceLabel => 'فاتورة';

  @override
  String get clients => 'العملاء';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get createInvoice => 'فاتورة جديدة';

  @override
  String get draft => 'مسودة';

  @override
  String get sent => 'مرسلة';

  @override
  String get paid => 'مدفوعة';

  @override
  String get overdue => 'متأخرة';

  @override
  String get unpaid => 'غير مدفوعة';

  @override
  String get accepted => 'مقبول';

  @override
  String get converted => 'محولة';

  @override
  String get cancelled => 'ملغاة';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get darkTheme => 'المظهر الداكن';

  @override
  String get lightTheme => 'المظهر الفاتح';

  @override
  String get total => 'الإجمالي';

  @override
  String get status => 'الحالة';

  @override
  String get date => 'التاريخ';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get issueDate => 'تاريخ الإصدار';

  @override
  String get clientName => 'اسم العميل';

  @override
  String get amount => 'المبلغ';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get noInvoices => 'لا توجد فواتير';

  @override
  String get noClients => 'لا يوجد عملاء';

  @override
  String get addClient => 'إضافة عميل';

  @override
  String get editClient => 'تعديل العميل';

  @override
  String get clientDetails => 'تفاصيل العميل';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get name => 'الاسم الكامل';

  @override
  String get address => 'العنوان';

  @override
  String get phone => 'الهاتف';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get confirmDelete => 'هل أنت متأكد من الحذف؟';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get downloadPdf => 'تحميل PDF';

  @override
  String get pdfSaved => 'تم حفظ PDF في المستندات';

  @override
  String get share => 'مشاركة';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get companyInfo => 'ملف الشركة';

  @override
  String get businessProfileSubtitle => 'يُستخدم في فواتير PDF المُنشأة';

  @override
  String get currency => 'العملة';

  @override
  String get items => 'البنود';

  @override
  String get addItem => 'إضافة بند';

  @override
  String get description => 'الوصف';

  @override
  String get quantity => 'الكمية';

  @override
  String get price => 'السعر';

  @override
  String get unitPrice => 'سعر الوحدة';

  @override
  String get tax => 'الضريبة (%)';

  @override
  String get discount => 'الخصم';

  @override
  String get subtotal => 'المجموع الجزئي';

  @override
  String get totalTax => 'مبلغ الضريبة';

  @override
  String get notes => 'ملاحظات';

  @override
  String get invoiceNumber => 'رقم الفاتورة';

  @override
  String get selectClient => 'اختر العميل';

  @override
  String get recordPayment => 'تسجيل دفعة';

  @override
  String get paymentAmount => 'مبلغ الدفعة';

  @override
  String get paymentRecorded => 'تم تسجيل الدفعة';

  @override
  String get invoiceMarkedPaid => 'تم وضع علامة مدفوعة على الفاتورة';

  @override
  String get updateStatus => 'تحديث الحالة';

  @override
  String get statusUpdated => 'تم تحديث الحالة';

  @override
  String get billTo => 'فاتورة إلى';

  @override
  String get summary => 'الملخص';

  @override
  String get newInvoice => 'فاتورة جديدة';

  @override
  String get invoiceDetails => 'تفاصيل الفاتورة';

  @override
  String get attachment => 'مرفق';

  @override
  String get addAttachment => 'إضافة مرفق';

  @override
  String get changeAttachment => 'تغيير المرفق';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات بنجاح';

  @override
  String get appSettings => 'إعدادات التطبيق';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get outstanding => 'المستحقات';

  @override
  String get totalClients => 'إجمالي العملاء';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get recentInvoices => 'الفواتير الأخيرة';

  @override
  String get overdueInvoices => 'الفواتير المتأخرة';

  @override
  String overdueAlert(int count) {
    return '$count فاتورة متأخرة';
  }

  @override
  String get immediateAction => 'مطلوب اتخاذ إجراء فوري';

  @override
  String get noRecentInvoices => 'لا توجد فواتير حديثة';

  @override
  String get thankyou => 'شكراً لتعاملكم معنا!';

  @override
  String get paymentTerms => 'شروط الدفع: صافي 30 يوماً.';

  @override
  String get searchClients => 'البحث عن عملاء...';

  @override
  String get searchInvoices => 'البحث في الفواتير...';

  @override
  String get errorLoadingClients => 'خطأ في تحميل العملاء';

  @override
  String get addFirstClient => 'أضف أول عميل';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get french => 'الفرنسية';

  @override
  String get arabic => 'العربية';

  @override
  String get currencySymbol => 'دج';

  @override
  String get payments => 'المدفوعات';

  @override
  String get payment => 'دفعة';

  @override
  String get noPayments => 'لا توجد مدفوعات';

  @override
  String get addPayment => 'إضافة دفعة';

  @override
  String get balance => 'الرصيد';

  @override
  String get paidAmount => 'المبلغ المدفوع';

  @override
  String get remaining => 'المتبقي';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get paymentDate => 'تاريخ الدفع';

  @override
  String get history => 'السجل';

  @override
  String get relatedPayments => 'المدفوعات المتعلقة';

  @override
  String get articles => 'الأصناف';

  @override
  String get article => 'الصنف';

  @override
  String get noArticles => 'لا توجد أصناف';

  @override
  String get addArticle => 'إضافة صنف';

  @override
  String get editArticle => 'تعديل الصنف';

  @override
  String get code => 'الكود';

  @override
  String get unit => 'الوحدة';

  @override
  String get measure => 'القياس';

  @override
  String get searchArticles => 'البحث عن أصناف...';

  @override
  String get pricePerUnit => 'السعر لكل وحدة';

  @override
  String get kg => 'كلغ';

  @override
  String get m2 => 'م٢';

  @override
  String get m3 => 'م٣';

  @override
  String get pieces => 'قطعة';

  @override
  String get physical => 'مادي';

  @override
  String get service => 'خدمة';
}
