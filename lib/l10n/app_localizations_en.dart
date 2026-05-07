// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Invoice Pro';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get invoices => 'Invoices';

  @override
  String get invoiceLabel => 'Invoice';

  @override
  String get clients => 'Clients';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get createInvoice => 'New Invoice';

  @override
  String get draft => 'Draft';

  @override
  String get sent => 'Sent';

  @override
  String get paid => 'Paid';

  @override
  String get overdue => 'Overdue';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get accepted => 'Accepted';

  @override
  String get converted => 'Converted';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkTheme => 'Dark Theme';

  @override
  String get lightTheme => 'Light Theme';

  @override
  String get total => 'Total';

  @override
  String get status => 'Status';

  @override
  String get date => 'Date';

  @override
  String get dueDate => 'Due Date';

  @override
  String get issueDate => 'Issue Date';

  @override
  String get clientName => 'Client Name';

  @override
  String get amount => 'Amount';

  @override
  String get noData => 'No data available';

  @override
  String get noInvoices => 'No invoices found';

  @override
  String get noClients => 'No clients found';

  @override
  String get addClient => 'Add Client';

  @override
  String get editClient => 'Edit Client';

  @override
  String get clientDetails => 'Client Details';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get name => 'Full Name';

  @override
  String get address => 'Address';

  @override
  String get phone => 'Phone';

  @override
  String get website => 'Website';

  @override
  String get companyName => 'Company Name';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirmDelete => 'Are you sure you want to delete this?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get pdfSaved => 'PDF saved to Documents';

  @override
  String get share => 'Share';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get companyInfo => 'Business Profile';

  @override
  String get businessProfileSubtitle => 'Used on generated PDF invoices';

  @override
  String get currency => 'Currency';

  @override
  String get items => 'Items';

  @override
  String get addItem => 'Add Line Item';

  @override
  String get description => 'Description';

  @override
  String get quantity => 'Quantity';

  @override
  String get price => 'Price';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get tax => 'Tax (%)';

  @override
  String get discount => 'Discount';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get totalTax => 'Tax Amount';

  @override
  String get notes => 'Notes';

  @override
  String get invoiceNumber => 'Invoice #';

  @override
  String get selectClient => 'Select Client';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get paymentAmount => 'Payment Amount';

  @override
  String get paymentRecorded => 'Payment recorded';

  @override
  String get invoiceMarkedPaid => 'Invoice marked as PAID';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get statusUpdated => 'Status updated';

  @override
  String get billTo => 'Bill To';

  @override
  String get summary => 'Summary';

  @override
  String get newInvoice => 'New Invoice';

  @override
  String get invoiceDetails => 'Invoice Details';

  @override
  String get attachment => 'Attachment';

  @override
  String get addAttachment => 'Add Attachment';

  @override
  String get changeAttachment => 'Change Attachment';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get appSettings => 'App Settings';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get totalClients => 'Total Clients';

  @override
  String get thisMonth => 'This Month';

  @override
  String get recentInvoices => 'Recent Invoices';

  @override
  String get overdueInvoices => 'Overdue Invoices';

  @override
  String overdueAlert(int count) {
    return '$count Overdue Invoice(s)';
  }

  @override
  String get immediateAction => 'Immediate action required';

  @override
  String get noRecentInvoices => 'No recent invoices';

  @override
  String get thankyou => 'Thank you for your business!';

  @override
  String get paymentTerms => 'Payment Terms: Net 30 days.';

  @override
  String get searchClients => 'Search clients...';

  @override
  String get searchInvoices => 'Search invoices...';

  @override
  String get errorLoadingClients => 'Error loading clients';

  @override
  String get addFirstClient => 'Add Your First Client';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get french => 'French';

  @override
  String get arabic => 'Arabic';

  @override
  String get currencySymbol => 'DZD';

  @override
  String get payments => 'Payments';

  @override
  String get payment => 'Payment';

  @override
  String get noPayments => 'No payments found';

  @override
  String get addPayment => 'Add Payment';

  @override
  String get balance => 'Balance';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get remaining => 'Remaining';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get history => 'History';

  @override
  String get relatedPayments => 'Related Payments';

  @override
  String get articles => 'Articles';

  @override
  String get article => 'Article';

  @override
  String get noArticles => 'No articles found';

  @override
  String get addArticle => 'Add Article';

  @override
  String get editArticle => 'Edit Article';

  @override
  String get code => 'Code';

  @override
  String get unit => 'Unit';

  @override
  String get measure => 'Measure';

  @override
  String get searchArticles => 'Search articles...';

  @override
  String get pricePerUnit => 'Price per unit';

  @override
  String get kg => 'kg';

  @override
  String get m2 => 'm²';

  @override
  String get m3 => 'm³';

  @override
  String get pieces => 'Pieces';

  @override
  String get physical => 'Physical';

  @override
  String get service => 'Service';
}
