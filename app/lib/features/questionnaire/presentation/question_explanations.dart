import 'package:app/l10n/app_localizations.dart';

/// Human explanations for "Зачем это нужно?" - two short sentences per
/// question: why we ask, and what it changes in the agreement. Written
/// like a good consultant, never like a lawyer: no legal boilerplate, no
/// "существенное условие", no "переход права собственности".
///
/// The question text itself comes from the backend planner; this matcher
/// only picks which explanation fits it, by keywords, most specific
/// first. A question nothing matches gets the calm generic fallback -
/// still human, never legalese.
abstract final class QuestionExplanations {
  static String forQuestion(String question, AppLocalizations l10n) {
    final q = question.toLowerCase();

    bool has(List<String> keywords) => keywords.any(q.contains);

    // --- Money (specific before generic) ---
    if (has(['предоплат', 'аванс', 'задаток'])) {
      return l10n.explanationDeposit;
    }
    if (has(['способ оплат', 'как будет произведена оплата', 'как оплат', 'порядок оплат', 'наличн', 'безналичн'])) {
      return l10n.explanationPaymentMethod;
    }
    if (has(['счёт', 'счет', 'реквизит', 'мфо', 'iban'])) {
      return l10n.explanationBankDetails;
    }
    if (has(['процент', 'ставк'])) {
      return l10n.explanationInterestRate;
    }
    if (has(['зарплат', 'оклад', 'вознагражден'])) {
      return l10n.explanationSalary;
    }
    if (has(['цена', 'цену', 'стоимост', 'сумм'])) {
      return l10n.explanationPrice;
    }

    // --- Time ---
    if (has(['дата передачи', 'когда передадите', 'когда передать', 'когда планируете передать', 'срок передачи'])) {
      return l10n.explanationTransferDate;
    }
    if (has(['срок возврата', 'когда вернут', 'вернуть заём', 'вернуть займ', 'погашен'])) {
      return l10n.explanationRepaymentDate;
    }
    if (has(['дата выхода', 'начала работы', 'приступит к работе', 'первый рабочий'])) {
      return l10n.explanationStartDate;
    }
    if (has(['срок', 'период', 'до какого', 'длительн'])) {
      return l10n.explanationDuration;
    }
    if (has(['дата', 'когда'])) {
      return l10n.explanationGenericDate;
    }

    // --- Place ---
    if (has(['где состоится', 'место передачи', 'место встречи', 'где передад'])) {
      return l10n.explanationTransferPlace;
    }
    if (has(['адрес', 'кадастров', 'где находится'])) {
      return l10n.explanationAddress;
    }

    // --- The thing being sold/rented ---
    if (has(['vin', 'вин', 'номер двигателя', 'номер кузова', 'номер шасси', 'госномер', 'регистрационный номер'])) {
      return l10n.explanationVehicleIds;
    }
    if (has(['марка', 'модель', 'год выпуска'])) {
      return l10n.explanationVehicleMakeModel;
    }
    if (has(['площадь', 'комнат', 'этаж'])) {
      return l10n.explanationPropertyDetails;
    }

    // --- People ---
    if (has(['фио', 'ф.и.о', 'имя', 'фамили', 'паспорт', 'дата рождения'])) {
      return l10n.explanationPersonalInfo;
    }
    if (has(['должност', 'позици', 'кем будет работать'])) {
      return l10n.explanationJobTitle;
    }
    if (has(['телефон', 'контакт', 'почт', 'email'])) {
      return l10n.explanationContacts;
    }

    // --- Extra terms ---
    if (has(['особые услови', 'дополнительн', 'примечани', 'ещё что-то', 'пожелани'])) {
      return l10n.explanationExtraTerms;
    }

    // --- Calm human fallback ---
    return l10n.explanationFallback;
  }
}
