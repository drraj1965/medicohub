class MonetizationService {
  const MonetizationService();

  bool isFreePatientAccessEnabled() => true;

  bool isDoctorPremiumAvailable() => false;

  bool arePaidCoursesAvailable() => false;

  bool isSecondOpinionPaymentAvailable() => false;
}
