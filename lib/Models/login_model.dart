import 'dart:convert';

LoginModel loginModelFromJson(String str) =>
    LoginModel.fromJson(json.decode(str));

String loginModelToJson(LoginModel data) => json.encode(data.toJson());

class LoginModel {
  final String? status;
  final String? message;
  final Userinfo? userinfo;
  final List<Distributor>? distributors;
  final List<Reason>? reasons;
  final List<Item>? items;
  final UserRights? userRights;
  final String? statusAttendance;
  List<JourneyPlan>? journeyPlan;
  Log? log;

  LoginModel({
    this.status,
    this.message,
    this.userinfo,
    this.distributors,
    this.reasons,
    this.items,
    this.userRights,
    this.statusAttendance,
     this.journeyPlan,
     this.log,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
        status: json["status"] as String?,
        message: json["message"] as String?,
        userinfo: json["userinfo"] != null
            ? Userinfo.fromJson(json["userinfo"])
            : null,
        distributors: json["distributors"] != null
            ? List<Distributor>.from(
                json["distributors"].map((x) => Distributor.fromJson(x)))
            : [],
        reasons: json["reasons"] != null
            ? List<Reason>.from(json["reasons"].map((x) => Reason.fromJson(x)))
            : [],
        items: json["items"] != null
            ? List<Item>.from(json["items"].map((x) => Item.fromJson(x)))
            : [],
        userRights: json["user_rights"] != null
            ? UserRights.fromJson(json["user_rights"])
            : null,
        statusAttendance: json["statusAttendance"] as String?,
          journeyPlan: json["journeyPlan"] != null
            ? List<JourneyPlan>.from(json["journeyPlan"].map((x) => JourneyPlan.fromJson(x))) : [],
        log: json["log"] != null? Log.fromJson(json["log"]):null,
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "userinfo": userinfo?.toJson(),
        "distributors":
            distributors?.map((x) => x.toJson()).toList() ?? <dynamic>[],
        "reasons": reasons?.map((x) => x.toJson()).toList() ?? <dynamic>[],
        "items": items?.map((x) => x.toJson()).toList() ?? <dynamic>[],
        "user_rights": userRights?.toJson(),
        "statusAttendance": statusAttendance,
          "journeyPlan": journeyPlan?.map((x) => x.toJson()).toList() ?? <dynamic>[],// List<dynamic>.from(journeyPlan.map((x) => x.toJson())),
        "log": log!.toJson(),
      };
}

class Distributor {
  final String? id;
  final String? name;
  final String? sname;
  final String? address1;
  final String? prntAddress;
  final String? contNo;
  final String? principleCode;
  final String? startDate;
  final String? endDate;
  final String? remarks;
  final String? compid;
  final String? segment;
  final String? aut01;
  final String? aut02;
  final String? aut03;
  final String? entdate;
  final String? status;
  final String? postDays;
  final String? pic;
  final String? outOfRout;
  final String? outOfRoutOrder;

  Distributor({
    this.id,
    this.name,
    this.sname,
    this.address1,
    this.prntAddress,
    this.contNo,
    this.principleCode,
    this.startDate,
    this.endDate,
    this.remarks,
    this.compid,
    this.segment,
    this.aut01,
    this.aut02,
    this.aut03,
    this.entdate,
    this.status,
    this.postDays,
    this.pic,
    this.outOfRout,
    this.outOfRoutOrder,
  });

  factory Distributor.fromJson(Map<String, dynamic> json) => Distributor(
        id: json["id"] as String?,
        name: json["name"] as String?,
        sname: json["sname"] as String?,
        address1: json["address1"] as String?,
        prntAddress: json["prnt_address"] as String?,
        contNo: json["cont_no"] as String?,
        principleCode: json["principle_code"] as String?,
        startDate: json["start_date"] as String?,
        endDate: json["end_date"] as String?,
        remarks: json["remarks"] as String?,
        compid: json["compid"] as String?,
        segment: json["segment"] as String?,
        aut01: json["aut01"] as String?,
        aut02: json["aut02"] as String?,
        aut03: json["aut03"] as String?,
        entdate: json["entdate"] as String?,
        status: json["status"] as String?,
        postDays: json["post_days"] as String?,
        pic: json["pic"] as String?,
        outOfRout: json["out_of_rout"] as String?,
        outOfRoutOrder: json["out_of_rout_order"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "sname": sname,
        "address1": address1,
        "prnt_address": prntAddress,
        "cont_no": contNo,
        "principle_code": principleCode,
        "start_date": startDate,
        "end_date": endDate,
        "remarks": remarks,
        "compid": compid,
        "segment": segment,
        "aut01": aut01,
        "aut02": aut02,
        "aut03": aut03,
        "entdate": entdate,
        "status": status,
        "post_days": postDays,
        "pic": pic,
        "out_of_rout": outOfRout,
        "out_of_rout_order": outOfRoutOrder,
      };
}

class JourneyPlan {
  String segid;
  String segement;
  String accode;
  String partyName;
  String contper;
  String contno;
  String custClass;
  String crLimit;
  String crDays;
  String custAddress;
  String areaName;
  String subAreaName;
  String status;
  int counter;

  JourneyPlan({
    required this.segid,
    required this.segement,
    required this.accode,
    required this.partyName,
    required this.contper,
    required this.contno,
    required this.custClass,
    required this.crLimit,
    required this.crDays,
    required this.custAddress,
    required this.areaName,
    required this.subAreaName,
    required this.status,
    this.counter = 0, 
  });

  factory JourneyPlan.fromJson(Map<String, dynamic> json) => JourneyPlan(
        segid: json["segid"],
        segement: json["segement"],
        accode: json["accode"],
        partyName: json["party_name"],
        contper: json["contper"],
        contno: json["contno"],
        custClass: json["cust_class"],
        crLimit: json["cr_limit"],
        crDays: json["cr_days"],
        custAddress: json["cust_address"],
        areaName: json["area_name"],
        subAreaName: json["sub_area_name"],
        status: json["status"],
        counter: 0,
      );

  Map<String, dynamic> toJson() => {
        "segid": segid,
        "segement": segement,
        "accode": accode,
        "party_name": partyName,
        "contper": contper,
        "contno": contno,
        "cust_class": custClass,
        "cr_limit": crLimit,
        "cr_days": crDays,
        "cust_address": custAddress,
        "area_name": areaName,
        "sub_area_name": subAreaName,
        "status": status,
      };
}


/*class JourneyPlan {
    String segid;
    String segement;
    String accode;
    String partyName;
    String contper;
    String contno;
    String custClass;
    String crLimit;
    String crDays;
    String custAddress;
    String areaName;
    String subAreaName;
    String status;

    JourneyPlan({
        required this.segid,
        required this.segement,
        required this.accode,
        required this.partyName,
        required this.contper,
        required this.contno,
        required this.custClass,
        required this.crLimit,
        required this.crDays,
        required this.custAddress,
        required this.areaName,
        required this.subAreaName,
        required this.status,
    });

    factory JourneyPlan.fromJson(Map<String, dynamic> json) => JourneyPlan(
        segid: json["segid"],
        segement: json["segement"], //segmentValues.map[json["segement"]]!,
        accode: json["accode"],
        partyName: json["party_name"],
        contper: json["contper"],
        contno: json["contno"],
        custClass:json["cust_class"],
        crLimit: json["cr_limit"],
        crDays: json["cr_days"],
        custAddress: json["cust_address"],
        areaName: json["area_name"],
        subAreaName: json["sub_area_name"],
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "segid": segid,
        "segement": segement,
        "accode": accode,
        "party_name": partyName,
        "contper": contper,
        "contno": contno,
        "cust_class": custClass,
        "cr_limit": crLimit,
        "cr_days": crDays,
        "cust_address": custAddress,
        "area_name": areaName,
        "sub_area_name": subAreaName,
        "status": status,
    };
}*/


class Log {
    String id;
    String userId;
    String actType;
    String action;
    String trandate;
    String ipAddress;
    String lat;
    String lng;
    dynamic refId;
    String aut01;
    String aut02;
    dynamic aut03;
    String time;
    String tim;
    String timeDate;
    dynamic obid;
    String orderStatus;
    dynamic tso;
    dynamic asm;
    String gpsAddress;

    Log({
        required this.id,
        required this.userId,
        required this.actType,
        required this.action,
        required this.trandate,
        required this.ipAddress,
        required this.lat,
        required this.lng,
        required this.refId,
        required this.aut01,
        required this.aut02,
        required this.aut03,
        required this.time,
        required this.tim,
        required this.timeDate,
        required this.obid,
        required this.orderStatus,
        required this.tso,
        required this.asm,
        required this.gpsAddress,
    });

    factory Log.fromJson(Map<String, dynamic> json) => Log(
        id: json["id"],
        userId: json["user_id"],
        actType: json["act_type"],
        action: json["action"],
        trandate: json["trandate"],
        ipAddress: json["ip_address"],
        lat: json["lat"],
        lng: json["lng"],
        refId: json["ref_id"],
        aut01: json["aut01"],
        aut02: json["aut02"],
        aut03: json["aut03"],
        time: json["time"],
        tim: json["tim"],
        timeDate: json["time_date"],
        obid: json["obid"],
        orderStatus: json["order_status"],
        tso: json["tso"],
        asm: json["asm"],
        gpsAddress: json["gps_address"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "act_type": actType,
        "action": action,
        "trandate": trandate,
        "ip_address": ipAddress,
        "lat": lat,
        "lng": lng,
        "ref_id": refId,
        "aut01": aut01,
        "aut02": aut02,
        "aut03": aut03,
        "time": time,
        "tim": tim,
        "time_date": timeDate,
        "obid": obid,
        "order_status": orderStatus,
        "tso": tso,
        "asm": asm,
        "gps_address": gpsAddress,
    };
}

class Item {
  final String? itemName;
  final String? itemDesc;
  final String? id;
  final String? brandid;
  final String? segmentId;
  final String? name;
  final String? brand;
  final Segment? segment;
  final String? compid;
  final String? ctnQty;
  final String? packQty;
  final String? ctnStatus;
  final String? unitFlagQty;
  final String? perKgLtr;
  final String? perCtnNkg;

  Item({
    this.itemName,
    this.itemDesc,
    this.id,
    this.brandid,
    this.segmentId,
    this.name,
    this.brand,
    this.segment,
    this.compid,
    this.ctnQty,
    this.packQty,
    this.ctnStatus,
    this.unitFlagQty,
    this.perKgLtr,
    this.perCtnNkg,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        itemName: json["item_name"] as String?,
        itemDesc: json["item_desc"] as String?,
        id: json["id"] as String?,
        brandid: json["brandid"] as String?,
        segmentId: json["segment_id"] as String?,
        name: json["name"] as String?,
        brand: json["brand"] as String?,
        segment: segmentValues.map[json["segment"]],
        compid: json["compid"] as String?,
        ctnQty: json["ctn_qty"] as String?,
        packQty: json["pack_qty"] as String?,
        ctnStatus: json["ctn_status"] as String?,
        unitFlagQty: json["unit_flag_qty"] as String?,
        perKgLtr: json["per_kg_ltr"] as String?,
        perCtnNkg: json["per_ctn_nkg"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "item_name": itemName,
        "item_desc": itemDesc,
        "id": id,
        "brandid": brandid,
        "segment_id": segmentId,
        "name": name,
        "brand": brandValues.reverse[brand],
        "segment": segmentValues.reverse[segment],
        "compid": compid,
        "ctn_qty": ctnQty,
        "pack_qty": packQty,
        "ctn_status": ctnStatus,
        "unit_flag_qty": unitFlagQty,
        "per_kg_ltr": perKgLtr,
        "per_ctn_nkg": perCtnNkg,
      };
}

enum Brand {
  AWAZ,
  BAITHAK,
  BAITHAK_S,
  HARDUM,
  HARDUM_DANEDAR,
  HARDUM_MIXTURE,
  HARDUM_S,
  JASMINE_GREEN_TEA,
  JASMINE_JAR,
  LEMON_GRASS_JAR,
  LEMON_GREEN_TEA,
  MINT_GREEN_TEA,
  PURE_GREEN_TEA,
  ULTRA_DANEDAR,
  ULTRA_RICH,
  ULTRA_RICH_S
}

final brandValues = EnumValues({
  "AWAZ": Brand.AWAZ,
  "BAITHAK": Brand.BAITHAK,
  "BAITHAK S": Brand.BAITHAK_S,
  "HARDUM": Brand.HARDUM,
  "HARDUM DANEDAR": Brand.HARDUM_DANEDAR,
  "HARDUM MIXTURE": Brand.HARDUM_MIXTURE,
  "HARDUM S": Brand.HARDUM_S,
  "JASMINE GREEN TEA": Brand.JASMINE_GREEN_TEA,
  "JASMINE JAR": Brand.JASMINE_JAR,
  "LEMON GRASS JAR": Brand.LEMON_GRASS_JAR,
  "LEMON GREEN TEA": Brand.LEMON_GREEN_TEA,
  "MINT GREEN TEA": Brand.MINT_GREEN_TEA,
  "PURE GREEN TEA": Brand.PURE_GREEN_TEA,
  "ULTRA DANEDAR": Brand.ULTRA_DANEDAR,
  "ULTRA RICH": Brand.ULTRA_RICH,
  "ULTRA RICH S": Brand.ULTRA_RICH_S,
});

enum Segment { TEA }

final segmentValues = EnumValues({
  "TEA": Segment.TEA,
});

class Reason {
  final String? id;
  final String? name;
  final String? type;
  final String? compid;
  final String? status;

  Reason({
    this.id,
    this.name,
    this.type,
    this.compid,
    this.status,
  });

  factory Reason.fromJson(Map<String, dynamic> json) => Reason(
        id: json["id"] as String?,
        name: json["name"] as String?,
        type: json["type"] as String?,
        compid: json["compid"] as String?,
        status: json["status"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "type": type,
        "compid": compid,
        "status": status,
      };
}

class UserRights {
  final String? markAttendance;
  final String? markLocation;
  final String? markOrder;
  final String? markInvoices;
  final String? tracking;
  final String? trackingTime;
  final String? segment;

  UserRights({
    this.markAttendance,
    this.markLocation,
    this.markOrder,
    this.markInvoices,
    this.tracking,
    this.trackingTime,
    this.segment,
  });

  factory UserRights.fromJson(Map<String, dynamic> json) => UserRights(
        markAttendance: json["mark_attendance"] as String?,
        markLocation: json["mark_location"] as String?,
        markOrder: json["mark_order"] as String?,
        markInvoices: json["mark_invoices"] as String?,
        tracking: json["tracking"] as String?,
        trackingTime: json["tracking_time"] as String?,
        segment: json["segment"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "mark_attendance": markAttendance,
        "mark_location": markLocation,
        "mark_order": markOrder,
        "mark_invoices": markInvoices,
        "tracking": tracking,
        "tracking_time": trackingTime,
        "segment": segment,
      };
}

class Userinfo {
  final String? userId;
  final String? obid;
  final String? email;
  final String? userName;
  final String? phone;
  final String? password;
  final String? compid;
  final String? disid;
  final String? distributionName;
  final String? segment;
  final String? validDate;
  final String? active;

  Userinfo({
    this.userId,
    this.obid,
    this.email,
    this.userName,
    this.phone,
    this.password,
    this.compid,
    this.disid,
    this.distributionName,
    this.segment,
    this.validDate,
    this.active,
  });

  factory Userinfo.fromJson(Map<String, dynamic> json) => Userinfo(
        userId: json["user_id"] as String?,
        obid: json["obid"] as String?,
        email: json["email"] as String?,
        userName: json["user_name"] as String?,
        phone: json["phone"] as String?,
        password: json["password"] as String?,
        compid: json["compid"] as String?,
        disid: json["disid"] as String?,
        distributionName: json["distribution_name"] as String?,
        segment: json["segment"] as String?,
        validDate: json["valid_date"] as String?,
        active: json["active"] as String?,
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "obid": obid,
        "email": email,
        "user_name": userName,
        "phone": phone,
        "password": password,
        "compid": compid,
        "disid": disid,
        "distribution_name": distributionName,
        "segment": segment,
        "valid_date": validDate,
        "active": active,
      };
}

class EnumValues<T> {
  final Map<String, T> map;
  late final Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}

