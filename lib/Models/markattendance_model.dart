import 'dart:convert';

MarkAttendenceModel markAttendenceModelFromJson(String str) =>
    MarkAttendenceModel.fromJson(json.decode(str));

String markAttendenceModelToJson(MarkAttendenceModel data) =>
    json.encode(data.toJson());

class MarkAttendenceModel {
  final String? status;
  final String? message;
  final List<JourneyPlan>? journeyPlan;

  MarkAttendenceModel({this.status, this.message, this.journeyPlan});

  factory MarkAttendenceModel.fromJson(Map<String, dynamic> json) =>
      MarkAttendenceModel(
        status: json["status"] as String?,
        message: json["message"] as String?,
        journeyPlan: json["journeyPlan"] == null
            ? []
            : List<JourneyPlan>.from(
                (json["journeyPlan"] as List).map(
                  (x) => JourneyPlan.fromJson(x),
                ),
              ),
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "journeyPlan": journeyPlan == null
        ? []
        : List<dynamic>.from(journeyPlan!.map((x) => x.toJson())),
  };
}

class JourneyPlan {
  final String? segid;
  final Segement? segement;
  final String? accode;
  final String? partyName;
  final String? contper;
  final String? contno;
  final String? custClass;
  final String? crLimit;
  final String? crDays;
  final String? custAddress;
  final String? areaName;
  final String? subAreaName;
  final String? status;

  JourneyPlan({
    this.segid,
    this.segement,
    this.accode,
    this.partyName,
    this.contper,
    this.contno,
    this.custClass,
    this.crLimit,
    this.crDays,
    this.custAddress,
    this.areaName,
    this.subAreaName,
    this.status,
  });

  factory JourneyPlan.fromJson(Map<String, dynamic> json) => JourneyPlan(
    segid: json["segid"] as String?,
    segement: segementValues.map[json["segement"]],
    accode: json["accode"] as String?,
    partyName: json["party_name"] as String?,
    contper: json["contper"] as String?,
    contno: json["contno"] as String?,
    custClass:
        json["cust_class"]
            as String?, //custClassValues.map[json["cust_class"]],
    crLimit: json["cr_limit"] as String?,
    crDays: json["cr_days"] as String?,
    custAddress: json["cust_address"] as String?,
    areaName: json["area_name"] as String?,
    subAreaName: json["sub_area_name"] as String?,
    status: json["status"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "segid": segid,
    "segement": segementValues.reverse[segement],
    "accode": accode,
    "party_name": partyName,
    "contper": contper,
    "contno": contno,
    "cust_class": custClass, //custClassValues.reverse[custClass],
    "cr_limit": crLimit,
    "cr_days": crDays,
    "cust_address": custAddress,
    "area_name": areaName,
    "sub_area_name": subAreaName,
    "status": status,
  };
}

enum CustClass { LMT, LR, OOH, POC, RETAILER, W_S }

final custClassValues = EnumValues({
  "LMT": CustClass.LMT,
  "LR": CustClass.LR,
  "OOH": CustClass.OOH,
  "POC": CustClass.POC,
  "RETAILER": CustClass.RETAILER,
  "W.S": CustClass.W_S,
});

enum Segement { TEA }

final segementValues = EnumValues({"TEA": Segement.TEA});

class EnumValues<T> {
  final Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}

// import 'dart:convert';

// MarkAttendenceModel markAttendenceModelFromJson(String str) => MarkAttendenceModel.fromJson(json.decode(str));

// String markAttendenceModelToJson(MarkAttendenceModel data) => json.encode(data.toJson());

// class MarkAttendenceModel {
//     String status;
//     String message;
//     List<JourneyPlan> journeyPlan;

//     MarkAttendenceModel({
//         required this.status,
//         required this.message,
//         required this.journeyPlan,
//     });

//     factory MarkAttendenceModel.fromJson(Map<String, dynamic> json) => MarkAttendenceModel(
//         status: json["status"],
//         message: json["message"],
//         journeyPlan: List<JourneyPlan>.from(json["journeyPlan"].map((x) => JourneyPlan.fromJson(x))),
//     );

//     Map<String, dynamic> toJson() => {
//         "status": status,
//         "message": message,
//         "journeyPlan": List<dynamic>.from(journeyPlan.map((x) => x.toJson())),
//     };
// }

// class JourneyPlan {
//     String segid;
//     Segement segement;
//     String accode;
//     String partyName;
//     String contper;
//     String contno;
//     CustClass custClass;
//     String crLimit;
//     String crDays;
//     String custAddress;
//     String areaName;
//     String subAreaName;
//     String status;

//     JourneyPlan({
//         required this.segid,
//         required this.segement,
//         required this.accode,
//         required this.partyName,
//         required this.contper,
//         required this.contno,
//         required this.custClass,
//         required this.crLimit,
//         required this.crDays,
//         required this.custAddress,
//         required this.areaName,
//         required this.subAreaName,
//         required this.status,
//     });

//     factory JourneyPlan.fromJson(Map<String, dynamic> json) => JourneyPlan(
//         segid: json["segid"],
//         segement: segementValues.map[json["segement"]]!,
//         accode: json["accode"],
//         partyName: json["party_name"],
//         contper: json["contper"],
//         contno: json["contno"],
//         custClass: custClassValues.map[json["cust_class"]]!,
//         crLimit: json["cr_limit"],
//         crDays: json["cr_days"],
//         custAddress: json["cust_address"],
//         areaName: json["area_name"],
//         subAreaName: json["sub_area_name"],
//         status: json["status"],
//     );

//     Map<String, dynamic> toJson() => {
//         "segid": segid,
//         "segement": segementValues.reverse[segement],
//         "accode": accode,
//         "party_name": partyName,
//         "contper": contper,
//         "contno": contno,
//         "cust_class": custClassValues.reverse[custClass],
//         "cr_limit": crLimit,
//         "cr_days": crDays,
//         "cust_address": custAddress,
//         "area_name": areaName,
//         "sub_area_name": subAreaName,
//         "status": status,
//     };
// }

// enum CustClass {
//     LMT,
//     LR,
//     OOH,
//     POC,
//     RETAILER,
//     W_S
// }

// final custClassValues = EnumValues({
//     "LMT": CustClass.LMT,
//     "LR": CustClass.LR,
//     "OOH": CustClass.OOH,
//     "POC": CustClass.POC,
//     "RETAILER": CustClass.RETAILER,
//     "W.S": CustClass.W_S
// });

// enum Segement {
//     TEA
// }

// final segementValues = EnumValues({
//     "TEA": Segement.TEA
// });

// class EnumValues<T> {
//     Map<String, T> map;
//     late Map<T, String> reverseMap;

//     EnumValues(this.map);

//     Map<T, String> get reverse {
//             reverseMap = map.map((k, v) => MapEntry(v, k));
//             return reverseMap;
//     }
// }
