// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Invoice Pro';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get invoices => 'Factures';

  @override
  String get invoiceLabel => 'Facture';

  @override
  String get clients => 'Clients';

  @override
  String get settings => 'Paramètres';

  @override
  String get logout => 'Déconnexion';

  @override
  String get login => 'Connexion';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get createInvoice => 'Nouvelle facture';

  @override
  String get draft => 'Brouillon';

  @override
  String get sent => 'Envoyée';

  @override
  String get paid => 'Payée';

  @override
  String get overdue => 'En retard';

  @override
  String get unpaid => 'Impayée';

  @override
  String get accepted => 'Accepté';

  @override
  String get converted => 'Converti';

  @override
  String get cancelled => 'Annulée';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get darkTheme => 'Thème sombre';

  @override
  String get lightTheme => 'Thème clair';

  @override
  String get total => 'Total';

  @override
  String get status => 'Statut';

  @override
  String get date => 'Date';

  @override
  String get dueDate => 'Date d\'échéance';

  @override
  String get issueDate => 'Date d\'émission';

  @override
  String get clientName => 'Nom du client';

  @override
  String get amount => 'Montant';

  @override
  String get noData => 'Aucune donnée disponible';

  @override
  String get noInvoices => 'Aucune facture trouvée';

  @override
  String get noClients => 'Aucun client trouvé';

  @override
  String get addClient => 'Ajouter un client';

  @override
  String get editClient => 'Modifier le client';

  @override
  String get editInvoice => 'Modifier la facture';

  @override
  String get clientDetails => 'Détails du client';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get name => 'Nom complet';

  @override
  String get address => 'Adresse';

  @override
  String get phone => 'Téléphone';

  @override
  String get website => 'Site web';

  @override
  String get companyName => 'Nom de l\'entreprise';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get confirmDelete => 'Voulez-vous vraiment supprimer ceci ?';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get downloadPdf => 'Télécharger le PDF';

  @override
  String get pdfSaved => 'PDF enregistré dans Documents';

  @override
  String get share => 'Partager';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get companyInfo => 'Profil de l\'entreprise';

  @override
  String get businessProfileSubtitle => 'Utilisé sur les factures PDF générées';

  @override
  String get currency => 'Devise';

  @override
  String get items => 'Articles';

  @override
  String get addItem => 'Ajouter un article';

  @override
  String get description => 'Description';

  @override
  String get quantity => 'Quantité';

  @override
  String get price => 'Prix';

  @override
  String get unitPrice => 'Prix unitaire';

  @override
  String get tax => 'Taxe (%)';

  @override
  String get discount => 'Remise';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get totalTax => 'Montant de la taxe';

  @override
  String get notes => 'Notes';

  @override
  String get invoiceNumber => 'N° Facture';

  @override
  String get selectClient => 'Sélectionner un client';

  @override
  String get recordPayment => 'Enregistrer un paiement';

  @override
  String get paymentAmount => 'Montant du paiement';

  @override
  String get paymentRecorded => 'Paiement enregistré';

  @override
  String get invoiceMarkedPaid => 'Facture marquée comme PAYÉE';

  @override
  String get updateStatus => 'Mettre à jour le statut';

  @override
  String get statusUpdated => 'Statut mis à jour';

  @override
  String get billTo => 'Facturer à';

  @override
  String get summary => 'Résumé';

  @override
  String get newInvoice => 'Nouvelle facture';

  @override
  String get invoiceDetails => 'Détails de la facture';

  @override
  String get attachment => 'Pièce jointe';

  @override
  String get addAttachment => 'Ajouter une pièce jointe';

  @override
  String get changeAttachment => 'Changer la pièce jointe';

  @override
  String get saveSettings => 'Enregistrer les paramètres';

  @override
  String get settingsSaved => 'Paramètres enregistrés avec succès';

  @override
  String get appSettings => 'Paramètres de l\'application';

  @override
  String get totalRevenue => 'Chiffre d\'affaires';

  @override
  String get outstanding => 'En attente';

  @override
  String get totalClients => 'Total clients';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get lastMonth => 'Le mois dernier';

  @override
  String get issued => 'Emises';

  @override
  String get recentInvoices => 'Factures récentes';

  @override
  String get overdueInvoices => 'Factures en retard';

  @override
  String overdueAlert(int count) {
    return '$count Facture(s) en retard';
  }

  @override
  String get immediateAction => 'Action immédiate requise';

  @override
  String get noRecentInvoices => 'Aucune facture récente';

  @override
  String get thankyou => 'Merci pour votre confiance !';

  @override
  String get paymentTerms => 'Conditions de paiement : 30 jours net.';

  @override
  String get pdfDownloadedAndOpened => 'PDF téléchargé et ouvert :';

  @override
  String get error => 'Erreur';

  @override
  String get errorGeneratingPdf => 'Erreur lors de la génération du PDF';

  @override
  String get notesOptional => 'Notes (facultatif)';

  @override
  String get paymentNotesHint => 'ex. virement bancaire, espèces';

  @override
  String get record => 'Enregistrer';

  @override
  String get changeStatus => 'Changer le statut';

  @override
  String get unknownClient => 'Client inconnu';

  @override
  String get invoiceSavedSuccessfully => 'Facture enregistrée avec succès';

  @override
  String get addAtLeastOnePricedItem =>
      'Veuillez ajouter au moins un article avec un prix';

  @override
  String get errorSavingInvoice =>
      'Erreur lors de l\'enregistrement de la facture';

  @override
  String get searchClients => 'Rechercher des clients...';

  @override
  String get searchInvoices => 'Rechercher des factures...';

  @override
  String get errorLoadingClients => 'Erreur lors du chargement des clients';

  @override
  String get addFirstClient => 'Ajouter votre premier client';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get english => 'Anglais';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'Arabe';

  @override
  String get currencySymbol => 'DZD';

  @override
  String get payments => 'Paiements';

  @override
  String get payment => 'Paiement';

  @override
  String get noPayments => 'Aucun paiement trouvé';

  @override
  String get addPayment => 'Ajouter un paiement';

  @override
  String get balance => 'Solde';

  @override
  String get paidAmount => 'Montant payé';

  @override
  String get remaining => 'Restant';

  @override
  String get paymentMethod => 'Mode de paiement';

  @override
  String get paymentDate => 'Date de paiement';

  @override
  String get history => 'Historique';

  @override
  String get relatedPayments => 'Paiements associés';

  @override
  String get articles => 'Articles';

  @override
  String get article => 'Article';

  @override
  String get noArticles => 'Aucun article trouvé';

  @override
  String get addArticle => 'Ajouter un article';

  @override
  String get editArticle => 'Modifier l\'article';

  @override
  String get code => 'Code';

  @override
  String get unit => 'Unité';

  @override
  String get measure => 'Mesure';

  @override
  String get searchArticles => 'Rechercher des articles...';

  @override
  String get pricePerUnit => 'Prix unitaire';

  @override
  String get kg => 'kg';

  @override
  String get m2 => 'm²';

  @override
  String get m3 => 'm³';

  @override
  String get pieces => 'Pièces';

  @override
  String get physical => 'Physique';

  @override
  String get service => 'Service';
}
