class GetSaleHistoryModel {
  final String? ordNo;
  final String? disid;
  final String? segmentId;
  final String? acode;
  final String? partyName;
  final String? itemid;
  final String? itemDesc;
  final String? qty;
  final String? qtyInKgs;
  final String? pcsQty;
  final String? totCtnQty;

   GetSaleHistoryModel({
    this.ordNo,
    this.disid,
    this.segmentId,
    this.acode,
    this.partyName,
    this.itemid,
    this.itemDesc,
    this.qty,
    this.qtyInKgs,
    this.pcsQty,
    this.totCtnQty,
  });

  factory GetSaleHistoryModel.fromJson(Map<String, dynamic> json) {
    return GetSaleHistoryModel(
      ordNo: json['ord_no'] as String?,
      disid: json['disid'] as String?,
      segmentId: json['segment_id'] as String?,
      acode: json['acode'] as String?,
      partyName: json['party_name'] as String?,
      itemid: json['itemid'] as String?,
      itemDesc: json['item_desc'] as String?,
      qty: json['qty'] as String?,
      qtyInKgs: json['qty_in_kgs'] as String?,
      pcsQty: json['pcs_qty'] as String?,
      totCtnQty: json['tot_ctn_qty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ord_no': ordNo,
      'disid': disid,
      'segment_id': segmentId,
      'acode': acode,
      'party_name': partyName,
      'itemid': itemid,
      'item_desc': itemDesc,
      'qty': qty,
      'qty_in_kgs': qtyInKgs,
      'pcs_qty': pcsQty,
      'tot_ctn_qty': totCtnQty,
    };
  }
}
