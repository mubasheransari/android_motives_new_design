class GetShopInvoicesModel {
  final String? invid;
  final String? cashCredit;
  final String? invno;
  final String? invDate;
  final String? acode;
  final String? invAmount;
  final String? ledAmount;
  final String? balAmount;

  const GetShopInvoicesModel({
    this.invid,
    this.cashCredit,
    this.invno,
    this.invDate,
    this.acode,
    this.invAmount,
    this.ledAmount,
    this.balAmount,
  });

  factory GetShopInvoicesModel.fromJson(Map<String, dynamic> json) {
    return GetShopInvoicesModel(
      invid: json['invid'] as String?,
      cashCredit: json['cash_credit'] as String?,
      invno: json['invno'] as String?,
      invDate: json['inv_date'] as String?,
      acode: json['acode'] as String?,
      invAmount: json['inv_amount'] as String?,
      ledAmount: json['led_amount'] as String?,
      balAmount: json['bal_amount'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invid': invid,
      'cash_credit': cashCredit,
      'invno': invno,
      'inv_date': invDate,
      'acode': acode,
      'inv_amount': invAmount,
      'led_amount': ledAmount,
      'bal_amount': balAmount,
    };
  }

  static List<GetShopInvoicesModel> listFromJson(List<dynamic> json) =>
      json.map((e) => GetShopInvoicesModel.fromJson(e as Map<String, dynamic>)).toList();
}
